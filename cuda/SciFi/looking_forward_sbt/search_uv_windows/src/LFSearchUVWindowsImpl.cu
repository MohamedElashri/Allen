#include "LFSearchUVWindowsImpl.cuh"

using namespace LookingForward;

__device__ void lf_search_uv_windows_impl(
  const float* scifi_hits_x0,
  const SciFi::HitCount& scifi_hit_count,
  const SciFi::TrackHits& track,
  const float x0,
  const float x1,
  const float z0,
  const float z1,
  const uint event_number,
  const uint number_of_events,
  const uint event_offset,
  const LookingForward::Constants* dev_looking_forward_constants,
  const MiniState& ut_state,
  const int total_number_of_ut_tracks,
  const int ut_event_tracks_offset,
  const int ut_event_number_of_tracks,
  short* dev_scifi_lf_uv_windows)
{
  const auto reco_slope = (x1 - x0) / (z1 - z0);

  for (int relative_uv_layer = 0; relative_uv_layer < 6; relative_uv_layer++) {
    const auto layer2 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
    // dzDy correction
    const auto z2 = dev_looking_forward_constants->Zone_zPos[layer2];
    //const auto projection_y = LookingForward::y_at_z_dzdy_corrected(ut_state, z2);
    const auto projection_y = LookingForward::y_at_z(ut_state, z2);
    const auto layer_offset_nhits =
      LookingForward::get_offset_and_n_hits_for_layer(2 * layer2, scifi_hit_count, projection_y);

    const auto projection_x =
      LookingForward::scifi_propagation(
        x0, reco_slope, track.qop, dev_looking_forward_constants->Zone_zPos_uvlayers[relative_uv_layer] - z0) -
      dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1] * projection_y;

    const auto layer_candidates = LookingForward::find_x_in_window(
      scifi_hits_x0,
      std::get<0>(layer_offset_nhits) - event_offset,
      std::get<1>(layer_offset_nhits),
      projection_x,
      4.f * dev_looking_forward_constants->extrapolation_uv_stddev[relative_uv_layer]);

    dev_scifi_lf_uv_windows
      [ut_event_tracks_offset * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       ut_event_number_of_tracks * relative_uv_layer *
         LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter] = std::get<0>(layer_candidates);

    dev_scifi_lf_uv_windows
      [total_number_of_ut_tracks * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       ut_event_tracks_offset * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       ut_event_number_of_tracks * relative_uv_layer *
         LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter] = std::get<1>(layer_candidates);
  }
}
