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

    // Load parametrization
    const auto a1 = dev_scifi_lf_parametrization_x_filter[scifi_track_index];
    const auto b1 = dev_scifi_lf_parametrization_x_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto c1 = dev_scifi_lf_parametrization_x_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];

    // constexpr float deltaYParams[8] {3.78837f, 73.1636f, 7353.89f, -6347.68f, 20270.3f, 3721.02f, -46038.2f, 230943.f};

    // const auto layer0 = scifi_hits.planeCode(event_offset + track.hits[0]) / 2;
    // const auto layer2 = scifi_hits.planeCode(event_offset + track.hits[2]) / 2;

    // const auto z0 = dev_looking_forward_constants->Zone_zPos[layer0];
    // const auto z2 = dev_looking_forward_constants->Zone_zPos[layer2];

    // const auto x0 = scifi_hits.x0[event_offset + track.hits[0]];
    // const auto x2 = scifi_hits.x0[event_offset + track.hits[2]];
    // const auto SciFi_tx = (x2 - x0) / (z2 - z0);
    // const auto deltaSlope = SciFi_tx - ut_state.tx;
    // const auto absDSlope = fabsf(deltaSlope);
    // const auto direction = -1.f * signbit(deltaSlope);
    // const auto endv_ty = ut_state.ty;
    // const auto endv_ty2 = endv_ty * endv_ty;
    // const auto endv_tx = ut_state.tx;
    // const auto endv_tx2 = endv_tx * endv_tx;

    // const auto ycorr =
    //   absDSlope *
    //   (direction * deltaYParams[0] + deltaYParams[1] * endv_ty + deltaYParams[2] * direction * endv_tx * endv_ty +
    //    deltaYParams[3] * endv_tx2 * endv_ty + deltaYParams[4] * direction * endv_tx2 * endv_tx * endv_ty +
    //    deltaYParams[5] * endv_ty2 * endv_ty + deltaYParams[6] * direction * endv_tx * endv_ty2 * endv_ty +
    //    deltaYParams[7] * endv_tx2 * endv_ty2 * endv_ty);

    for (int relative_uv_layer = 0; relative_uv_layer < 6; relative_uv_layer++) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];

      // Use UV windows
      const auto uv_window_start = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 2) * ut_total_number_of_tracks];
      const auto uv_window_size = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 3) * ut_total_number_of_tracks];

      // TODO: Do ycorr
      const auto projection_y = LookingForward::y_at_z_dzdy_corrected(dev_ut_states[current_ut_track_index], z4);
      // const auto projection_y = ut_state.y + endv_ty * (z4 - ut_state.z) - ycorr;

      const auto dz = z4 - LookingForward::z_mid_t;
      const auto predicted_x =
        c1 + b1 * dz +
        a1 * dz * dz -
        dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1] * projection_y;

      // Pick the best, according to chi2
      int best_index = -1;
      float best_chi2 = 16.f;

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
        track.add_hit_with_quality((uint16_t) uv_window_start + best_index, best_chi2);
      }
    }
  }
}
