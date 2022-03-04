/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostPrefixSum.h"

INSTANTIATE_ALGORITHM(host_prefix_sum::host_prefix_sum_t)

#ifdef __x86_64__
#include <immintrin.h>

/**
 * @brief SSE implementation of prefix sum.
 */
void host_prefix_sum::host_prefix_sum_impl(
  unsigned* host_prefix_sum_buffer,
  const size_t size,
  unsigned* host_total_sum_holder)
{
  __m128i offset = _mm_setzero_si128();
  for (unsigned i = 0; i < size - (size % 4); i += 4) {
    __m128i x = _mm_load_si128(reinterpret_cast<__m128i*>(&host_prefix_sum_buffer[i]));
    x = _mm_add_epi32(x, _mm_slli_si128(x, 4));
    x = _mm_add_epi32(x, _mm_slli_si128(x, 8));
    x = _mm_add_epi32(x, offset);
    _mm_store_si128(reinterpret_cast<__m128i*>(&host_prefix_sum_buffer[i]), x);
    offset = _mm_shuffle_epi32(x, _MM_SHUFFLE(3, 3, 3, 3));
  }

  unsigned sum;
  _mm_storeu_si32(&sum, offset);
  const auto first_element_remaining = size - (size % 4);
  for (unsigned i = 0; i < size % 4; ++i) {
    sum += host_prefix_sum_buffer[first_element_remaining + i];
    host_prefix_sum_buffer[first_element_remaining + i] = sum;
  }

  // Store the total sum in host_total_sum_holder as well
  if (host_total_sum_holder != nullptr) {
    host_total_sum_holder[0] = sum;
  }
}

#else

void host_prefix_sum::host_prefix_sum_impl(
  unsigned* host_prefix_sum_buffer,
  const size_t size,
  unsigned* host_total_sum_holder)
{
  // Do prefix sum on the host
  unsigned sum = 0;
  for (unsigned i = 0; i < size; ++i) {
    sum += host_prefix_sum_buffer[i];
    host_prefix_sum_buffer[i] = sum;
  }

  // Store the total sum in host_total_sum_holder as well
  if (host_total_sum_holder != nullptr) {
    host_total_sum_holder[0] = sum;
  }
}

#endif

void host_prefix_sum::host_prefix_sum_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // The total sum holder just holds a single unsigned integer.
  set_size<host_total_sum_holder_t>(arguments, 1);
  set_size<dev_output_buffer_t>(arguments, size<dev_input_buffer_t>(arguments) + 1);
  set_size<host_output_buffer_t>(arguments, size<dev_input_buffer_t>(arguments) + 1);
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
  data<dev_output_buffer_t>(arguments)[0] = 0;
  Allen::copy<dev_output_buffer_t, dev_input_buffer_t>(arguments, context, size<dev_input_buffer_t>(arguments), 1, 0);

  // Perform the prefix sum on the output buffer
  host_prefix_sum_impl(
    data<dev_output_buffer_t>(arguments),
    size<dev_output_buffer_t>(arguments),
    data<host_total_sum_holder_t>(arguments));

  // Ensure host_output_buffer and dev_output_buffer contain the same
  Allen::copy<host_output_buffer_t, dev_output_buffer_t>(arguments, context);
#else
  // Copy data over to the host
  data<host_output_buffer_t>(arguments)[0] = 0;
  Allen::copy<host_output_buffer_t, dev_input_buffer_t>(arguments, context, size<dev_input_buffer_t>(arguments), 1, 0);

  host_prefix_sum_impl(
    data<host_output_buffer_t>(arguments),
    size<host_output_buffer_t>(arguments),
    data<host_total_sum_holder_t>(arguments));

  // Copy prefix summed data to the device
  Allen::copy_async<dev_output_buffer_t, host_output_buffer_t>(arguments, context);
#endif
}
