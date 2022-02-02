/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostPrefixSum.h"
#include <immintrin.h>
#include "Timer.h"

INSTANTIATE_ALGORITHM(host_prefix_sum::host_prefix_sum_t)

void print256_num(__m256i var)
{
  uint32_t val[8];
  memcpy(val, &var, sizeof(val));
  printf("Numerical: %i %i %i %i %i %i %i %i \n", val[0], val[1], val[2], val[3], val[4], val[5], val[6], val[7]);
}

inline __m256i scan_AVX(__m256i x)
{
  __m256 t0, t1;
  // shift1_AVX + add
  t0 = _mm256_permute_ps(reinterpret_cast<__m256*>(&x)[0], _MM_SHUFFLE(2, 1, 0, 3));
  t1 = _mm256_blend_ps(t0, _mm256_permute2f128_ps(t0, t0, 41), 0x11);
  x = _mm256_add_epi32(x, reinterpret_cast<__m256i*>(&t1)[0]);
  // shift2_AVX + add
  t0 = _mm256_permute_ps(reinterpret_cast<__m256*>(&x)[0], _MM_SHUFFLE(1, 0, 3, 2));
  t1 = _mm256_blend_ps(t0, _mm256_permute2f128_ps(t0, t0, 41), 0x33);
  x = _mm256_add_epi32(x, reinterpret_cast<__m256i*>(&t1)[0]);
  // shift3_AVX + add
  x = _mm256_add_epi32(x, _mm256_permute2f128_si256(x, x, 41));
  return x;
}

void prefix_sum_AVX(unsigned* host_prefix_sum_buffer, const size_t size, unsigned* host_total_sum_holder)
{
  __m256i offset = _mm256_setzero_si256();
  for (unsigned i = 0; i < size - (size % 8); i += 8) {
    __m256i x = _mm256_loadu_si256(reinterpret_cast<__m256i_u*>(&host_prefix_sum_buffer[i]));
    __m256i out = scan_AVX(x);
    out = _mm256_add_epi32(out, offset);
    _mm256_storeu_si256(reinterpret_cast<__m256i_u*>(&host_prefix_sum_buffer[i]), out);
    // broadcast last element
    __m256 t0 = _mm256_permute_ps(
      _mm256_permute2f128_ps(reinterpret_cast<__m256*>(&out)[0], reinterpret_cast<__m256*>(&out)[0], 0x11), 0xff);
    offset = reinterpret_cast<__m256i*>(&t0)[0];
  }

  unsigned sum = _mm256_extract_epi32(offset, 0);
  const auto first_element_remaining = size - (size % 8);
  for (unsigned i = 0; i < size % 8; ++i) {
    sum += host_prefix_sum_buffer[first_element_remaining + i];
    host_prefix_sum_buffer[first_element_remaining + i] = sum;
  }

  // Store the total sum in host_total_sum_holder as well
  if (host_total_sum_holder != nullptr) {
    host_total_sum_holder[0] = sum;
  }
}

inline __m128i scan_SSE(__m128i x)
{
  x = _mm_add_epi32(x, _mm_slli_si128(x, 4));
  x = _mm_add_epi32(x, _mm_slli_si128(x, 8));
  return x;
}

void prefix_sum_SSE(unsigned* host_prefix_sum_buffer, const size_t size, unsigned* host_total_sum_holder)
{
  __m128i offset = _mm_setzero_si128();
  for (unsigned i = 0; i < size - (size % 4); i += 4) {
    __m128i x = _mm_load_si128(reinterpret_cast<__m128i*>(&host_prefix_sum_buffer[i]));
    __m128i out = scan_SSE(x);
    out = _mm_add_epi32(out, offset);
    _mm_store_si128(reinterpret_cast<__m128i*>(&host_prefix_sum_buffer[i]), out);
    offset = _mm_shuffle_epi32(out, _MM_SHUFFLE(3, 3, 3, 3));
  }

  unsigned sum = _mm_extract_epi32(offset, 0);
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
  // Timer t0, t1, t2;

  // // Perform the prefix sum in the host
  // t0.start();
  // for (int i = 0; i < 1000; ++i) {
  //   host_prefix_sum_impl(
  //     data<host_output_buffer_t>(arguments),
  //     size<host_output_buffer_t>(arguments),
  //     data<host_total_sum_holder_t>(arguments));
  // }
  // t0.stop();

  // t1.start();
  // for (int i = 0; i < 1000; ++i) {
  //   prefix_sum_AVX(
  //     data<host_output_buffer_t>(arguments),
  //     size<host_output_buffer_t>(arguments),
  //     data<host_total_sum_holder_t>(arguments));
  // }
  // t1.stop();

  // t2.start();
  // for (int i = 0; i < 1000; ++i) {
  //   prefix_sum_SSE(
  //     data<host_output_buffer_t>(arguments),
  //     size<host_output_buffer_t>(arguments),
  //     data<host_total_sum_holder_t>(arguments));
  // }
  // t2.stop();

  // std::cout << "Timing without AVX: " << t0.get() << "\nTiming with AVX: " << t1.get()
  //           << "\nTiming with SSE: " << t2.get()
  //           << "\nSpeedup SSE: " << t0.get() / t2.get() << "x, speedup AVX: " << t0.get() / t1.get() << "\n";

  // Copy data over to the host
  data<host_output_buffer_t>(arguments)[0] = 0;
  Allen::copy<host_output_buffer_t, dev_input_buffer_t>(arguments, context, size<dev_input_buffer_t>(arguments), 1, 0);
  
  prefix_sum_SSE(
    data<host_output_buffer_t>(arguments),
    size<host_output_buffer_t>(arguments),
    data<host_total_sum_holder_t>(arguments));

  // Copy prefix summed data to the device
  Allen::copy_async<dev_output_buffer_t, host_output_buffer_t>(arguments, context);
#endif
}

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
