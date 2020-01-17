#include "SequenceVisitor.cuh"
#include "PrefixSum.cuh"
#include "CpuPrefixSum.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(copy_and_prefix_sum_sel_reps_t)

template<>
void SequenceVisitor::visit<copy_and_prefix_sum_sel_reps_t>(
  copy_and_prefix_sum_sel_reps_t& state,
  const copy_and_prefix_sum_sel_reps_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{

  // TODO: Offloading this prefix sum on the CPU results in a 5-10%
  // efficiency hit. This deserves some investigation. For now just do
  // the prefix sum on the GPU, which takes ~0 time.
  /*
  if (runtime_options.cpu_offload) {
    cudaCheck(cudaMemcpyAsync(
      (uint*) arguments.offset<dev_sel_rep_offsets>() + host_buffers.host_number_of_passing_events[0],
      (uint*) arguments.offset<dev_sel_rep_offsets>(),
      host_buffers.host_number_of_passing_events[0] * sizeof(uint),
      cudaMemcpyDeviceToDevice));    
    
    cpu_prefix_sum(
      host_buffers.host_prefix_sum_buffer,
      host_buffers.host_allocated_prefix_sum_space,
      (uint*) arguments.offset<dev_sel_rep_offsets>() + host_buffers.host_number_of_passing_events[0],
      (host_buffers.host_number_of_passing_events[0] + 1) * sizeof(uint),
      cuda_stream,
      cuda_generic_event,
      host_buffers.host_number_of_sel_rep_words);
    
    cpu_prefix_sum(
      host_buffers.host_prefix_sum_buffer,
      host_buffers.host_allocated_prefix_sum_space,
      //arguments.offset<dev_sel_rep_offsets>() + host_buffers.host_number_of_passing_events[0],
      arguments.offset<dev_sel_rep_offsets>(),
      (host_buffers.host_number_of_passing_events[0] + 1) * sizeof(uint),
      //arguments.size<dev_sel_rep_offsets>(),
      cuda_stream,
      cuda_generic_event,
      host_buffers.host_number_of_sel_rep_words);
  }
  */
  
  state.set_opts(cuda_stream);
  state.set_arguments(
    (uint*) arguments.offset<dev_sel_rep_offsets>() + host_buffers.host_number_of_passing_events[0] * 2,
    (uint*) arguments.offset<dev_sel_rep_offsets>(),
    (uint*) arguments.offset<dev_sel_rep_offsets>() + host_buffers.host_number_of_passing_events[0],
    host_buffers.host_number_of_passing_events[0]);
  state.invoke();

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_sel_rep_offsets,
    arguments.offset<dev_sel_rep_offsets>(),
    (2 * host_buffers.host_number_of_passing_events[0] + 1) * sizeof(uint),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

  // For some reason I can't get the prefix sum to work correctly. For
  // now manually set the total number of words needed for the sel
  // reports.
  host_buffers.host_number_of_sel_rep_words[0] =
    host_buffers.host_sel_rep_offsets[host_buffers.host_number_of_passing_events[0] - 1] +
    host_buffers.host_sel_rep_offsets[2 * host_buffers.host_number_of_passing_events[0] - 1];
  
}