#include "LFQualityFilterCollectedHits.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_quality_filter_collected_hits_t>(
  lf_quality_filter_collected_hits_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_collected_hits_atomics>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_scifi_lf_collected_hits_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track);
}

template<>
void SequenceVisitor::visit<lf_quality_filter_collected_hits_t>(
  lf_quality_filter_collected_hits_t& state,
  const lf_quality_filter_collected_hits_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_collected_hits_atomics>(),
    0,
    arguments.size<dev_scifi_lf_collected_hits_atomics>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0], 24), dim3(32), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_collected_hits_atomics>(),
    arguments.offset<dev_scifi_lf_collected_hits_tracks>());

  state.invoke();
}
