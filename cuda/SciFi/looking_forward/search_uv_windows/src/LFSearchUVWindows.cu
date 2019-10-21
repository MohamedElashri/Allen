#include "LFSearchUVWindows.cuh"

__global__ void lf_search_uv_windows(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_tracks,
  const uint* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  short* dev_scifi_lf_uv_windows,
  const int* dev_scifi_lf_initial_windows)
{
  __shared__ SciFi::SciFiGeometry scifi_geometry;
  __shared__ SciFi::HitCount scifi_hit_count;
  __shared__ SciFi::Hits scifi_hits;

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const int ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const int total_number_of_ut_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];

  if (threadIdx.x == 0) {
    scifi_geometry = SciFi::SciFiGeometry {dev_scifi_geometry};
    scifi_hit_count = SciFi::HitCount {(uint32_t*) dev_scifi_hit_count, event_number};
    scifi_hits =
      SciFi::Hits {const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  }

  __syncthreads();

  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_atomics_scifi[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const SciFi::TrackHits& track = dev_scifi_tracks
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

    for (int relative_uv_layer = 0; relative_uv_layer < 6; ++relative_uv_layer) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];
      const auto projection_y = LookingForward::y_at_z_dzdy_corrected(dev_ut_states[current_ut_track_index], z4);

      const auto projection_x =
        c1 + b1 * (z4 - z_mid_t) + a1 * (z4 - z_mid_t) * (z4 - z_mid_t) * (1.f + d_ratio * (z4 - z_mid_t)) -
        dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1] * projection_y;

      const auto uv_search_window_start = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 2) * total_number_of_ut_tracks];
      const auto uv_search_window_size = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 3) * total_number_of_ut_tracks];

      const auto layer_candidates = LookingForward::find_x_in_window(
        scifi_hits.x0 + event_offset,
        uv_search_window_start,
        uv_search_window_size,
        projection_x,
        LookingForward::chi2_max_extrapolation_to_uv_layers_single);

      dev_scifi_lf_uv_windows
        [6 * ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         relative_uv_layer * ut_event_number_of_tracks *
           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         i] = std::get<0>(layer_candidates);

      dev_scifi_lf_uv_windows
        [6 * total_number_of_ut_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         6 * ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         relative_uv_layer * ut_event_number_of_tracks *
           LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         i] = std::get<1>(layer_candidates);

      // printf("Candidates: %i, %i\n", std::get<0>(layer_candidates), std::get<1>(layer_candidates));
    }
  }
}
