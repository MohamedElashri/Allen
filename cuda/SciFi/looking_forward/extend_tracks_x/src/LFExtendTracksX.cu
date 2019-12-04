#include "LFExtendTracksX.cuh"
#include "BinarySearch.cuh"
#include "Invoke.cuh"

void lf_extend_tracks_x_t::invoke() {
  invoke_helper(handler);
}

__global__ void lf_extend_tracks_x(
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
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

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
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    SciFi::TrackHits& track = dev_scifi_tracks[scifi_track_index];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    const auto a1 = dev_scifi_lf_parametrization[scifi_track_index];
    const auto b1 = dev_scifi_lf_parametrization
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto c1 = dev_scifi_lf_parametrization
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto d_ratio = dev_scifi_lf_parametrization
      [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];

    // Note: This logic assumes the candidate layers have hits in {T0, T1, T2}
    for (auto current_layer : {1 - track.get_layer(0), 5 - track.get_layer(1), 9 - track.get_layer(2)}) {

      // Note: This logic assumes the candidate layers are {0, 2, 4} and {1, 3, 5}
      // for (auto current_layer : {1 - track.get_layer(0), 3 - track.get_layer(0), 5 - track.get_layer(0)}) {
      // Find window
      const auto window_start = dev_initial_windows
        [current_ut_track_index +
         current_layer * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
      const auto window_size = dev_initial_windows
        [current_ut_track_index +
         (current_layer * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];
      const float z = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

      const auto dz = z - LookingForward::z_mid_t;
      const auto predicted_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);

      // Pick the best, according to chi2
      int best_index = -1;
      float best_chi2 = LookingForward::chi2_max_extrapolation_to_x_layers_single;

      const auto scifi_hits_x0 = scifi_hits.x0 + event_offset + window_start;

      // Binary search of candidate
      const auto candidate_index = binary_search_leftmost(scifi_hits_x0, window_size, predicted_x);

      // It is now either candidate_index - 1 or candidate_index
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
