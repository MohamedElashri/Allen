#include "LFQualityFilterX.cuh"

__global__ void lf_quality_filter_x(
  const int* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  int* dev_scifi_lf_x_filtered_atomics)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;

  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto number_of_tracks = dev_scifi_lf_atomics[current_ut_track_index];

    // first save indices and qualities of tracks with more than three hits
    for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
      const SciFi::TrackHits& track =
        dev_scifi_lf_tracks[current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + i];
      if (track.hitsNum > 3) {
        const auto insert_index = atomicAdd(dev_scifi_lf_x_filtered_atomics + event_number, 1);
        dev_scifi_lf_x_filtered_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + insert_index] = track;
      }
    }
  }
}
