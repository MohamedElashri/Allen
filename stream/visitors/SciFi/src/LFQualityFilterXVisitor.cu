#include "LFQualityFilterX.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_quality_filter_x_t>(
  lf_quality_filter_x_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_filtered_tracks>(host_buffers.host_number_of_selected_events[0] * SciFi::Constants::max_lf_tracks);
  arguments.set_size<dev_scifi_lf_filtered_atomics>(host_buffers.host_number_of_selected_events[0] * LookingForward::num_atomics * 2 + 1);
}

template<>
void SequenceVisitor::visit<lf_quality_filter_x_t>(
  lf_quality_filter_x_t& state,
  const lf_quality_filter_x_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_filtered_atomics>(),
    0,
    arguments.size<dev_scifi_lf_filtered_atomics>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_filtered_atomics>());
  
  state.invoke();
}
