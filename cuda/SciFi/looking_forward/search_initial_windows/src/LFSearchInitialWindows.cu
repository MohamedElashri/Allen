#include "LFSearchInitialWindows.cuh"
#include "LFSearchInitialWindowsImpl.cuh"

__global__ void lf_search_initial_windows::lf_search_initial_windows(
  lf_search_initial_windows::Parameters parameters,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};
  const uint velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   event_number,
                                                   number_of_events};

  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::ConstHits scifi_hits(parameters.dev_scifi_hits, total_number_of_hits);
  const auto event_offset = scifi_hit_count.event_offset();

  MiniState* ut_states = parameters.dev_ut_states + ut_event_tracks_offset;

  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const int velo_track_index = ut_tracks.velo_track(i);
    const int ut_track_index = ut_event_tracks_offset + i;
    const float ut_qop = ut_tracks.qop(i);

    // Note: These data should be accessed like
    //       the previous ut_tracks.qop[i] in the future
    const float ut_x = parameters.dev_ut_x[ut_track_index];
    const float ut_tx = parameters.dev_ut_tx[ut_track_index];
    const float ut_z = parameters.dev_ut_z[ut_track_index];

    const uint velo_states_index = velo_event_tracks_offset + velo_track_index;
    const MiniState velo_state = velo_states.getMiniState(velo_states_index);

    // extrapolate velo y & ty to z of UT x and tx
    // use ty from Velo state
    const MiniState ut_state {ut_x, LookingForward::y_at_z(velo_state, ut_z), ut_z, ut_tx, velo_state.ty};
    const MiniState state_at_z_last_ut_plane = LookingForward::state_at_z(ut_state, LookingForward::z_last_UT_plane);

    // Store state for access in other algorithms
    ut_states[i] = state_at_z_last_ut_plane;

    // Parameters for the calculation of the windows
    const float y_projection = LookingForward::y_at_z_dzdy_corrected(
      state_at_z_last_ut_plane, dev_looking_forward_constants->Zone_zPos_xlayers[0]);

    lf_search_initial_windows_impl(
      scifi_hits,
      scifi_hit_count,
      state_at_z_last_ut_plane,
      dev_looking_forward_constants,
      ut_qop,
      y_projection >= 0.f,
      parameters.dev_scifi_lf_initial_windows + ut_event_tracks_offset + i,
      ut_tracks.total_number_of_tracks(),
      event_offset,
      parameters.dev_scifi_lf_process_track,
      ut_track_index);
  }
}
