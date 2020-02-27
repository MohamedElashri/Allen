#include "CudaCommon.h"

#ifdef CPU

#include <cstring>
#include "stdlib.h"

thread_local GridDimensions gridDim;
thread_local BlockIndices blockIdx;

dim3::dim3(const unsigned int& x) : x(x) {}
dim3::dim3(const unsigned int& x, const unsigned int& y) : x(x), y(y) {}
dim3::dim3(const unsigned int& x, const unsigned int& y, const unsigned int& z) : x(x), y(y), z(z) {}

cudaError_t cudaMalloc(void** devPtr, size_t size)
{
  posix_memalign(devPtr, 64, size);
  return 0;
}

cudaError_t cudaMallocHost(void** ptr, size_t size)
{
  posix_memalign(ptr, 64, size);
  return 0;
}

cudaError_t cudaMemcpy(void* dst, const void* src, size_t count, enum cudaMemcpyKind)
{
  std::memcpy(dst, src, count);
  return 0;
}

cudaError_t cudaMemcpyAsync(void* dst, const void* src, size_t count, enum cudaMemcpyKind, cudaStream_t)
{
  std::memcpy(dst, src, count);
  return 0;
}

cudaError_t cudaMemset(void* devPtr, int value, size_t count)
{
  std::memset(devPtr, value, count);
  return 0;
}

cudaError_t cudaMemsetAsync(void* devPtr, int value, size_t count, cudaStream_t)
{
  std::memset(devPtr, value, count);
  return 0;
}

cudaError_t cudaPeekAtLastError() { return 0; }

cudaError_t cudaEventCreate(cudaEvent_t*) { return 0; }

cudaError_t cudaEventCreateWithFlags(cudaEvent_t*, int) { return 0; }

cudaError_t cudaEventSynchronize(cudaEvent_t) { return 0; }

cudaError_t cudaEventRecord(cudaEvent_t, cudaStream_t) { return 0; }

cudaError_t cudaFreeHost(void* ptr)
{
  free(ptr);
  return 0;
}

cudaError_t cudaFree(void* ptr)
{
  free(ptr);
  return 0;
}

cudaError_t cudaDeviceReset() { return 0; }

cudaError_t cudaStreamCreate(cudaStream_t*) { return 0; }

cudaError_t cudaMemcpyToSymbol(void* symbol, const void* src, size_t count, size_t offset, enum cudaMemcpyKind)
{
  std::memcpy(symbol, reinterpret_cast<const char*>(src) + offset, count);
  return 0;
}

unsigned int atomicInc(unsigned int* address, unsigned int val)
{
  unsigned int old = *address;
  *address = ((old >= val) ? 0 : (old + 1));
  return old;
}

namespace Configuration {
  uint verbosity_level;
}

#endif

#if defined(CPU) || defined(HIP)

__device__ __host__ int32_t intbits(const float f)
{
  int32_t i;
  std::memcpy(&i, &f, sizeof(float));
  return i;
}

__device__ __host__ float floatbits(const int32_t i)
{
  float f;
  std::memcpy(&f, &i, sizeof(float));
  return f;
}

half_t::half_t(const float f) {
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

  m_value = (o | (sign >> 16));
}

half_t::operator float() const {
  constexpr uint32_t shifted_exp = 0x7c00 << 13; // exponent mask after shift

  int32_t o = ((int32_t)(m_value & 0x7fff)) << 13; // exponent/mantissa bits
  uint32_t exp = shifted_exp & o;            // just the exponent
  o += (127 - 15) << 23;                     // exponent adjust

  // handle exponent special cases
  if (exp == shifted_exp)                                   // Inf/NaN?
    o += (128 - 16) << 23;                                  // extra exp adjust
  else if (exp == 0) {                                      // Zero/Denormal?
    o += 1 << 23;                                           // extra exp adjust
    o = intbits(floatbits(o) - floatbits(113 << 23)); // renormalize
  }

  o |= ((int32_t)(m_value & 0x8000)) << 16; // sign bit
  return floatbits(o);
}

int16_t half_t::get() const { return m_value; }

#endif
