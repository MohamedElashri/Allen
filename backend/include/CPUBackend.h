/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#ifdef TARGET_DEVICE_CPU

#include <stdexcept>
#include <cassert>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <regex>

#ifdef __linux__
#include <ext/stdio_filebuf.h>
#endif

using std::copysignf;
using std::max;
using std::min;
using std::signbit;

#define __host__
#define __device__
#define __shared__
#define __global__
#define __constant__
#define __syncthreads()
#define __syncwarp()
#define __launch_bounds__(_i)
#define __popc __builtin_popcount
#define __popcll __builtin_popcountll
#define __ffs __builtin_ffs
#define __clz __builtin_clz
#define __forceinline__ inline
#define CUDART_PI_F M_PI
#define copysignf_impl copysignf
#define fmaxf_impl fmaxf
#define fminf_impl fminf

struct float3 {
  float x;
  float y;
  float z;
};

struct float2 {
  float x;
  float y;
};

struct dim3 {
  unsigned int x = 1;
  unsigned int y = 1;
  unsigned int z = 1;

  dim3() = default;
  dim3(const dim3&) = default;
  dim3(const unsigned int& x) : x(x) {}
  dim3(const unsigned int& x, const unsigned int& y) : x(x), y(y) {}
  dim3(const unsigned int& x, const unsigned int& y, const unsigned int& z) : x(x), y(y), z(z) {}
};

struct GridDimensions {
  unsigned int x;
  unsigned int y;
  unsigned int z;
};

struct BlockIndices {
  unsigned int x;
  unsigned int y;
  unsigned int z;
};

struct BlockDimensions {
  unsigned int x = 1;
  unsigned int y = 1;
  unsigned int z = 1;
};

struct ThreadIndices {
  unsigned int x = 0;
  unsigned int y = 0;
  unsigned int z = 0;
};

extern thread_local GridDimensions gridDim;
extern thread_local BlockIndices blockIdx;
constexpr BlockDimensions blockDim {1, 1, 1};
constexpr ThreadIndices threadIdx {0, 0, 0};

template<class T, class S>
T atomicAdd(T* address, S val)
{
  const T old = *address;
  *address += val;
  return old;
}

template<class T, class S>
T atomicOr(T* address, S val)
{
  const T old = *address;
  *address |= val;
  return old;
}

inline unsigned int atomicInc(unsigned int* address, unsigned int val)
{
  unsigned int old = *address;
  *address = ((old >= val) ? 0 : (old + 1));
  return old;
}

uint16_t __float2half(const float f);

float __half2float(const uint16_t h);

#ifdef CPU_USE_REAL_HALF

/**
 * @brief half_t with int16_t backend (real half).
 */
struct half_t {
private:
  uint16_t m_value;

public:
  half_t() = default;
  half_t(const half_t&) = default;

  half_t(const float f) { m_value = __float2half(f); }

  inline operator float() const { return __half2float(m_value); }

  inline bool operator<(const half_t& a) const
  {
    const auto sign = (m_value >> 15) & 0x01;
    const auto sign_a = (a.get() >> 15) & 0x01;
    return (sign & sign_a & operator!=(a)) ^ (m_value < a.get());
  }

  inline bool operator>(const half_t& a) const
  {
    const auto sign = (m_value >> 15) & 0x01;
    const auto sign_a = (a.get() >> 15) & 0x01;
    return (sign & sign_a & operator!=(a)) ^ (m_value > a.get());
  }

  inline bool operator<=(const half_t& a) const { return !operator>(a); }

  inline bool operator>=(const half_t& a) const { return !operator<(a); }

  inline bool operator==(const half_t& a) const { return m_value == a.get(); }

  inline bool operator!=(const half_t& a) const { return !operator==(a); }
};

#else

/**
 * @brief half_t with float backend.
 */
using half_t = float;

#endif

namespace Allen {
  // Big enough alignment to align with 512-bit vectors
  constexpr static unsigned cpu_alignment = 16;

  struct Context {
    void initialize() {}
  };

  void inline malloc(void** devPtr, size_t size) { posix_memalign(devPtr, 64, size); }

  void inline malloc_host(void** ptr, size_t size) { malloc(ptr, size); }

  void inline memcpy(void* dst, const void* src, size_t count, enum Allen::memcpy_kind)
  {
    std::memcpy(dst, src, count);
  }

  void inline memcpy_async(void* dst, const void* src, size_t count, enum Allen::memcpy_kind kind, const Context&)
  {
    memcpy(dst, src, count, kind);
  }

  void inline memset(void* devPtr, int value, size_t count) { std::memset(devPtr, value, count); }

  void inline memset_async(void* ptr, int value, size_t count, const Context&) { memset(ptr, value, count); }

  void inline free_host(void* ptr) { ::free(ptr); }

  void inline free(void* ptr) { free_host(ptr); }

  void inline synchronize(const Context&) {}

  void inline device_reset() {}

  void inline peek_at_last_error() {}

  void inline host_unregister(void*) {}

  void inline host_register(void*, size_t, host_register_kind) {}

  std::tuple<bool, std::string, unsigned> inline set_device(int, size_t)
  {
#ifdef __linux__
    // Try to get the CPU type on a linux system
    FILE* cmd = popen("grep -m1 -hoE 'model name\\s+.*' /proc/cpuinfo | awk '{ print substr($0, index($0,$4)) }'", "r");
    if (cmd == NULL) return {true, "CPU", 0};

    // Get a string that identifies the CPU
    const int fd = fileno(cmd);
    __gnu_cxx::stdio_filebuf<char> filebuf {fd, std::ios::in};
    std::istream cmd_ifstream {&filebuf};
    std::string processor_name {(std::istreambuf_iterator<char>(cmd_ifstream)), (std::istreambuf_iterator<char>())};

    // Clean the string
    const std::regex regex_to_remove {"(\\(R\\))|(CPU )|( @.*)|(\\(TM\\))|(\n)|( Processor)"};
    processor_name = std::regex_replace(processor_name, regex_to_remove, std::string {});
    
    return {true, processor_name, cpu_alignment};
#else
    return {true, "CPU", cpu_alignment};
#endif // linux-dependent CPU detection
  }

  void inline print_device_memory_consumption() {}

  std::tuple<bool, int> inline get_device_id(std::string) { return {true, 0}; }
} // namespace Allen

#endif
