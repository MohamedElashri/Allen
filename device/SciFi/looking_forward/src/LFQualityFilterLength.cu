#include "LFQualityFilterLength.cuh"

void lf_quality_filter_length::lf_quality_filter_length_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_lf_length_filtered_tracks_t>(
    arguments,
    first<host_number_of_reconstructed_ut_tracks_t>(arguments) *
      LookingForward::maximum_number_of_candidates_per_ut_track);
  set_size<dev_scifi_lf_length_filtered_atomics_t>(
    arguments, first<host_number_of_selected_events_t>(arguments) * LookingForward::num_atomics);
  set_size<dev_scifi_lf_parametrization_length_filter_t>(
    arguments,
    4 * first<host_number_of_reconstructed_ut_tracks_t>(arguments) *
      LookingForward::maximum_number_of_candidates_per_ut_track);
}

void lf_quality_filter_length::lf_quality_filter_length_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_scifi_lf_length_filtered_atomics_t>(arguments, 0, cuda_stream);

  device_function(lf_quality_filter_length)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
}

__global__ void lf_quality_filter_length::lf_quality_filter_length(lf_quality_filter_length::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  // UT consolidated tracks
  UT::Consolidated::ConstTracks ut_tracks {
    parameters.dev_atomics_ut, parameters.dev_ut_track_hit_number, event_number, number_of_events};

  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();
  const auto number_of_tracks = parameters.dev_scifi_lf_atomics[event_number];

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
