#include "FitSeeds.cuh"

void fit_seeds::pv_fit_seeds_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_vertex_t>(arguments, PatPV::max_number_vertices * first<host_number_of_selected_events_t>(arguments));
  set_size<dev_number_vertex_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

void fit_seeds::pv_fit_seeds_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  device_function(fit_seeds)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);

  if (runtime_options.do_check) {
    // Retrieve result
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_reconstructed_pvs,
      data<dev_vertex_t>(arguments),
      size<dev_vertex_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_number_of_vertex,
      data<dev_number_vertex_t>(arguments),
      size<dev_number_vertex_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

__global__ void fit_seeds::fit_seeds(fit_seeds::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstKalmanStates velo_states {
    parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};
  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  PV::Vertex vertex;

  int counter_vertex = 0;
  for (uint i_seed = 0; i_seed < parameters.dev_number_seeds[event_number]; i_seed++) {
    bool success = fit_vertex(
      parameters.dev_seeds[event_number * PatPV::max_number_vertices + i_seed],
      velo_states,
      vertex,
      number_of_tracks_event,
      event_tracks_offset);
    if (success) {

      parameters.dev_vertex[PatPV::max_number_vertices * event_number + counter_vertex] = vertex;
      counter_vertex++;
    }
  }

  parameters.dev_number_vertex[event_number] = counter_vertex;
}

__device__ bool fit_vertex(
  const PatPV::XYZPoint& seedPoint,
  Velo::Consolidated::ConstKalmanStates& velo_states,
  PV::Vertex& vtx,
  int number_of_tracks,
  uint tracks_offset)
{

  float tr_state_x[Velo::Constants::max_tracks];
  float tr_state_y[Velo::Constants::max_tracks];
  float tr_state_z[Velo::Constants::max_tracks];

  float tr_state_tx[Velo::Constants::max_tracks];
  float tr_state_ty[Velo::Constants::max_tracks];

  float tr_state_c00[Velo::Constants::max_tracks];
  float tr_state_c11[Velo::Constants::max_tracks];
  float tr_state_c20[Velo::Constants::max_tracks];
  float tr_state_c22[Velo::Constants::max_tracks];
  float tr_state_c31[Velo::Constants::max_tracks];
  float tr_state_c33[Velo::Constants::max_tracks];

  // position at which derivatives are evaluated

  float3 vtxpos {seedPoint.x, seedPoint.y, seedPoint.z};

  // prepare tracks

  uint pvTrack_counter = 0;

  for (int i = 0; i < number_of_tracks; i++) {
    int index = i + tracks_offset;

    KalmanVeloState trk = velo_states.get(index);
    float new_z = vtxpos.z;

    float m_state_x = trk.x;
    float m_state_y = trk.y;
    float m_state_z = trk.z;

    float m_state_tx = trk.tx;
    float m_state_ty = trk.ty;

    float m_state_c00 = trk.c00;
    float m_state_c11 = trk.c11;
    float m_state_c20 = trk.c20;
    float m_state_c22 = trk.c22;
    float m_state_c31 = trk.c31;
    float m_state_c33 = trk.c33;

    const float dz = new_z - m_state_z;
    const float dz2 = dz * dz;

    m_state_x += dz * m_state_tx;
    m_state_y += dz * m_state_ty;
    m_state_z = new_z;
    m_state_c00 += dz2 * m_state_c22 + 2 * dz * m_state_c20;
    m_state_c20 += dz * m_state_c22;
    m_state_c11 += dz2 * m_state_c33 + 2 * dz * m_state_c31;
    m_state_c31 += dz * m_state_c33;

    float2 res {vtxpos.x - m_state_x, vtxpos.y - m_state_y};

    float tr_chi2 = res.x * res.x / m_state_c00 + res.y * res.y / m_state_c11;

    if (tr_chi2 < PatPV::m_maxChi2) {
      // have to use updated values!!
      tr_state_x[pvTrack_counter] = m_state_x;
      tr_state_y[pvTrack_counter] = m_state_y;
      tr_state_z[pvTrack_counter] = m_state_z;

      tr_state_tx[pvTrack_counter] = m_state_tx;
      tr_state_ty[pvTrack_counter] = m_state_ty;

      tr_state_c00[pvTrack_counter] = m_state_c00;
      tr_state_c11[pvTrack_counter] = m_state_c11;
      tr_state_c20[pvTrack_counter] = m_state_c20;
      tr_state_c22[pvTrack_counter] = m_state_c22;
      tr_state_c31[pvTrack_counter] = m_state_c31;
      tr_state_c33[pvTrack_counter] = m_state_c33;

      pvTrack_counter++;
    }
  }

  if (pvTrack_counter < PatPV::m_minTr) {
    return false;
  }

  float vtxcov[6];
  bool converged = false;
  float maxdz = PatPV::m_maxDeltaZ;
  int nbIter = 0;
  int tracks_in_vertex = 0;
  while ((nbIter < PatPV::m_minIter) || (!converged && nbIter < PatPV::m_Iterations)) {
    ++nbIter;

    float halfD2Chi2DX2_00 = 0.f;
    float halfD2Chi2DX2_10 = 0.f;
    float halfD2Chi2DX2_11 = 0.f;
    float halfD2Chi2DX2_20 = 0.f;
    float halfD2Chi2DX2_21 = 0.f;
    float halfD2Chi2DX2_22 = 0.f;
    PatPV::XYZPoint halfDChi2DX(0.f, 0.f, 0.f);

    // add contribution from all tracks
    float chi2(0);
    size_t ntrin(0);
    for (uint index = 0; index < pvTrack_counter; index++) {

      float new_z = vtxpos.z;
      float m_state_x = tr_state_x[index];
      float m_state_y = tr_state_y[index];
      float m_state_z = tr_state_z[index];

      float m_state_tx = tr_state_tx[index];
      float m_state_ty = tr_state_ty[index];

      float m_state_c00 = tr_state_c00[index];
      float m_state_c11 = tr_state_c11[index];
      float m_state_c20 = tr_state_c20[index];
      float m_state_c22 = tr_state_c22[index];
      float m_state_c31 = tr_state_c31[index];
      float m_state_c33 = tr_state_c33[index];

      const float dz = new_z - m_state_z;
      const float dz2 = dz * dz;

      m_state_x += dz * m_state_tx;
      m_state_y += dz * m_state_ty;
      m_state_z = new_z;
      m_state_c00 += dz2 * m_state_c22 + 2 * dz * m_state_c20;
      m_state_c20 += dz * m_state_c22;
      m_state_c11 += dz2 * m_state_c33 + 2 * dz * m_state_c31;
      m_state_c31 += dz * m_state_c33;

      float2 res {vtxpos.x - m_state_x, vtxpos.y - m_state_y};

      float tr_halfD2Chi2DX2_00 = 1.f / m_state_c00;
      float tr_halfD2Chi2DX2_10 = 0.f;
      float tr_halfD2Chi2DX2_11 = 1.f / m_state_c11;
      float tr_halfD2Chi2DX2_20 = -m_state_tx / m_state_c00;
      float tr_halfD2Chi2DX2_21 = -m_state_ty / m_state_c11;
      float tr_halfD2Chi2DX2_22 = m_state_tx * m_state_tx / m_state_c00 + m_state_ty * m_state_ty / m_state_c11;

      float tr_halfDChi2DX_x = res.x / m_state_c00;
      float tr_halfDChi2DX_y = res.y / m_state_c11;
      float tr_halfDChi2DX_z = -m_state_tx * res.x / m_state_c00 - m_state_ty * res.y / m_state_c11;
      float tr_chi2 = res.x * res.x / m_state_c00 + res.y * res.y / m_state_c11;

      float weight = get_tukey_weight(tr_chi2, nbIter);

      // add the track
      if (weight > PatPV::m_minTrackWeight) {
        ++ntrin;
        halfD2Chi2DX2_00 += weight * tr_halfD2Chi2DX2_00;
        halfD2Chi2DX2_10 += weight * tr_halfD2Chi2DX2_10;
        halfD2Chi2DX2_11 += weight * tr_halfD2Chi2DX2_11;
        halfD2Chi2DX2_20 += weight * tr_halfD2Chi2DX2_20;
        halfD2Chi2DX2_21 += weight * tr_halfD2Chi2DX2_21;
        halfD2Chi2DX2_22 += weight * tr_halfD2Chi2DX2_22;

        halfDChi2DX.x += weight * tr_halfDChi2DX_x;
        halfDChi2DX.y += weight * tr_halfDChi2DX_y;
        halfDChi2DX.z += weight * tr_halfDChi2DX_z;

        chi2 += weight * tr_chi2;
      }
    }

    // check nr of tracks that entered the fit
    if (ntrin < PatPV::m_minTr) {

      return false;
    }

    // compute the new vertex covariance

    // replace Cholesky inverter by analytical solution
    float a00 = halfD2Chi2DX2_00;
    float a10 = halfD2Chi2DX2_10;
    float a11 = halfD2Chi2DX2_11;
    float a20 = halfD2Chi2DX2_20;
    float a21 = halfD2Chi2DX2_21;
    float a22 = halfD2Chi2DX2_22;

    float det = a00 * (a22 * a11 - a21 * a21) - a10 * (a22 * a10 - a21 * a20) + a20 * (a21 * a10 - a11 * a20);
    if (det == 0) return false;

    vtxcov[0] = (a22 * a11 - a21 * a21) / det;
    vtxcov[1] = -(a22 * a10 - a20 * a21) / det;
    vtxcov[2] = (a22 * a00 - a20 * a20) / det;
    vtxcov[3] = (a21 * a10 - a20 * a11) / det;
    vtxcov[4] = -(a21 * a00 - a20 * a10) / det;
    vtxcov[5] = (a11 * a00 - a10 * a10) / det;

    // compute the delta
    PatPV::XYZPoint delta {0.f, 0.f, 0.f};
    delta.x = -1.0f * (vtxcov[0] * halfDChi2DX.x + vtxcov[1] * halfDChi2DX.y + vtxcov[3] * halfDChi2DX.z);
    delta.y = -1.0f * (vtxcov[1] * halfDChi2DX.x + vtxcov[2] * halfDChi2DX.y + vtxcov[4] * halfDChi2DX.z);
    delta.z = -1.0f * (vtxcov[3] * halfDChi2DX.x + vtxcov[4] * halfDChi2DX.y + vtxcov[5] * halfDChi2DX.z);

    chi2 += delta.x * halfDChi2DX.x + delta.y * halfDChi2DX.y + delta.z * halfDChi2DX.z;

    // update the position
    vtxpos.x = (vtxpos.x + delta.x);
    vtxpos.y = (vtxpos.y + delta.y);
    vtxpos.z = (vtxpos.z + delta.z);

    vtx.setChi2AndDoF(chi2, 2 * ntrin - 3);

    // loose convergence criteria if close to end of iterations
    if (1.f * nbIter > 0.8f * PatPV::m_Iterations) maxdz = 10.f * PatPV::m_maxDeltaZ;
    converged = fabsf(delta.z) < maxdz;
    tracks_in_vertex = ntrin;
  } // end iteration loop

  if (!converged) return false;

  // set position and covariance
  vtx.setPosition(vtxpos);
  vtx.setCovMatrix(vtxcov);
  // Set tracks. Compute final chi2.

  vtx.nTracks = tracks_in_vertex;

  return true;
}

//=============================================================================
// Get Tukey's weight
//=============================================================================
__device__ float get_tukey_weight(float trchi2, int iter)
{
  if (iter < 1) return 1.f;
  float ctrv = PatPV::m_trackChi * max(PatPV::m_minIter - iter, 1);
  float cT2 = trchi2 / powf(ctrv * PatPV::m_TrackErrorScaleFactor, 2);
  return cT2 < 1.f ? powf(1.f - cT2, 2) : 0.f;
}
