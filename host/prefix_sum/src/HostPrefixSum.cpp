#include "HostPrefixSum.h"

void host_prefix_sum::host_prefix_sum_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // The total sum holder just holds a single unsigned integer.
  set_size<host_total_sum_holder_t>(arguments, 1);
  set_size<dev_output_buffer_t>(arguments, size<dev_input_buffer_t>(arguments) / sizeof(unsigned) + 1);
  set_size<host_output_buffer_t>(arguments, size<dev_input_buffer_t>(arguments) / sizeof(unsigned) + 1);
}

void host_prefix_sum::host_prefix_sum_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
#if defined(TARGET_DEVICE_CPU)
  // Copy directly data to the output buffer
  copy<dev_output_buffer_t, dev_input_buffer_t>(arguments, context);

  // Perform the prefix sum on the output buffer
  host_prefix_sum_impl(
    data<dev_output_buffer_t>(arguments),
    size<dev_input_buffer_t>(arguments) / sizeof(unsigned),
    data<host_total_sum_holder_t>(arguments));
#else
  // Copy data over to the host
  copy<host_output_buffer_t, dev_input_buffer_t>(arguments, context);

  // Synchronize
  Allen::synchronize(context);

  // Perform the prefix sum in the host
  host_prefix_sum_impl(
    data<host_output_buffer_t>(arguments),
    size<dev_input_buffer_t>(arguments) / sizeof(unsigned),
    data<host_total_sum_holder_t>(arguments));

  // Copy prefix summed data to the device
  copy<dev_output_buffer_t, host_output_buffer_t>(arguments, context);
#endif
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
