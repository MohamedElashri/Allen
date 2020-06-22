#include "CudaCommon.h"

// If supported, compile and use F16C extensions to convert from / to float16
#include "CpuID.h"

__host__ __device__ int32_t intbits(const float f)
{
  const int32_t* i_p = reinterpret_cast<const int32_t*>(&f);
  return i_p[0];
}

__host__ __device__ float floatbits(const int32_t i)
{
  const float* f_p = reinterpret_cast<const float*>(&i);
  return f_p[0];
}

__host__ __device__ uint16_t __float2half_impl(const float f)
{
  // via Fabian "ryg" Giesen.
  // https://gist.github.com/2156668
  uint32_t sign_mask = 0x80000000u;
  int32_t o;

  int32_t fint = intbits(f);
  int32_t sign = fint & sign_mask;
  fint ^= sign;

  // NOTE all the integer compares in this function can be safely
  // compiled into signed compares since all operands are below
  // 0x80000000. Important if you want fast straight SSE2 code (since
  // there's no unsigned PCMPGTD).

  // Inf or NaN (all exponent bits set)
  // NaN->qNaN and Inf->Inf
  // unconditional assignment here, will override with right value for
  // the regular case below.
  int32_t f32infty = 255ul << 23;
  o = (fint > f32infty) ? 0x7e00u : 0x7c00u;

  // (De)normalized number or zero
  // update fint unconditionally to save the blending; we don't need it
  // anymore for the Inf/NaN case anyway.

  // const uint32_t round_mask = ~0xffful;
  const uint32_t round_mask = ~0xfffu;
  const int32_t magic = 15ul << 23;
  const int32_t f16infty = 31ul << 23;

  int32_t fint2 = intbits(floatbits(fint & round_mask) * floatbits(magic)) - round_mask;
  fint2 = (fint2 > f16infty) ? f16infty : fint2; // Clamp to signed infinity if overflowed

  if (fint < f32infty) o = fint2 >> 13; // Take the bits!

  return (o | (sign >> 16));
}

__host__ __device__ float __half2float_impl(const uint16_t h)
{
  constexpr uint32_t shifted_exp = 0x7c00 << 13; // exponent mask after shift

  int32_t o = ((int32_t)(h & 0x7fff)) << 13; // exponent/mantissa bits
  uint32_t exp = shifted_exp & o;            // just the exponent
  o += (127 - 15) << 23;                     // exponent adjust

  // handle exponent special cases
  if (exp == shifted_exp)                             // Inf/NaN?
    o += (128 - 16) << 23;                            // extra exp adjust
  else if (exp == 0) {                                // Zero/Denormal?
    o += 1 << 23;                                     // extra exp adjust
    o = intbits(floatbits(o) - floatbits(113 << 23)); // renormalize
  }

  o |= ((int32_t)(h & 0x8000)) << 16; // sign bit
  return floatbits(o);
}

#if defined(TARGET_DEVICE_CPU)

uint16_t __float2half(const float f)
{
#if !defined(__APPLE__) && defined(__F16C__)
  // Check at runtime if the processor supports the F16C extension
  if (cpu_id::supports_feature(bit_F16C, cpu_id::CpuIDRegister::ecx)) {
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc99-extensions"
#endif

    return _cvtss_sh(f, _MM_FROUND_TO_NEAREST_INT | _MM_FROUND_NO_EXC);

#if defined(__clang__)
#pragma clang diagnostic pop
#endif
  }
  else {
    return __float2half_impl(f);
  }
#else
  return __float2half_impl(f);
#endif
}

float __half2float(const uint16_t h)
{
#if !defined(__APPLE__) && defined(__F16C__)
  if (cpu_id::supports_feature(bit_F16C, cpu_id::CpuIDRegister::ecx)) {
    return _cvtsh_ss(h);
  }
  else {
    return __half2float_impl(h);
  }
#else
  return __half2float_impl(h);
#endif
}

#ifdef CPU_USE_REAL_HALF

half_t::half_t(const float f) { m_value = __float2half(f); }

half_t::operator float() const { return __half2float(m_value); }

bool half_t::operator<(const half_t& a) const
{
  const auto sign = (m_value >> 15) & 0x01;
  const auto sign_a = (a.get() >> 15) & 0x01;
  return (sign & sign_a & operator!=(a)) ^ (m_value < a.get());
}

bool half_t::operator>(const half_t& a) const
{
  const auto sign = (m_value >> 15) & 0x01;
  const auto sign_a = (a.get() >> 15) & 0x01;
  return (sign & sign_a & operator!=(a)) ^ (m_value > a.get());
}

bool half_t::operator<=(const half_t& a) const { return !operator>(a); }

bool half_t::operator>=(const half_t& a) const { return !operator<(a); }

bool half_t::operator==(const half_t& a) const { return m_value == a.get(); }

bool half_t::operator!=(const half_t& a) const { return !operator==(a); }
#else
half_t::half_t(const float f) { m_value = __half2float(__float2half(f)); }

half_t::operator float() const { return m_value; }
#endif

#elif defined(DEVICE_TARGET_HIP)

__host__ __device__ uint16_t __float2half(const float f) { return __float2half_impl(f); }

__host__ __device__ float __half2float(const uint16_t h) { return __half2float_impl(h); }

#endif
