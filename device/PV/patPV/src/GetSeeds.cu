/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "GetSeeds.cuh"

void pv_get_seeds::pv_get_seeds_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_seeds_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_number_seeds_t>(arguments, first<host_number_of_events_t>(arguments));
}

void pv_get_seeds::pv_get_seeds_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  global_function(pv_get_seeds)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), stream)(
    arguments);

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_number_seeds_t>(host_buffers.host_number_of_seeds, arguments, stream);
  }
}

__device__ float zCloseBeam(KalmanVeloState track, const PatPV::XYZPoint& beamspot)
{

  PatPV::XYZPoint tpoint(track.x, track.y, track.z);
  PatPV::XYZPoint tdir(track.tx, track.ty, 1.f);

  float wx = (1.f + tdir.x * tdir.x) / track.c00;
  float wy = (1.f + tdir.y * tdir.y) / track.c11;

  float x0 = tpoint.x - tpoint.z * tdir.x - beamspot.x;
  float y0 = tpoint.y - tpoint.z * tdir.y - beamspot.y;
  float den = wx * tdir.x * tdir.x + wy * tdir.y * tdir.y;
  float zAtBeam = -(wx * x0 * tdir.x + wy * y0 * tdir.y) / den;

  float xb = tpoint.x + tdir.x * (zAtBeam - tpoint.z) - beamspot.x;
  float yb = tpoint.y + tdir.y * (zAtBeam - tpoint.z) - beamspot.y;
  float r2AtBeam = xb * xb + yb * yb;

  return r2AtBeam < 0.5f * 0.5f ? zAtBeam : 10e8f;
}

__device__ void errorForPVSeedFinding(float tx, float ty, float& sigz2)
{

  // the seeding results depend weakly on this eror parametrization

  float pMean = 3000.f; // unit: MeV

  float tanTheta2 = tx * tx + ty * ty;
  float sinTheta2 = tanTheta2 / (1.f + tanTheta2);

  // assume that first hit in VD at 8 mm
  float distr = 8.f; // unit: mm
  float dist2 = distr * distr / sinTheta2;
  float sigma_ms2 = PatPV::mcu_scatCons * PatPV::mcu_scatCons * dist2 / (pMean * pMean);
  float fslope2 = 0.0005f * 0.0005f;
  float sigma_slope2 = fslope2 * dist2;

  sigz2 = (sigma_ms2 + sigma_slope2) / sinTheta2;
  if (sigz2 == 0) sigz2 = 100.f;
}

__global__ void pv_get_seeds::pv_get_seeds(pv_get_seeds::Parameters parameters)
{
  PatPV::XYZPoint beamspot;
  beamspot.x = 0;
  beamspot.y = 0;
  beamspot.z = 0;

  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {
    parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};
  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  PatPV::vtxCluster vclusters[Velo::Constants::max_tracks];

  int counter_number_of_clusters = 0;
  for (unsigned i = 0; i < number_of_tracks_event; i++) {
    float sigsq;
    float zclu;
    KalmanVeloState trk = velo_states.get_kalman_state(event_tracks_offset + i);

    zclu = zCloseBeam(trk, beamspot);
    errorForPVSeedFinding(trk.tx, trk.ty, sigsq);

    if (fabsf(zclu) > 2000.f) continue;
    PatPV::vtxCluster clu;
    clu.z = zclu;
    clu.sigsq = sigsq;
    clu.sigsqmin = clu.sigsq;
    clu.ntracks = 1;
    vclusters[counter_number_of_clusters] = clu;

    counter_number_of_clusters++;
  }

  float zseeds[Velo::Constants::max_tracks];

  int number_final_clusters = find_clusters(vclusters, zseeds, counter_number_of_clusters, parameters);

  for (int i = 0; i < number_final_clusters; i++)
    parameters.dev_seeds[event_number * PatPV::max_number_vertices + i] =
      PatPV::XYZPoint {beamspot.x, beamspot.y, zseeds[i]};

  parameters.dev_number_seeds[event_number] = number_final_clusters;
}

