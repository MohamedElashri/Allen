#include "CpuVeloPrefixSumNumberOfTracks.h"

void cpu_velo_prefix_sum_number_of_tracks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  // Copy
  cudaCheck(cudaMemcpyAsync(
    (uint*) arguments.offset<dev_atomics_velo>() + host_buffers.host_number_of_selected_events[0],
    (uint*) arguments.offset<dev_atomics_velo>(),
    host_buffers.host_number_of_selected_events[0] * sizeof(uint),
    cudaMemcpyDeviceToDevice,
    cuda_stream));

  // Prefix sum
  function.invoke(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    (uint*) arguments.offset<dev_atomics_velo>() + host_buffers.host_number_of_selected_events[0],
    (host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_number_of_reconstructed_velo_tracks);
}
