#include "LFQualityFilterLength.cuh"
#include "Invoke.cuh"

void lf_quality_filter_length_t::invoke() {
  invoke_helper(handler);
}

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const float* dev_scifi_lf_xAtRef,
  float* dev_scifi_lf_xAtRef_after_length_filter,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  uint* dev_scifi_lf_filtered_atomics)
{
  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const SciFi::TrackHits& track = dev_scifi_lf_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    if (track.hitsNum >= LookingForward::track_min_hits) {
      const auto insert_index = atomicAdd(dev_scifi_lf_filtered_atomics + event_number, 1);
      dev_scifi_lf_filtered_tracks
        [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         insert_index] = track;
      dev_scifi_lf_xAtRef_after_length_filter
        [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         insert_index] = dev_scifi_lf_xAtRef
          [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    }
  }
}
