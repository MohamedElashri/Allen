#include "LFFit.cuh"
#include "Invoke.cuh"

void lf_fit_t::invoke() {
  invoke_helper(handler);
}

__device__ void lf_fit_impl(
  SciFi::TrackHits& track,
  const int event_offset,
  const SciFi::Hits& scifi_hits,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState velo_state,
  const float xAtRef_average,
  float* trackParams)
{

  // Note: It is faster to load the hit variables once into registers
  // rather than to access global memory in all the fitting functions
  float hits_x[SciFi::Constants::max_track_size];
  float hits_z[SciFi::Constants::max_track_size];
  float hits_dxdy[SciFi::Constants::max_track_size];
  float hits_w[SciFi::Constants::max_track_size];
  uint8_t n_x_hits = 0;
  for (int j = 0; j < track.hitsNum; ++j) {
    const int hit = event_offset + track.hits[j];
    const int plane_code = scifi_hits.planeCode(hit) >> 1;
    hits_x[j] = scifi_hits.x0[hit];
    hits_dxdy[j] = scifi_hits.dxdy(hit);
    hits_w[j] = scifi_hits.w(hit);
    hits_z[j] = dev_looking_forward_constants->Zone_zPos[plane_code];
    if (!constArrays->is_x_plane[plane_code] && n_x_hits == 0) {
      n_x_hits = j;
    }
  }
  const uint8_t n_uv_hits = track.hitsNum - n_x_hits;

  // initial track parameters
  getTrackParameters(xAtRef_average, velo_state, constArrays, trackParams);

  // fit uv hits to update parameters related to y coordinate
  // update trackParams [4] [5] [6]
  if (!LookingForward::fitParabola_proto(
        hits_x + n_x_hits, hits_z + n_x_hits, hits_dxdy + n_x_hits, hits_w + n_x_hits, n_uv_hits, trackParams, false)) {
    trackParams[7] = -1.f; // set chi2 negative
  }

  // make a fit of all hits using their x coordinate
  // update trackParams [0] [1] [2] (x coordinate related)
  if (!LookingForward::fitParabola_proto(hits_x, hits_z, hits_dxdy, hits_w, track.hitsNum, trackParams, true)) {
    trackParams[7] = -1.f; // set chi2 negative
  }

  // calculate chi2
  if (!LookingForward::getChi2(hits_x, hits_z, hits_dxdy, hits_w, track.hitsNum, trackParams)) {
    trackParams[7] = -1.f; // set chi2 negative
  }
}

__global__ void lf_fit(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const float* dev_scifi_lf_xAtRef_after_length_filter,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const SciFi::Tracking::Arrays* constArrays,
  const LookingForward::Constants* dev_looking_forward_constants,
  float* dev_scifi_lf_track_params)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_lf_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto velo_states_index = velo_tracks_offset_event + ut_tracks.velo_track[track.ut_track_index];
    const MiniState velo_state = velo_states.getMiniState(velo_states_index);
    // load xAtRef average value that was calculated during LFQualityFilterX
    const float xAtRef_average = dev_scifi_lf_xAtRef_after_length_filter
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];

    float* trackParams = dev_scifi_lf_track_params +
                         ut_event_tracks_offset *
                           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter *
                           SciFi::Tracking::nTrackParams +
                         i * SciFi::Tracking::nTrackParams;

    lf_fit_impl(
      track,
      event_offset,
      scifi_hits,
      dev_looking_forward_constants,
      constArrays,
      velo_state,
      xAtRef_average,
      trackParams);
  }
}
