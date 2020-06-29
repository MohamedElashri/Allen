/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#ifdef TARGET_DEVICE_CPU

#include "CPUBackend.h"
#include <iostream>

// If supported, compile and use F16C extensions to convert from / to float16
#include "CPUID.h"

int32_t intbits(const float f)
{
  const int32_t* i_p = reinterpret_cast<const int32_t*>(&f);
  return i_p[0];
}

float floatbits(const int32_t i)
{
  const float* f_p = reinterpret_cast<const float*>(&i);
  return f_p[0];
}

uint16_t __float2half_impl(const float f)
{
  // via Fabian "ryg" Giesen.
  // https://gist.github.com/2156668
  constexpr uint32_t sign_mask = 0x80000000u;
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
  // constexpr int32_t magic = 15ul << 23;
  constexpr float fmagic = 1.92592994439e-34f; // equals 15ul << 23
  constexpr uint32_t round_mask = ~0xfffu;
  constexpr int32_t f16infty = 31ul << 23;

  int32_t fint2 = intbits(floatbits(fint & round_mask) * fmagic) - round_mask;
  fint2 = (fint2 > f16infty) ? f16infty : fint2; // Clamp to signed infinity if overflowed

  if (fint < f32infty) o = fint2 >> 13; // Take the bits!

  return (o | (sign >> 16));
}

float __half2float_impl(const uint16_t h)
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

// A good approximation of converting to half and back in a single function
float __float_cap_to_half_precision(const float f) {
  constexpr float fmagic = 1.92592994439e-34f; // equals 15ul << 23
  constexpr uint32_t signs_mask = 0xC0000000u;
  constexpr uint32_t round_mask = ~0xfffu;
  
  const auto fint = intbits(f);
  const auto fint2 = intbits(floatbits(fint & round_mask) * fmagic) - round_mask;
  const auto result = (fint & signs_mask) | (fint2 & 0x07FFE000);
  const auto fresult = floatbits(result);

  return fresult;
}

uint16_t __float2half(const float f) { return __float2half_impl(f); }

float __half2float(const uint16_t h) { return __half2float_impl(h); }

#endif
