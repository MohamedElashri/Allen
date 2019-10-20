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

    const auto h0 = event_offset + track.hits[0];
    const auto h1 = event_offset + track.hits[1];

    const auto x0 = scifi_hits.x0[h0];
    const auto x1 = scifi_hits.x0[h1];

    const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(0)];
    const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(1)];

    const auto reco_slope = (x1 - x0) / (z1 - z0);

    for (int relative_uv_layer = 0; relative_uv_layer < 6; ++relative_uv_layer) {
      const auto layer2 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z2 = dev_looking_forward_constants->Zone_zPos[layer2];
      const auto projection_y = LookingForward::y_at_z_dzdy_corrected(dev_ut_states[current_ut_track_index], z2);

      const auto projection_x =
        LookingForward::scifi_propagation(
          x0, reco_slope, track.qop, dev_looking_forward_constants->Zone_zPos_uvlayers[relative_uv_layer] - z0) -
        dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1] * projection_y;

      const auto uv_search_window_start = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 2) * total_number_of_ut_tracks];
      const auto uv_search_window_size = dev_scifi_lf_initial_windows
        [ut_event_tracks_offset + track.ut_track_index + (relative_uv_layer * 8 + 3) * total_number_of_ut_tracks];

      const auto layer_candidates = LookingForward::find_x_in_window(
        scifi_hits.x0 + event_offset,
        uv_search_window_start - event_offset,
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
    }
  }
}
