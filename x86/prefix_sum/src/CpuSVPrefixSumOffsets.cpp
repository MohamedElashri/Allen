#include "CpuSVPrefixSumOffsets.h"

void cpu_sv_prefix_sum_offsets_t::set_arguments_size(
  ArgumentRefManager<T> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  set_size<dev_sv_offsets_t>(arguments, value<host_number_of_selected_events_t>(arguments) + 1);
}

void cpu_sv_prefix_sum_offsets_t::operator()(
  const ArgumentRefManager<T>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cudaCheck(cudaMemcpyAsync(
    (uint*) offset<dev_sv_offsets_t>(arguments),
    (uint*) offset<dev_atomics_scifi_t>(arguments),
    value<host_number_of_selected_events_t>(arguments) * sizeof(uint),
    cudaMemcpyDeviceToDevice,
    cuda_stream));

  function(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    (uint*) offset<dev_sv_offsets_t>(arguments),
    (value<host_number_of_selected_events_t>(arguments) + 1) * sizeof(uint),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_number_of_svs);
  
  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_number_of_svs,
      offset<dev_sv_offsets_t>(arguments) + value<host_number_of_selected_events_t>(arguments),
      sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_sv_offsets,
      offset<dev_sv_offsets_t>(arguments),
      (value<host_number_of_selected_events_t>(arguments) + 1) * sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}
