#include "CpuSVPrefixSumOffsets.h"

void cpu_sv_prefix_sum_offsets_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_sv_offsets>(host_buffers.host_number_of_selected_events[0] + 1);
}

void cpu_sv_prefix_sum_offsets_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cudaCheck(cudaMemcpyAsync(
    (uint*) offset<dev_sv_offsets_t>(arguments),
    (uint*) offset<dev_atomics_scifi_t>(arguments),
    host_buffers.host_number_of_selected_events[0] * sizeof(uint),
    cudaMemcpyDeviceToDevice,
    cuda_stream));

  function(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    (uint*) offset<dev_sv_offsets_t>(arguments),
    (host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_number_of_svs);
  
  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_number_of_svs,
      offset<dev_sv_offsets_t>(arguments) + host_buffers.host_number_of_selected_events[0],
      sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_sv_offsets,
      offset<dev_sv_offsets_t>(arguments),
      (host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}
