#include "CpuPrefixSum.h"

void cpu_prefix_sum_impl(uint* host_prefix_sum_buffer, const size_t dev_prefix_sum_size, uint* host_total_sum_holder)
{
  // Do prefix sum on CPU
  const size_t number_of_elements = (dev_prefix_sum_size >> 2) - 1;
  uint temp = 0;
  uint temp_sum = 0;
  for (uint i = 0; i < number_of_elements; ++i) {
    temp_sum += host_prefix_sum_buffer[i];
    host_prefix_sum_buffer[i] = temp;
    temp = temp_sum;
  }
  host_prefix_sum_buffer[number_of_elements] = temp;

  if (host_total_sum_holder != nullptr) {
    host_total_sum_holder[0] = host_prefix_sum_buffer[number_of_elements];
  }
}

void _cpu_prefix_sum::cpu_prefix_sum(
  uint* host_prefix_sum_buffer,
  size_t& host_allocated_prefix_sum_space,
  _cpu_prefix_sum::dev_buffer_t dev_prefix_sum_offset,
  const size_t dev_prefix_sum_size,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event,
  _cpu_prefix_sum::host_total_sum_holder_t host_total_sum_holder)
{
  // Reallocate if insufficient space on host buffer
  if ((dev_prefix_sum_size >> 2) > host_allocated_prefix_sum_space) {
    host_allocated_prefix_sum_space = (dev_prefix_sum_size >> 2) * 1.2f;
    cudaCheck(cudaFreeHost(host_prefix_sum_buffer));
    cudaCheck(cudaMallocHost((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(uint)));
  }

#ifdef CPU
  _unused(cuda_stream);
  _unused(cuda_generic_event);

  host_prefix_sum_buffer = dev_prefix_sum_offset;
#else
  cudaCheck(cudaMemcpyAsync(
    host_prefix_sum_buffer, dev_prefix_sum_offset, dev_prefix_sum_size, cudaMemcpyDeviceToHost, cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
#endif

  cpu_prefix_sum_impl(host_prefix_sum_buffer, dev_prefix_sum_size, host_total_sum_holder);

#ifndef CPU
  cudaCheck(cudaMemcpyAsync(
    dev_prefix_sum_offset, host_prefix_sum_buffer, dev_prefix_sum_size, cudaMemcpyHostToDevice, cuda_stream));
#endif
}

void cpu_prefix_sum(
    uint* host_prefix_sum_buffer,
    size_t& host_allocated_prefix_sum_space,
    uint* dev_prefix_sum_offset,
    const size_t dev_prefix_sum_size,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event,
    uint* host_total_sum_holder) {
  _cpu_prefix_sum::cpu_prefix_sum(host_prefix_sum_buffer,
    host_allocated_prefix_sum_space,
    _cpu_prefix_sum::dev_buffer_t{dev_prefix_sum_offset},
    dev_prefix_sum_size,
    cuda_stream,
    cuda_generic_event,
    _cpu_prefix_sum::host_total_sum_holder_t{host_total_sum_holder});
}