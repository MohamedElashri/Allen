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
  const int* dev_initial_windows,
  const float* dev_scifi_lf_parametrization)
{
  // if (Configuration::verbosity_level >= logger::debug) {
  //   if (blockIdx.y == 0) {
  //     printf("---- Extend Missing X ----\n");
  //   }
  // }

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint i_ut_track = threadIdx.x; i_ut_track < ut_event_number_of_tracks; i_ut_track += blockDim.x) {
    const auto current_ut_track_index = ut_event_tracks_offset + i_ut_track;
    const auto number_of_tracks = dev_atomics_scifi[current_ut_track_index];

    // if (Configuration::verbosity_level >= logger::debug) {
    //   printf("Number of tracks for UT track %i: %i\n", i_ut_track, number_of_tracks);
    // }

    for (uint i = threadIdx.y; i < number_of_tracks; i += blockDim.y) {
      const auto scifi_track_index =
        current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + i;
      SciFi::TrackHits& track = dev_scifi_tracks[scifi_track_index];

      const auto a1 = dev_scifi_lf_parametrization[scifi_track_index];
      const auto b1 = dev_scifi_lf_parametrization
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = dev_scifi_lf_parametrization
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto d_ratio = dev_scifi_lf_parametrization
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];

      // Note: This logic assumes the candidate layers are {0,2,4} and {1,3,5}.
      for (auto current_layer : {1 - track.get_layer(0), 3 - track.get_layer(0), 5 - track.get_layer(0)}) {
        // Find window
        const auto window_start =
          dev_initial_windows[current_ut_track_index + current_layer * 8 * ut_total_number_of_tracks];
        const auto window_size =
          dev_initial_windows[current_ut_track_index + (current_layer * 8 + 1) * ut_total_number_of_tracks];
        const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

        const auto predicted_x = c1 + b1 * (zZone - LookingForward::z_mid_t) +
                                 a1 * (zZone - LookingForward::z_mid_t) * (zZone - LookingForward::z_mid_t) *
                                   (1.f + d_ratio * (zZone - LookingForward::z_mid_t));

        // Pick the best, according to chi2
        int best_index = -1;
        float best_chi2 = 4.f;

        const auto scifi_hits_x0 = scifi_hits.x0 + event_offset + window_start;

        // Binary search of candidate
        const auto candidate_index = binary_search_leftmost(scifi_hits_x0, window_size, predicted_x);

        // It is now either candidate_index-1 or candidate_index
        for (int h4_rel = candidate_index - 1; h4_rel < candidate_index + 1; ++h4_rel) {
          if (h4_rel >= 0 && h4_rel < window_size) {
            const auto x4 = scifi_hits_x0[h4_rel];
            const auto chi2 = (x4 - predicted_x) * (x4 - predicted_x);

            if (chi2 < best_chi2) {
              best_chi2 = chi2;
              best_index = h4_rel;
            }
          }
        }

        if (best_index != -1) {
          track.add_hit_with_quality((uint16_t)(window_start + best_index), best_chi2);
        }
      }
    }
  }
}
