#include "LFQualityFilterLength.cuh"

void lf_quality_filter_length_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_scifi_lf_length_filtered_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track);
  arguments.set_size<dev_scifi_lf_length_filtered_atomics>(
    host_buffers.host_number_of_selected_events[0] * LookingForward::num_atomics * 2 + 1);
  arguments.set_size<dev_scifi_lf_parametrization_length_filter>(
    4 * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track);
}

void lf_quality_filter_length_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_length_filtered_atomics>(),
    0,
    arguments.size<dev_scifi_lf_length_filtered_atomics>(),
    cuda_stream));
  
  function(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_length_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_length_filtered_atomics>(),
    arguments.offset<dev_scifi_lf_parametrization>(),
    arguments.offset<dev_scifi_lf_parametrization_length_filter>());
}

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  uint* dev_scifi_lf_filtered_atomics,
  const float* dev_scifi_lf_parametrization,
  float* dev_scifi_lf_parametrization_length_filter)
{
  const auto event_number = blockIdx.x;
  const auto number_of_events = gridDim.x;

  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index = ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

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
