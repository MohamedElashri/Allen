#include "LFExtendTracksUV.cuh"

__global__ void lf_extend_tracks_uv(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  const uint* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const short* dev_scifi_lf_uv_windows,
  const float* dev_scifi_lf_parametrization_x_filter)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const int ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const int ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_atomics_scifi[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i;
    SciFi::TrackHits& track = dev_scifi_tracks[scifi_track_index];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    // Load parametrization
    const auto a1 = dev_scifi_lf_parametrization_x_filter[scifi_track_index];
    const auto b1 = dev_scifi_lf_parametrization_x_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto c1 = dev_scifi_lf_parametrization_x_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto d_ratio = dev_scifi_lf_parametrization_x_filter
      [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];

    for (int relative_extrapolation_layer = 0; relative_extrapolation_layer < 6; relative_extrapolation_layer++) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_extrapolation_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];
      const auto projection_y_zone_dxdy =
        LookingForward::y_at_z_dzdy_corrected(dev_ut_states[current_ut_track_index], z4) *
        dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_extrapolation_layer & 0x1];

      // Use UV windows
      const auto uv_window_start = dev_scifi_lf_uv_windows
        [ut_event_tracks_offset * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         ut_event_number_of_tracks * relative_extrapolation_layer *
           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         i];

      const auto uv_window_size = dev_scifi_lf_uv_windows
        [ut_total_number_of_tracks * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         ut_event_tracks_offset * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         ut_event_number_of_tracks * relative_extrapolation_layer *
           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         i];

      const auto predicted_x = c1 + b1 * (z4 - LookingForward::z_mid_t) +
                               a1 * (z4 - LookingForward::z_mid_t) * (z4 - LookingForward::z_mid_t) *
                                 (1.f + d_ratio * (z4 - LookingForward::z_mid_t));

      if (Configuration::verbosity_level >= logger::debug) {
        printf(" Predicted x: %f\n", predicted_x);
      }

      // Pick the best, according to chi2
      int best_index = -1;
      float best_chi2 = 4.f;

      const auto scifi_hits_x0 = scifi_hits.x0 + event_offset + uv_window_start;
      for (int h4 = 0; h4 < uv_window_size; h4++) {
        const auto x4 = scifi_hits_x0[h4] + projection_y_zone_dxdy;
        const auto chi2 = fabsf(x4 - predicted_x);

        if (chi2 < best_chi2) {
          best_chi2 = chi2;
          best_index = h4;
        }
      }

      if (best_index != -1) {
        track.add_hit((uint16_t) uv_window_start + best_index);
      }

      // lf_extend_tracks_uv_impl(
      //   scifi_hits.x0 + event_offset,
      //   uv_window_start,
      //   uv_window_size,
      //   track,
      //   x0,
      //   x1,
      //   z0,
      //   z1,
      //   z2,
      //   projection_y * dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_extrapolation_layer & 0x1],
      //   LookingForward::chi2_max_extrapolation_to_uv_layers_single);
    }
  }
}
