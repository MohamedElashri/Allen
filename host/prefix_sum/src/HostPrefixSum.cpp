/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostPrefixSum.h"

void host_prefix_sum::host_prefix_sum_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // The total sum holder just holds a single unsigned integer.
  set_size<host_total_sum_holder_t>(arguments, 1);
  set_size<dev_output_buffer_t>(arguments, size<dev_input_buffer_t>(arguments) + 1);
}

void host_prefix_sum::host_prefix_sum_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t& event) const
{
  // Invokes the function
  host_prefix_sum(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    size<dev_input_buffer_t>(arguments) * sizeof(dev_input_buffer_t::type),
    size<dev_output_buffer_t>(arguments) * sizeof(dev_input_buffer_t::type),
    stream,
    event,
    Parameters {data<host_total_sum_holder_t>(arguments),
                data<dev_input_buffer_t>(arguments),
                data<dev_output_buffer_t>(arguments)});
}

void host_prefix_sum::host_prefix_sum_impl(
  unsigned* host_prefix_sum_buffer,
  const size_t input_number_of_elements,
  unsigned* host_total_sum_holder)
{
  // Do prefix sum on the host
  unsigned temp = 0;
  unsigned temp_sum = 0;
  for (unsigned i = 0; i < input_number_of_elements; ++i) {
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
  unsigned* host_prefix_sum_buffer,
  size_t& host_allocated_prefix_sum_space,
  const size_t dev_input_buffer_size,
  [[maybe_unused]] const size_t dev_output_buffer_size,
  cudaStream_t& stream,
  cudaEvent_t& event,
  host_prefix_sum::Parameters parameters)
{
  assert(dev_output_buffer_size == (dev_input_buffer_size + 1 * sizeof(unsigned)));
  const auto input_number_of_elements = dev_input_buffer_size / sizeof(unsigned);

  // Reallocate if insufficient space on host buffer
  if ((input_number_of_elements + 1) > host_allocated_prefix_sum_space) {
    info_cout << "Prefix sum host buffer: Number of elements surpassed (" << input_number_of_elements << " > "
              << host_allocated_prefix_sum_space << "). Allocating more space ("
              << ((input_number_of_elements + 1) * 1.2f) << ").\n";
    host_allocated_prefix_sum_space = (input_number_of_elements + 1) * 1.2f;
    cudaCheck(cudaFreeHost(host_prefix_sum_buffer));
    cudaCheck(cudaMallocHost((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(unsigned)));
  }

#ifdef CPU
  _unused(stream);
  _unused(event);

  // Copy directly data to the output buffer
  std::memcpy(parameters.dev_output_buffer, parameters.dev_input_buffer, dev_input_buffer_size);

  // Perform the prefix sum on the output buffer
  host_prefix_sum_impl(parameters.dev_output_buffer, input_number_of_elements, parameters.host_total_sum_holder);
#else
  // Copy data over to the host
  cudaCheck(cudaMemcpyAsync(
    host_prefix_sum_buffer, parameters.dev_input_buffer, dev_input_buffer_size, cudaMemcpyDeviceToHost, stream));

  // Synchronize
  cudaEventRecord(event, stream);
  cudaEventSynchronize(event);

  // Perform the prefix sum
  host_prefix_sum_impl(host_prefix_sum_buffer, input_number_of_elements, parameters.host_total_sum_holder);

  // Copy prefix summed data to the output buffer
  cudaCheck(cudaMemcpyAsync(
    parameters.dev_output_buffer, host_prefix_sum_buffer, dev_output_buffer_size, cudaMemcpyHostToDevice, stream));
#endif
}
