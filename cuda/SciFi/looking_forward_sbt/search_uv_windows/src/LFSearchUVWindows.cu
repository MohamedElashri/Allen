#include "LFSearchUVWindows.cuh"

__global__ void lf_search_uv_windows(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_tracks,
  const int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  short* dev_scifi_lf_uv_windows)
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
    const SciFi::TrackHits& track = dev_scifi_tracks[event_number * SciFi::Constants::max_lf_tracks + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    const auto h0 = event_offset + track.hits[0];
    const auto h1 = event_offset + track.hits[1];

    const auto layer0 = scifi_hits.planeCode(h0) >> 1;
    const auto layer1 = scifi_hits.planeCode(h1) >> 1;

    const auto x0 = scifi_hits.x0[h0];
    const auto x1 = scifi_hits.x0[h1];

    const auto z0 = dev_looking_forward_constants->Zone_zPos[layer0];
    const auto z1 = dev_looking_forward_constants->Zone_zPos[layer1];

    lf_search_uv_windows_impl(
      scifi_hits.x0 + event_offset,
      scifi_hit_count,
      track,
      x0,
      x1,
      z0,
      z1,
      event_number,
      number_of_events,
      event_offset,
      dev_looking_forward_constants,
      dev_ut_states[current_ut_track_index],
      dev_scifi_lf_uv_windows + i);
  }
}