__device__ int pv_get_seeds::find_clusters(
  PatPV::vtxCluster* vclus,
  float* zclusters,
  int number_of_clusters,
  const pv_get_seeds::Parameters& parameters)
{
  for (int i = 0; i < number_of_clusters; i++) {
    vclus[i].sigsq *= parameters.factor_to_increase_errors * parameters.factor_to_increase_errors; // blow up errors
    vclus[i].sigsqmin = vclus[i].sigsq;
  }

  // maybe sort in z before merging? -> does not seem to help

  bool no_merges = false;
  while (!no_merges) {
    // reset merged flags
    for (int j = 0; j < number_of_clusters; j++)
      vclus[j].merged = false;

    no_merges = true;
    for (int index_cluster = 0; index_cluster < number_of_clusters - 1; index_cluster++) {

      // skip cluster which have already been merged
      if (vclus[index_cluster].ntracks == 0) continue;

      // sorting by chi2dist seems to increase efficiency in nominal code

      for (int index_second_cluster = 0; index_second_cluster < number_of_clusters; index_second_cluster++) {
        if (vclus[index_second_cluster].merged || vclus[index_cluster].merged) continue;
        // skip cluster which have already been merged
        if (vclus[index_second_cluster].ntracks == 0) continue;
        if (index_cluster == index_second_cluster) continue;
        float z1 = vclus[index_cluster].z;
        float z2 = vclus[index_second_cluster].z;
        float s1 = vclus[index_cluster].sigsq;
        float s2 = vclus[index_second_cluster].sigsq;
        float s1min = vclus[index_cluster].sigsqmin;
        float s2min = vclus[index_second_cluster].sigsqmin;
        float sigsqmin = s1min;
        if (s2min < s1min) sigsqmin = s2min;

        float zdist = z1 - z2;
        float chi2dist = zdist * zdist / (s1 + s2);
        // merge if chi2dist is smaller than max
        if (chi2dist < parameters.max_chi2_merge) {
          no_merges = false;
          float w_inv = (s1 * s2 / (s1 + s2));
          float zmerge = w_inv * (z1 / s1 + z2 / s2);

          vclus[index_cluster].z = zmerge;
          vclus[index_cluster].sigsq = w_inv;
          vclus[index_cluster].sigsqmin = sigsqmin;
          vclus[index_cluster].ntracks += vclus[index_second_cluster].ntracks;
          vclus[index_second_cluster].ntracks = 0; // mark second cluster as used
          vclus[index_cluster].merged = true;
          vclus[index_second_cluster].merged = true;

          // break;
        }
      }
    }
  }

  int return_number_of_clusters = 0;
  // count final number of clusters
  PatPV::vtxCluster pvclus[Velo::Constants::max_tracks];
  for (int i = 0; i < number_of_clusters; i++) {
    if (vclus[i].ntracks != 0) {
      pvclus[return_number_of_clusters] = vclus[i];
      return_number_of_clusters++;
    }
  }

  // clean up clusters, do we gain much from this?

  // Select good clusters.

  int number_good_clusters = 0;

  for (int index = 0; index < return_number_of_clusters; index++) {

    int n_tracks_close = 0;
    for (int i = 0; i < number_of_clusters; i++)
      if (fabsf(vclus[i].z - pvclus[index].z) < parameters.dz_close_tracks_in_cluster) n_tracks_close++;

    float dist_to_closest = 1000000.;
    if (return_number_of_clusters > 1) {
      for (int index2 = 0; index2 < return_number_of_clusters; index2++) {
        if (index != index2 && (fabsf(pvclus[index2].z - pvclus[index].z) < dist_to_closest))
          dist_to_closest = fabsf(pvclus[index2].z - pvclus[index].z);
      }
    }

    // ratio to remove clusters made of one low error track and many large error ones
    float rat = pvclus[index].sigsq / pvclus[index].sigsqmin;
    bool igood = false;
    int ntracks = pvclus[index].ntracks;
    if (ntracks >= parameters.min_cluster_mult) {
      if (dist_to_closest > 10.f && rat < 0.95f) igood = true;
      if (ntracks >= parameters.high_mult && rat < parameters.ratio_sig2_high_mult) igood = true;
      if (ntracks < parameters.high_mult && rat < parameters.ratio_sig2_low_mult) igood = true;
    }
    // veto
    if (n_tracks_close < parameters.min_close_tracks_in_cluster) igood = false;
    if (igood) {
      zclusters[number_good_clusters] = pvclus[index].z;
      number_good_clusters++;
    }
  }

  // return return_number_of_clusters;
  return number_good_clusters;
}
