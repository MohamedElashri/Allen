#include "LFQualityFilterLength.cuh"
#include "SequenceVisitor.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(lf_quality_filter_length_t)

template<>
void SequenceVisitor::visit<lf_quality_filter_length_t>(
  lf_quality_filter_length_t& state,
  const lf_quality_filter_length_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_atomics>(),
    0,
    arguments.size<dev_scifi_lf_atomics>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_lf_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_filtered_atomics>(),
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>());
  
  state.invoke();
}
