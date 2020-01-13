#include "LFQualityFilterLength.cuh"

__global__ void lf_quality_filter_length::lf_quality_filter_length(lf_quality_filter_length::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  const auto ut_event_tracks_offset = parameters.dev_atomics_ut[number_of_events + event_number];
  const auto number_of_tracks = parameters.dev_scifi_lf_atomics[event_number];
  const auto ut_total_number_of_tracks = parameters.dev_atomics_ut[2 * number_of_events];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    const SciFi::TrackHits& track = parameters.dev_scifi_lf_tracks[scifi_track_index];

    if (track.hitsNum >= LookingForward::track_min_hits) {
      const auto insert_index = atomicAdd(parameters.dev_scifi_lf_length_filtered_atomics + event_number, 1);
      const auto new_scifi_track_index =
        ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + insert_index;

      parameters.dev_scifi_lf_length_filtered_tracks[new_scifi_track_index] = track;

      // Save track parameters to new container as well
      const auto a1 = parameters.dev_scifi_lf_parametrization[scifi_track_index];
      const auto b1 =
        parameters.dev_scifi_lf_parametrization
          [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = parameters.dev_scifi_lf_parametrization
                        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
                         scifi_track_index];
      const auto d_ratio =
        parameters.dev_scifi_lf_parametrization
          [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
           scifi_track_index];

      parameters.dev_scifi_lf_parametrization_length_filter[new_scifi_track_index] = a1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = b1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = c1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
         new_scifi_track_index] = d_ratio;
    }
  }
}
