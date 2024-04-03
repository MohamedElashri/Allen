/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#if defined(TARGET_DEVICE_CUDA)

#if !defined(DEVICE_COMPILER)
#include <cuda_runtime_api.h>
#endif

#include <cuda_runtime.h>
#include <iomanip>
#include <cuda_fp16.h>
#define half_t half
constexpr int warp_size = 32;
#define __bswap(x) __byte_perm(x, x, 0x0123)
#define __fdividef(x, y) ((x) / (y))

// Support for dynamic shared memory buffers
#define DYNAMIC_SHARED_MEMORY_BUFFER(_type, _instance, _config) extern __shared__ _type _instance[];

/**
 * @brief Macro to check cuda calls.
 */
#define cudaCheck(stmt)                                                                                            \
  {                                                                                                                \
    cudaError_t err = stmt;                                                                                        \
    if (err != cudaSuccess) {                                                                                      \
      fprintf(                                                                                                     \
        stderr, "Failed to run %s\n%s (%d) at %s: %d\n", #stmt, cudaGetErrorString(err), err, __FILE__, __LINE__); \
      throw std::invalid_argument("cudaCheck failed");                                                             \
    }                                                                                                              \
  }

#define cudaCheckKernelCall(stmt)                                                                                  \
  {                                                                                                                \
    cudaError_t err = stmt;                                                                                        \
    if (err != cudaSuccess) {                                                                                      \
      fprintf(                                                                                                     \
        stderr, "Failed to invoke kernel\n%s (%d) at %s: %d\n", cudaGetErrorString(err), err, __FILE__, __LINE__); \
      throw std::invalid_argument("cudaCheckKernelCall failed");                                                   \
    }                                                                                                              \
  }

#if defined(DEVICE_COMPILER)
__attribute__((always_inline, const)) __device__ inline uint32_t __lanemask_eq() noexcept
{
  uint32_t mask;
  asm("mov.u32 %0, %%lanemask_eq;" : "=r"(mask));
  return mask;
}

__attribute__((always_inline, const)) __device__ inline uint32_t __lanemask_lt() noexcept
{
  uint32_t mask;
  asm("mov.u32 %0, %%lanemask_lt;" : "=r"(mask));
  return mask;
}

__attribute__((always_inline, const)) __device__ inline uint32_t __lanemask_le() noexcept
{
  uint32_t mask;
  asm("mov.u32 %0, %%lanemask_le;" : "=r"(mask));
  return mask;
}

__attribute__((always_inline, const)) __device__ inline uint32_t __lanemask_gt() noexcept
{
  uint32_t mask;
  asm("mov.u32 %0, %%lanemask_gt;" : "=r"(mask));
  return mask;
}

__attribute__((always_inline, const)) __device__ inline uint32_t __lanemask_ge() noexcept
{
  uint32_t mask;
  asm("mov.u32 %0, %%lanemask_ge;" : "=r"(mask));
  return mask;
}

__attribute__((always_inline, const)) inline __device__ uint32_t conflict_mask(uint32_t mask, uint32_t l) noexcept
{
#if __CUDA_ARCH__ >= 700
  return __match_any_sync(mask, l);
#else
  if (!(mask & __lanemask_eq())) return 0;
  uint32_t ref, ballot;
  int leader;
  goto entry;
loop:
  mask &= ~ballot;
entry:
  leader = __ffs(mask) - 1;
  ref = __shfl_sync(mask, l, leader);
  ballot = __ballot_sync(mask, l == ref);
  if (!(ballot & __lanemask_eq())) goto loop;
  // exit:
  return ballot;
#endif
}
#endif

namespace Allen {
  struct KernelInvocationConfiguration {
    KernelInvocationConfiguration() = default;
    KernelInvocationConfiguration(const dim3&, const dim3&, const unsigned) {}
  };

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  struct Context {
    void initialize(unsigned id) { stream_id = id; }
    unsigned stream_id {0};
  };
#else
  struct Context {
  private:
    cudaStream_t m_stream;

  public:
    Context() {}

    void initialize(unsigned id)
    {
      stream_id = id;
      cudaCheck(cudaStreamCreate(&m_stream));
    }
    unsigned stream_id;

    cudaStream_t inline stream() const { return m_stream; }
  };
#endif

  // Convert kind from Allen::memcpy_kind to cudaMemcpyKind
  cudaMemcpyKind inline convert_allen_to_cuda_kind(Allen::memcpy_kind kind)
  {
    switch (kind) {
    case memcpyHostToHost: return cudaMemcpyHostToHost;
    case memcpyHostToDevice: return cudaMemcpyHostToDevice;
    case memcpyDeviceToHost: return cudaMemcpyDeviceToHost;
    case memcpyDeviceToDevice: return cudaMemcpyDeviceToDevice;
    default: return cudaMemcpyDefault;
    }
  }

  unsigned inline convert_allen_to_cuda_host_register_kind(Allen::host_register_kind kind)
  {
    switch (kind) {
    case hostRegisterPortable: return cudaHostRegisterPortable;
    case hostRegisterMapped: return cudaHostRegisterMapped;
    case hostRegisterIoMemory: return cudaHostRegisterIoMemory;
    case hostRegisterReadOnly: return cudaHostRegisterReadOnly;
    default: return cudaHostRegisterDefault;
    }
  }

  void inline malloc(void** devPtr, size_t size) { cudaCheck(cudaMalloc(devPtr, size)); }

  void inline malloc_host(void** ptr, size_t size) { cudaCheck(cudaMallocHost(ptr, size)); }

  void inline memcpy(void* dst, const void* src, size_t count, Allen::memcpy_kind kind)
  {
    cudaCheck(cudaMemcpy(dst, src, count, convert_allen_to_cuda_kind(kind)));
  }

  template<typename Symbol>
  void inline memcpyToSymbol(Symbol& symbol, const void* src, size_t count)
  {
    cudaCheck(cudaMemcpyToSymbol(symbol, src, count));
  }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline memcpy_async(void* dst, const void* src, size_t count, Allen::memcpy_kind kind, const Context&)
  {
    memcpy(dst, src, count, kind);
  }
#else
  void inline memcpy_async(void* dst, const void* src, size_t count, Allen::memcpy_kind kind, const Context& context)
  {
    cudaCheck(cudaMemcpyAsync(dst, src, count, convert_allen_to_cuda_kind(kind), context.stream()));
  }
#endif

  void inline memset(void* devPtr, int value, size_t count) { cudaCheck(cudaMemset(devPtr, value, count)); }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline memset_async(void* ptr, int value, size_t count, const Context&) { memset(ptr, value, count); }
#else
  void inline memset_async(void* ptr, int value, size_t count, const Context& context)
  {
    cudaCheck(cudaMemsetAsync(ptr, value, count, context.stream()));
  }
#endif

  void inline free_host(void* ptr) { cudaCheck(cudaFreeHost(ptr)); }

  void inline free(void* ptr) { cudaCheck(cudaFree(ptr)); }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline synchronize(const Context&) {}
#else
  void inline synchronize(const Context& context) { cudaCheck(cudaStreamSynchronize(context.stream())); }
#endif

  void inline device_reset() { cudaCheck(cudaDeviceReset()); }

  void inline peek_at_last_error() { cudaCheckKernelCall(cudaPeekAtLastError()); }

  void inline host_unregister(void* ptr) { cudaCheck(cudaHostUnregister(ptr)); }

  void inline host_register(void* ptr, size_t size, host_register_kind flags)
  {
    cudaCheck(cudaHostRegister(ptr, size, convert_allen_to_cuda_host_register_kind(flags)));
  }

  namespace device {
    template<class To, class From>
    __host__ __device__ std::enable_if_t<
      sizeof(To) == sizeof(From) && alignof(To) == alignof(From) && std::is_trivially_copyable_v<From> &&
        std::is_trivially_copyable_v<To>,
      To>
    bit_cast(const From& src) noexcept
    {
      return *reinterpret_cast<const To*>(&src);
    }
  } // namespace device
} // namespace Allen

#endif
