#include "pv_beamline_multi_fitter.cuh"

__global__ void pv_beamline_multi_fitter(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtracks_denom,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  float* dev_beamline,
  const float* dev_pvtrack_z)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  uint* number_of_multi_fit_vertices = dev_number_of_multi_fit_vertices + event_number;

  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};

  const uint number_of_tracks = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const float* zseeds = dev_zpeaks + event_number * PV::max_number_vertices;
  const uint number_of_seeds = dev_number_of_zpeaks[event_number];

  const PVTrack* tracks = dev_pvtracks + event_tracks_offset;

  PV::Vertex* vertices = dev_multi_fit_vertices + event_number * PV::max_number_vertices;
  PV::Vertex vertex;
  float* pvtracks_denom = dev_pvtracks_denom + event_tracks_offset;

  const float2 seed_pos_xy {dev_beamline[0], dev_beamline[1]};

  // Find out the tracks we have to process
  // Exploit the fact tracks are sorted by z
  int first_track_in_range = -1;
  uint number_of_tracks_in_range = 0;
  for (uint i = 0; i < number_of_tracks; i++) {
    const auto z = dev_pvtrack_z[event_tracks_offset + i];
    if (zmin < z && z < zmax) {
      if (first_track_in_range == -1) {
        first_track_in_range = i;
      }
      ++number_of_tracks_in_range;
    }
  }

  


  // make sure that we have one thread per seed
  for (uint i_thisseed = threadIdx.x; i_thisseed < number_of_seeds; i_thisseed += blockDim.x) {
    float exp_chi2_0[1200];

    bool converged = false;
    bool accept = true;
    float vtxcov[6] = {0.f, 0.f, 0.f, 0.f, 0.f, 0.f};

    // initial vertex posisiton, use x,y of the beamline and z of the seed
    float2 vtxpos_xy = seed_pos_xy;
    const float seed_pos_z = zseeds[i_thisseed];
    auto vtxpos_z = seed_pos_z;
    float chi2tot = 0.f;
    float sum_weights = 0.f;

    for (uint iter = 0; (iter < maxFitIter && !converged) || iter < minFitIter; ++iter) {
      auto halfD2Chi2DX2_00 = 0.f;
      auto halfD2Chi2DX2_11 = 0.f;
      auto halfD2Chi2DX2_20 = 0.f;
      auto halfD2Chi2DX2_21 = 0.f;
      auto halfD2Chi2DX2_22 = 0.f;
      float3 halfDChi2DX {0.f, 0.f, 0.f};
      sum_weights = 0.f;

      uint nselectedtracks = 0;
      chi2tot = 0.f;
      float local_chi2tot = 0.f;
      float local_sum_weights = 0.f;

      for (uint i = threadIdx.y; i < number_of_tracks_in_range; i += blockDim.y) {
        // compute the chi2
        const PVTrackInVertex& trk = tracks[first_track_in_range + i];

        const auto dz = vtxpos_z - trk.z;
        const float2 res = vtxpos_xy - (trk.x + trk.tx * dz);
        const auto chi2 = res.x * res.x * trk.W_00 + res.y * res.y * trk.W_11;
        if(iter == 0) exp_chi2_0[i] = expf(chi2 * (-0.5f));


        // compute the weight.
        if (chi2 < maxChi2) {
          
          // for more information on the weighted fitting, see e.g.
          // Adaptive Multi-vertex fitting, R. Frühwirth, W. Waltenberger
          // https://cds.cern.ch/record/803519/files/p280.pdf
                    // use seed position for chi2 calculation of nominator
          const float dz_seed = seed_pos_z - trk.z;
          const float2 res_seed = seed_pos_xy - (trk.x + trk.tx * dz_seed);
          const float chi2_seed = res_seed.x * res_seed.x * trk.W_00 + res_seed.y * res_seed.y * trk.W_11;
          const auto nom = expf(chi2_seed * (-0.5f));
          

          const auto denom = chi2CutExp + nom;
          //substract this term to avoid double counting

          const auto track_weight = nom / (denom + pvtracks_denom[first_track_in_range + i] - exp_chi2_0[i]);



          // unfortunately branchy, but reduces fake rate
           if (trk.weight > 0.5) {
              ++nselectedtracks;

            const float3 HWr {
              res.x * trk.W_00, res.y * trk.W_11, -trk.tx.x * res.x * trk.W_00 - trk.tx.y * res.y * trk.W_11};

            halfDChi2DX += HWr * track_weight;
            halfD2Chi2DX2_00 += track_weight * trk.HWH_00;
            halfD2Chi2DX2_11 += track_weight * trk.HWH_11;
            halfD2Chi2DX2_20 += track_weight * trk.HWH_20;
            halfD2Chi2DX2_21 += track_weight * trk.HWH_21;
            halfD2Chi2DX2_22 += track_weight * trk.HWH_22;

            local_chi2tot += track_weight * chi2;
            local_sum_weights += track_weight;
          }
        }
      }

      // __syncthreads();

      // for (int i = 16; i > 0; i = i / 2) {
      //   halfD2Chi2DX2_00 += __shfl_down_sync(0xFFFFFFFF, halfD2Chi2DX2_00, i);
      //   halfD2Chi2DX2_11 += __shfl_down_sync(0xFFFFFFFF, halfD2Chi2DX2_11, i);
      //   halfD2Chi2DX2_20 += __shfl_down_sync(0xFFFFFFFF, halfD2Chi2DX2_20, i);
      //   halfD2Chi2DX2_21 += __shfl_down_sync(0xFFFFFFFF, halfD2Chi2DX2_21, i);
      //   halfD2Chi2DX2_22 += __shfl_down_sync(0xFFFFFFFF, halfD2Chi2DX2_22, i);
      //   halfDChi2DX.x += __shfl_down_sync(0xFFFFFFFF, halfDChi2DX.x, i);
      //   halfDChi2DX.y += __shfl_down_sync(0xFFFFFFFF, halfDChi2DX.y, i);
      //   halfDChi2DX.z += __shfl_down_sync(0xFFFFFFFF, halfDChi2DX.z, i);
      //   local_chi2tot += __shfl_down_sync(0xFFFFFFFF, chi2tot, i);
      //   local_sum_weights += __shfl_down_sync(0xFFFFFFFF, sum_weights, i);
      //   nselectedtracks += __shfl_down_sync(0xFFFFFFFF, nselectedtracks, i);
      // }

      // __syncthreads();

      if (threadIdx.y == 0) {
        chi2tot += local_chi2tot;
        sum_weights += local_sum_weights;

        if (nselectedtracks >= 2) {
          // compute the new vertex covariance using analytical inversion
          const auto a00 = halfD2Chi2DX2_00;
          const auto a11 = halfD2Chi2DX2_11;
          const auto a20 = halfD2Chi2DX2_20;
          const auto a21 = halfD2Chi2DX2_21;
          const auto a22 = halfD2Chi2DX2_22;

          const auto det = a00 * (a22 * a11 - a21 * a21) + a20 * (-a11 * a20);
          const auto inv_det = 1.f / det;

          // maybe we should catch the case when det = 0
          // if (det == 0) return false;

          vtxcov[0] = (a22 * a11 - a21 * a21) * inv_det;
          vtxcov[1] = -(-a20 * a21) * inv_det;
          vtxcov[2] = (a22 * a00 - a20 * a20) * inv_det;
          vtxcov[3] = (-a20 * a11) * inv_det;
          vtxcov[4] = -(a21 * a00) * inv_det;
          vtxcov[5] = (a11 * a00) * inv_det;

          const float2 delta_xy {
            -1.f * (vtxcov[0] * halfDChi2DX.x + vtxcov[1] * halfDChi2DX.y + vtxcov[3] * halfDChi2DX.z),
            -1.f * (vtxcov[1] * halfDChi2DX.x + vtxcov[2] * halfDChi2DX.y + vtxcov[4] * halfDChi2DX.z)};

          const auto delta_z =
            -1.f * (vtxcov[3] * halfDChi2DX.x + vtxcov[4] * halfDChi2DX.y + vtxcov[5] * halfDChi2DX.z);
          chi2tot += delta_xy.x * halfDChi2DX.x + delta_xy.y * halfDChi2DX.y + delta_z * halfDChi2DX.z;

          // update the position
          vtxpos_xy = vtxpos_xy + delta_xy;
          vtxpos_z = vtxpos_z + delta_z;
          converged = fabsf(delta_z) < maxDeltaZConverged;
        }
        else {
          // Finish loop and do not accept vertex
          converged = true;
          accept = false;
        }
      }

      // converged = __any_sync(0xFFFFFFFF, converged);
    } // end iteration loop

    if (accept && threadIdx.y == 0) {
      vertex.chi2 = chi2tot;
      vertex.setPosition(vtxpos_xy, vtxpos_z);
      vertex.setCovMatrix(vtxcov);
      vertex.nTracks = sum_weights;

      // TODO integrate beamline position
      const auto beamlinedx = vertex.position.x - dev_beamline[0];
      const auto beamlinedy = vertex.position.y - dev_beamline[1];
      const auto beamlinerho2 = beamlinedx * beamlinedx + beamlinedy * beamlinedy;
      if (vertex.nTracks >= 2.f && beamlinerho2 < maxVertexRho2) {
        uint vertex_index = atomicAdd(number_of_multi_fit_vertices, 1);
        vertices[vertex_index] = vertex;
      }
    }
  }
}
