#include "LFQualityFilterLength.cuh"

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  uint* dev_scifi_lf_filtered_atomics)
{
  if (Configuration::verbosity_level >= logger::debug) {
    if (blockIdx.y == 0) {
      printf("\n\n---------- Quality filter length ------------\n");
    }
  }

  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  if (Configuration::verbosity_level >= logger::debug) {
    printf("Number of SciFi tracks: %i\n", number_of_tracks);
  }

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const SciFi::TrackHits& track = dev_scifi_lf_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];

    if (Configuration::verbosity_level >= logger::debug) {
      track.print(event_number);
    }

    if (track.hitsNum >= LookingForward::track_min_hits) {
      const auto insert_index = atomicAdd(dev_scifi_lf_filtered_atomics + event_number, 1);
      dev_scifi_lf_filtered_tracks
        [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         insert_index] = track;
    }
  }
}
