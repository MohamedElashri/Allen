#include "LFQualityFilterLength.cuh"

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  uint* dev_scifi_lf_filtered_atomics,
  const float* dev_scifi_lf_parametrization,
  float* dev_scifi_lf_parametrization_length_filter)
{
  if (Configuration::verbosity_level >= logger::debug) {
    if (blockIdx.y == 0) {
      printf("\n\n---------- Quality filter length ------------\n");
    }
  }

  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  if (Configuration::verbosity_level >= logger::debug) {
    printf("Number of SciFi tracks: %i\n", number_of_tracks);
  }

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index = ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

    if (Configuration::verbosity_level >= logger::debug) {
      track.print(event_number);
    }

    if (track.hitsNum >= LookingForward::track_min_hits) {
      const auto insert_index = atomicAdd(dev_scifi_lf_filtered_atomics + event_number, 1);
      const auto new_scifi_track_index = ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track +
        insert_index;

      dev_scifi_lf_filtered_tracks[new_scifi_track_index] = track;

      // Save track parameters to new container as well
      const auto a1 = dev_scifi_lf_parametrization[scifi_track_index];
      const auto b1 = dev_scifi_lf_parametrization
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = dev_scifi_lf_parametrization
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         scifi_track_index];
      const auto d_ratio = dev_scifi_lf_parametrization
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         scifi_track_index];

      dev_scifi_lf_parametrization_length_filter[new_scifi_track_index] = a1;
      dev_scifi_lf_parametrization_length_filter
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = b1;
      dev_scifi_lf_parametrization_length_filter
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = c1;
      dev_scifi_lf_parametrization_length_filter
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = d_ratio;
    }
  }
}
