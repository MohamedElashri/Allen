#include "LFSearchInitialWindows.cuh"
#include "LFSearchInitialWindowsImpl.cuh"

__global__ void lf_search_initial_windows(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const SciFi::Tracking::Arrays* dev_constArrays,
  int* dev_forward_windows)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                      (uint*) dev_ut_track_hit_number,
                                      (float*) dev_ut_qop,
                                      (uint*) dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};

  const int n_veloUT_tracks_event = ut_tracks.number_of_tracks(event_number);

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);

  // Loop over the veloUT input tracks
  for (int i_veloUT_track = threadIdx.x; i_veloUT_track < n_veloUT_tracks_event; i_veloUT_track += blockDim.x) {
    const float qop_ut = ut_tracks.qop[i_veloUT_track];
    const int i_velo_track = ut_tracks.velo_track[i_veloUT_track];
    const uint velo_states_index = velo_tracks_offset_event + i_velo_track;
    const MiniState velo_state {velo_states, velo_states_index};

    const float zRef_track = SciFi::Tracking::zReference;
    const float xAtRef = xFromVelo(zRef_track, velo_state);
    const float yAtRef = yFromVelo(zRef_track, velo_state);

    if (yAtRef > -5.f) {
      int forward_windows[4 * SciFi::Tracking::zoneoffsetpar];
      
      lf_search_initial_windows_impl(
        scifi_hits, scifi_hit_count, xAtRef, yAtRef, velo_state, dev_constArrays, qop_ut, 1, forward_windows);

      for (int i = 0; i < 4 * SciFi::Tracking::zoneoffsetpar; ++i) {
        dev_forward_windows[
          i * number_of_events * ut_tracks.total_number_of_tracks +
          ut_tracks.tracks_offset(event_number) +
          i_veloUT_track] = forward_windows[i];
      }
    }

    if (yAtRef < 5.f) {
      int forward_windows[4 * SciFi::Tracking::zoneoffsetpar];

      lf_search_initial_windows_impl(
        scifi_hits, scifi_hit_count, xAtRef, yAtRef, velo_state, dev_constArrays, qop_ut, -1, forward_windows);

      for (int i = 0; i < 4 * SciFi::Tracking::zoneoffsetpar; ++i) {
        dev_forward_windows[
          4 * SciFi::Tracking::zoneoffsetpar * number_of_events * ut_tracks.total_number_of_tracks +
          i * number_of_events * ut_tracks.total_number_of_tracks +
          ut_tracks.tracks_offset(event_number) +
          i_veloUT_track] = forward_windows[i];
      }
    }
  }
}
