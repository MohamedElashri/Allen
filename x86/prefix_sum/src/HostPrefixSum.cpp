#include "HostPrefixSum.h"

void host_prefix_sum::host_prefix_sum_impl(uint* host_prefix_sum_buffer, const size_t input_number_of_elements, uint* host_total_sum_holder)
{
  // Do prefix sum on the host
  uint temp = 0;
  uint temp_sum = 0;
  for (uint i = 0; i < input_number_of_elements; ++i) {
    temp_sum += host_prefix_sum_buffer[i];
    host_prefix_sum_buffer[i] = temp;
    temp = temp_sum;
  }

  // Store the total sum in the output buffer
  host_prefix_sum_buffer[input_number_of_elements] = temp;

  // Store the total sum in host_total_sum_holder as well
  if (host_total_sum_holder != nullptr) {
    host_total_sum_holder[0] = host_prefix_sum_buffer[input_number_of_elements];
  }
}

void host_prefix_sum::host_prefix_sum(
  uint* host_prefix_sum_buffer,
  size_t& host_allocated_prefix_sum_space,
  const size_t dev_input_buffer_size,
  const size_t dev_output_buffer_size,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event,
  host_prefix_sum::Parameters parameters)
{
  assert(dev_output_buffer_size == (dev_input_buffer_size + 1 * sizeof(uint)));
  const auto input_number_of_elements = dev_input_buffer_size / sizeof(uint);

  // Reallocate if insufficient space on host buffer
  if ((input_number_of_elements + 1) > host_allocated_prefix_sum_space) {
    info_cout << "Prefix sum host buffer: Number of elements surpassed (" << host_allocated_prefix_sum_space
      << "). Allocating more space (" << ((input_number_of_elements + 1) * 1.2f) << ").\n";
    host_allocated_prefix_sum_space = (input_number_of_elements + 1) * 1.2f;
    cudaCheck(cudaFreeHost(host_prefix_sum_buffer));
    cudaCheck(cudaMallocHost((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(uint)));
  }

#ifdef CPU
  _unused(cuda_stream);
  _unused(cuda_generic_event);

  // Copy directly data to the output buffer
  std::memcpy(parameters.dev_output_buffer, parameters.dev_input_buffer, dev_input_buffer_size);

  // Perform the prefix sum on the output buffer
  host_prefix_sum_impl(parameters.dev_output_buffer, input_number_of_elements, parameters.host_total_sum_holder);
#else
  // Copy data over to the host
  cudaCheck(cudaMemcpyAsync(
    host_prefix_sum_buffer, parameters.dev_input_buffer, dev_input_buffer_size, cudaMemcpyDeviceToHost, cuda_stream));

  // Synchronize
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

  // Perform the prefix sum
  host_prefix_sum_impl(host_prefix_sum_buffer, input_number_of_elements, parameters.host_total_sum_holder);

  // Copy prefix summed data to the output buffer
  cudaCheck(cudaMemcpyAsync(
    parameters.dev_output_buffer, host_prefix_sum_buffer, dev_output_buffer_size, cudaMemcpyHostToDevice, cuda_stream));
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
  // host_prefix_sum::cpu_prefix_sum(host_prefix_sum_buffer,
  //   host_allocated_prefix_sum_space,
  //   host_prefix_sum::dev_buffer_t{dev_prefix_sum_offset},
  //   dev_prefix_sum_size,
  //   cuda_stream,
  //   cuda_generic_event,
  //   host_prefix_sum::host_total_sum_holder_t{host_total_sum_holder});
}