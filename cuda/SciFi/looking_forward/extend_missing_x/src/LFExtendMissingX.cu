#include "LFExtendMissingX.cuh"
#include "BinarySearch.cuh"
#include "Invoke.cuh"

void lf_extend_missing_x_t::invoke() {
  invoke_helper(handler);
}

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
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const int number_of_tracks = dev_atomics_scifi[event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    // Find out missing layers
    uint8_t number_of_missing_layers = 0;
    // required at least 4 hits in quality filter x -> only two layers can be missing at most
    uint8_t missing_layers[2];

    for (int j = 0; j < LookingForward::number_of_x_layers; ++j) {
      const auto layer_j = dev_looking_forward_constants->x_layers[j];
      bool found = false;
      for (int k = 0; k < track.hitsNum; ++k) {
        const auto hit_index = event_offset + track.hits[k];
        const auto layer_k = scifi_hits.planeCode(hit_index) >> 1;
        found |= layer_j == layer_k;
      }
      if (!found) {
        missing_layers[number_of_missing_layers++] = j;
      }
    }

    const auto h0 = event_offset + track.hits[0];
    const auto h1 = event_offset + track.hits[1];
    const auto x0 = scifi_hits.x0[h0];
    const auto x1 = scifi_hits.x0[h1];
    const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(0)];
    const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(1)];

    for (int j = 0; j < number_of_missing_layers; ++j) {
      const auto current_layer = missing_layers[j];

      // Find window
      const auto window_start =
        dev_initial_windows[current_ut_track_index + current_layer * 8 * ut_total_number_of_tracks];
      const auto window_size =
        dev_initial_windows[current_ut_track_index + (current_layer * 8 + 1) * ut_total_number_of_tracks];
      const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

      // Try all hits in the window now
      const auto best_index = lf_extend_missing_x_impl(
        scifi_hits.x0 + window_start,
        window_size,
        track,
        x0,
        x1,
        z0,
        z1,
        zZone,
        LookingForward::chi2_max_extrapolation_to_x_layers_single);

      if (best_index != -1) {
        track.add_hit((uint16_t)((window_start - event_offset) + best_index));
      }
    }
  }
}
