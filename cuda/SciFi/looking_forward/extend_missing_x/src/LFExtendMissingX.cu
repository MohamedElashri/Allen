#include "LFExtendMissingX.cuh"
#include "BinarySearch.cuh"

__global__ void lf_extend_missing_x(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows)
{
  // if (Configuration::verbosity_level >= logger::debug) {
  //   if (blockIdx.y == 0) {
  //     printf("---- Extend Missing X ----\n");
  //   }
  // }

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const int ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  for (int i_ut_track = threadIdx.x; i_ut_track < ut_event_number_of_tracks; i_ut_track += blockDim.x) {
    const auto current_ut_track_index = ut_event_tracks_offset + i_ut_track;
    int number_of_tracks = dev_atomics_scifi[current_ut_track_index];

    if (Configuration::verbosity_level >= logger::debug) {
      printf("Number of tracks for UT track %i: %i\n", i_ut_track, number_of_tracks);
    }

    for (int i = threadIdx.y; i < number_of_tracks; i += blockDim.y) {
      SciFi::TrackHits& track =
        dev_scifi_tracks[current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + i];

      // Find out missing layers
      uint8_t number_of_missing_layers = 0;
      uint8_t missing_layers[3];

      for (int layer_j = 0; layer_j < LookingForward::number_of_x_layers; ++layer_j) {
        bool found = false;
        for (int k = 0; k < track.hitsNum; ++k) {
          const auto layer_k = track.get_layer(k);
          found |= layer_j == layer_k;
        }
        if (!found) {
          missing_layers[number_of_missing_layers++] = layer_j;
        }
      }

      // Note: The notation 1, 2, 3 is used here (instead of h0, h1, h2)
      //       to avoid mistakes, as the code is similar to that of Hybrid Seeding
      const auto h1 = event_offset + track.hits[0];
      const auto h2 = event_offset + track.hits[1];
      const auto h3 = event_offset + track.hits[2];
      const auto x1 = scifi_hits.x0[h1];
      const auto x2 = scifi_hits.x0[h2];
      const auto x3 = scifi_hits.x0[h3];
      const auto z1_noref = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(0)];
      const auto z2_noref = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(1)];
      const auto z3_noref = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(2)];

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

      for (int j = 0; j < number_of_missing_layers; ++j) {
        const auto current_layer = missing_layers[j];

        // Find window
        const auto window_start =
          dev_initial_windows[current_ut_track_index + current_layer * 8 * ut_total_number_of_tracks];
        const auto window_size =
          dev_initial_windows[current_ut_track_index + (current_layer * 8 + 1) * ut_total_number_of_tracks];
        const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

        const auto predicted_x = c1 + b1 * (zZone - z_mid_t) +
                                 a1 * (zZone - z_mid_t) * (zZone - z_mid_t) * (1.f + d_ratio * (zZone - z_mid_t));

        if (Configuration::verbosity_level >= logger::debug) {
          printf(" Predicted x: %f\n", predicted_x);
        }

        // Pick the best, according to chi2
        int best_index = -1;
        float best_chi2 = 4.f;

        const auto scifi_hits_x0 = scifi_hits.x0 + event_offset + window_start;
        for (int h4_rel = 0; h4_rel < window_size; h4_rel++) {
          const auto x4 = scifi_hits_x0[h4_rel];
          const auto chi2 = fabsf(x4 - predicted_x);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_index = h4_rel;
          }
        }

        if (best_index != -1) {
          track.add_hit((uint16_t)(window_start + best_index));
        }
      }
    }
  }
}
