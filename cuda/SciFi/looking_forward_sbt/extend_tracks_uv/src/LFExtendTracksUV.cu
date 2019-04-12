#include "LFExtendTracksUV.cuh"

__global__ void lf_extend_tracks_uv(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  const int* dev_atomics_scifi,
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

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  // SciFi un-consolidated track types
  const int number_of_tracks = dev_atomics_scifi[event_number];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_tracks[event_number * SciFi::Constants::max_lf_tracks + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    const auto h0 = event_offset + track.hits[0];
    const auto h1 = event_offset + track.hits[1];

    const auto layer0 = scifi_hits.planeCode(h0) >> 1;
    const auto layer1 = scifi_hits.planeCode(h1) >> 1;

    const auto x0 = scifi_hits.x0[h0];
    const auto x1 = scifi_hits.x0[h1];

    const auto z0 = dev_looking_forward_constants->Zone_zPos[layer0];
    const auto z1 = dev_looking_forward_constants->Zone_zPos[layer1];

    for (int relative_extrapolation_layer = threadIdx.y; relative_extrapolation_layer < 6; relative_extrapolation_layer += blockDim.y) {
      const auto layer2 = dev_looking_forward_constants->extrapolation_uv_layers[relative_extrapolation_layer];
      const auto z2 = dev_looking_forward_constants->Zone_zPos[layer2];
      const auto projection_y = LookingForward::y_at_z(dev_ut_states[current_ut_track_index], z2);
      
      // Use UV windows
      const auto uv_window_start = dev_scifi_lf_uv_windows[
        event_number * 6 * SciFi::Constants::max_lf_tracks
        + relative_extrapolation_layer * SciFi::Constants::max_lf_tracks
        + i
      ];

      const auto uv_window_size = dev_scifi_lf_uv_windows[
        number_of_events * 6 * SciFi::Constants::max_lf_tracks
        + event_number * 6 * SciFi::Constants::max_lf_tracks
        + relative_extrapolation_layer * SciFi::Constants::max_lf_tracks
        + i
      ];

      lf_extend_tracks_uv_impl(
        scifi_hits.x0 + event_offset,
        uv_window_start,
        uv_window_size,
        track,
        x0,
        x1,
        z0,
        z1,
        z2,
        projection_y * dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_extrapolation_layer & 0x1],
        dev_looking_forward_constants->chi2_extrapolation_uv_mean[relative_extrapolation_layer] +
          2.5f * dev_looking_forward_constants->chi2_extrapolation_uv_stddev[relative_extrapolation_layer]);
    }
  }
}
