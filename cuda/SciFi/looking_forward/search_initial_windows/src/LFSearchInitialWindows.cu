#include "LFSearchInitialWindows.cuh"
#include "LFSearchInitialWindowsImpl.cuh"

__global__ void lf_search_initial_windows(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_x,
  const float* dev_ut_tx,
  const float* dev_ut_z,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* dev_initial_windows,
  MiniState* dev_ut_states,
  bool* dev_scifi_lf_process_track)
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

  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);
  const auto event_offset = scifi_hit_count.event_offset();

  MiniState* ut_states = dev_ut_states + ut_event_tracks_offset;

  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const int velo_track_index = ut_tracks.velo_track[i];
    const int ut_track_index = ut_event_tracks_offset + i;
    const float ut_qop = ut_tracks.qop[i];

    // Note: These data should be accessed like
    //       the previous ut_tracks.qop[i] in the future
    const float ut_x = dev_ut_x[ut_track_index];
    const float ut_tx = dev_ut_tx[ut_track_index];
    const float ut_z = dev_ut_z[ut_track_index];

    const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
    const MiniState velo_state = velo_states.getMiniState(velo_states_index);

    // extrapolate velo y & ty to z of UT x and tx
    // use ty from Velo state
    const MiniState ut_state {ut_x, LookingForward::y_at_z(velo_state, ut_z), ut_z, ut_tx, velo_state.ty};
    const MiniState state_at_z_last_ut_plane = LookingForward::state_at_z(ut_state, LookingForward::z_last_UT_plane);

    // Store state for access in other algorithms
    if (threadIdx.y == 0) {
      ut_states[i] = state_at_z_last_ut_plane;
    }

    // Parameters for the calculation of the windows
    const float y_projection =
      LookingForward::y_at_z_dzdy_corrected(state_at_z_last_ut_plane, dev_looking_forward_constants->Zone_zPos_xlayers[0]);

    lf_search_initial_windows_impl(
      scifi_hits,
      scifi_hit_count,
      state_at_z_last_ut_plane,
      dev_looking_forward_constants,
      ut_qop,
      (y_projection < 0 ? -1 : 1),
      dev_initial_windows + ut_event_tracks_offset + i,
      ut_tracks.total_number_of_tracks,
      event_offset,
      dev_scifi_lf_process_track,
      ut_track_index);
  }
}
