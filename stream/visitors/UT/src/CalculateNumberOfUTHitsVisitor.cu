#include "SequenceVisitor.cuh"
#include "UTCalculateNumberOfHits.cuh"

template<>
void SequenceVisitor::set_arguments_size<ut_calculate_number_of_hits_t>(
  const ut_calculate_number_of_hits_t& state,
  ut_calculate_number_of_hits_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_ut_hit_offsets>(
    host_buffers.host_number_of_selected_events[0] * constants.host_unique_x_sector_layer_offsets[4] + 1);
}

template<>
void SequenceVisitor::visit<ut_calculate_number_of_hits_t>(
  ut_calculate_number_of_hits_t& state,
  const ut_calculate_number_of_hits_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // Setup opts and arguments for kernel call
  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_ut_hit_offsets>(), 0, arguments.size<dev_ut_hit_offsets>(), cuda_stream));

  state.set_opts(runtime_options.mep_layout, dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    runtime_options.mep_layout,
    arguments.offset<dev_ut_raw_input>(),
    arguments.offset<dev_ut_raw_input_offsets>(),
    constants.dev_ut_boards.data(),
    constants.dev_ut_region_offsets.data(),
    constants.dev_unique_x_sector_layer_offsets.data(),
    constants.dev_unique_x_sector_offsets.data(),
    arguments.offset<dev_ut_hit_offsets>(),
    arguments.offset<dev_event_list>());

  // Invoke kernel
  state.invoke(runtime_options.mep_layout);
}
