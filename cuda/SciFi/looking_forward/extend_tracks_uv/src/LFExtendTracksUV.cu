#include "LFExtendTracksUV.cuh"
#include "BinarySearch.cuh"

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
  const int* dev_scifi_lf_initial_windows,
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
    const auto ut_state = dev_ut_states[current_ut_track_index];

    // Use quality normalized
    track.quality *= 0.5f;

    // Load parametrization
    const auto a1 = dev_scifi_lf_parametrization_x_filter[scifi_track_index];
    const auto b1 = dev_scifi_lf_parametrization_x_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto c1 = dev_scifi_lf_parametrization_x_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];

    const auto project_y = [&](const float x_hit, const float z_module, const int layer) {
      const auto Dx = x_hit - (ut_state.x + ut_state.tx * (z_module - ut_state.z));
      const auto tx = ut_state.tx;
      const auto tx2 = ut_state.tx * ut_state.tx;
      const auto tx3 = ut_state.tx * ut_state.tx * ut_state.tx;
      const auto tx4 = ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx;
      const auto tx5 = ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx;
      const auto ty = ut_state.ty;
      const auto ty2 = ut_state.ty * ut_state.ty;
      const auto ty3 = ut_state.ty * ut_state.ty * ut_state.ty;
      const auto ty4 = ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty;
      const auto ty5 = ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty;

      const auto C1y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer];
      const auto C1y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 1];
      const auto C1y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 2];
      const auto C1y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 3];
      const auto C1y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 4];
      const auto C1y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 5];
      const auto C2y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer + 6];
      const auto C2y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 7];
      const auto C2y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 8];
      const auto C2y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 9];
      const auto C2y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 10];
      const auto C2y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 11];
      const auto C3y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer + 12];
      const auto C3y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 13];
      const auto C3y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 14];
      const auto C3y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 15];
      const auto C3y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 16];
      const auto C3y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 17];

      const auto C1y =
        C1y_0 * tx * ty + C1y_1 * tx3 * ty + C1y_2 * tx * ty3 + C1y_3 * tx5 * ty + C1y_4 * tx3 * ty3 + C1y_5 * tx * ty5;
      const auto C2y = C2y_0 * ty + C2y_1 * tx2 * ty + C2y_2 * ty3 + C2y_3 * tx4 * ty + C2y_4 * tx2 * ty3 + C2y_5 * ty5;
      const auto C3y =
        C3y_0 * tx * ty + C3y_1 * tx3 * ty + C3y_2 * tx * ty3 + C3y_3 * tx5 * ty + C3y_4 * tx3 * ty3 + C3y_5 * tx * ty5;
      const auto Dy = Dx * C1y + Dx * Dx * C2y + Dx * Dx * Dx * C3y;
      const auto y = ut_state.y + ut_state.ty * (z_module - ut_state.z) + Dy;

      return y;
    };

    for (int relative_uv_layer = 0; relative_uv_layer < 6; relative_uv_layer++) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];

      // Use UV windows
      const auto uv_window_start = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 2) * ut_total_number_of_tracks];
      const auto uv_window_size = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 3) * ut_total_number_of_tracks];

      const auto dz = z4 - LookingForward::z_mid_t;
      const auto expected_x = c1 + b1 * dz + a1 * dz * dz;
      const auto expected_y =
        project_y(expected_x, z4, dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer]);
      const auto predicted_x =
        expected_x - expected_y * dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1];

      // Pick the best, according to chi2
      const float max_chi2 = 4.f + 20.f / 0.3f * fabsf(ut_state.ty) + 20.f / 0.3f * fabsf(a1 - ut_state.tx);

      int best_index = -1;
      float best_chi2 = max_chi2;

      const auto scifi_hits_x0 = scifi_hits.x0 + event_offset + uv_window_start;

      // Binary search of candidate
      const auto candidate_index = binary_search_leftmost(scifi_hits_x0, uv_window_size, predicted_x);

      // It is now either candidate_index - 1 or candidate_index
      for (int h4_rel = candidate_index - 1; h4_rel < candidate_index + 1; ++h4_rel) {
        if (h4_rel >= 0 && h4_rel < uv_window_size) {
          const auto x4 = scifi_hits_x0[h4_rel];
          const auto chi2 = (x4 - predicted_x) * (x4 - predicted_x);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_index = h4_rel;
          }
        }
      }

      if (best_index != -1) {
        track.add_hit_with_quality((uint16_t) uv_window_start + best_index, best_chi2 / max_chi2);
      }
    }
  }
}
