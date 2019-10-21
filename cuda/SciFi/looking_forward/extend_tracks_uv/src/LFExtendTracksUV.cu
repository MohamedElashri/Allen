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
  const short* dev_scifi_lf_uv_windows)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const int ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const int total_number_of_ut_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_atomics_scifi[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    // Note: The notation 1, 2, 3 is used here (instead of h0, h1, h2)
    //       to avoid mistakes, as the code is similar to that of Hybrid Seeding
    const auto h1 = event_offset + track.hits[0];
    const auto h2 = event_offset + track.hits[1];
    const auto h3 = event_offset + track.hits[2];
    const auto x1 = scifi_hits.x0[h1];
    const auto x2 = scifi_hits.x0[h2];
    const auto x3 = scifi_hits.x0[h3];
    const auto layer1 = scifi_hits.planeCode(h1) / 2;
    const auto layer2 = scifi_hits.planeCode(h2) / 2;
    const auto layer3 = scifi_hits.planeCode(h3) / 2;
    const auto z1_noref = dev_looking_forward_constants->Zone_zPos[layer1];
    const auto z2_noref = dev_looking_forward_constants->Zone_zPos[layer2];
    const auto z3_noref = dev_looking_forward_constants->Zone_zPos[layer3];

    // From hybrid seeding
    constexpr float z_mid_t = 8520.f * Gaudi::Units::mm;
    constexpr float d_ratio = -0.0000262f;

    const auto z1 = z1_noref - z_mid_t;
    const auto z2 = z2_noref - z_mid_t;
    const auto z3 = z3_noref - z_mid_t;
    const auto corrZ1 = 1.f + d_ratio * z1;
    const auto corrZ2 = 1.f + d_ratio * z2;
    const auto corrZ3 = 1.f + d_ratio * z3;

    const auto det = z1 * z1 * corrZ1 * z2 + z1 * z3 * z3 * corrZ3 + z2 * z2 * corrZ2 * z3 - z2 * z3 * z3 * corrZ3 -
                     z1 * z2 * z2 * corrZ2 - z3 * z1 * z1 * corrZ1;
    const auto det1 = x1 * z2 + z1 * x3 + x2 * z3 - z2 * x3 - z1 * x2 - z3 * x1;
    const auto det2 = z1 * z1 * corrZ1 * x2 + x1 * z3 * z3 * corrZ3 + z2 * z2 * corrZ2 * x3 - x2 * z3 * z3 * corrZ3 -
                      x1 * z2 * z2 * corrZ2 - x3 * z1 * z1 * corrZ1;
    const auto det3 = z1 * z1 * corrZ1 * z2 * x3 + z1 * z3 * z3 * corrZ3 * x2 + z2 * z2 * corrZ2 * z3 * x1 -
                      z2 * z3 * z3 * corrZ3 * x1 - z1 * z2 * z2 * corrZ2 * x3 - z3 * z1 * z1 * corrZ1 * x2;

    const auto recdet = 1.f / det;
    const auto a1 = recdet * det1;
    const auto b1 = recdet * det2;
    const auto c1 = recdet * det3;

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
        [total_number_of_ut_tracks * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         ut_event_tracks_offset * 6 * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         ut_event_number_of_tracks * relative_extrapolation_layer *
           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         i];

      const auto predicted_x =
        c1 + b1 * (z4 - z_mid_t) + a1 * (z4 - z_mid_t) * (z4 - z_mid_t) * (1.f + d_ratio * (z4 - z_mid_t));

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
