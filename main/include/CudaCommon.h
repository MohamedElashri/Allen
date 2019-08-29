#pragma once

#include <stdexcept>
#include <iostream>

#ifdef CPU

#include <cmath>

// ---------------
// CPU compilation
// ---------------

#define __host__
#define __device__
#define __shared__
#define __global__
#define __constant__
#define __syncthreads()
#define __launch_bounds__(_i)
#define cudaError_t int
#define cudaEvent_t int
#define cudaStream_t int
#define cudaSuccess 0
#define half_t short
#define __popcll __builtin_popcountll
#define cudaEventBlockingSync 0x01

enum cudaMemcpyKind {
  cudaMemcpyHostToHost,
  cudaMemcpyHostToDevice,
  cudaMemcpyDeviceToHost,
  cudaMemcpyDeviceToDevice,
  cudaMemcpyDefault
};

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

  dim3(const unsigned  int& x);
  dim3(const unsigned int& x, const unsigned int& y);
  dim3(const unsigned int& x, const unsigned int& y, const unsigned int& z);
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
extern thread_local BlockDimensions blockDim;
extern thread_local ThreadIndices threadIdx;

cudaError_t cudaMalloc(void** devPtr, size_t size);
cudaError_t cudaMallocHost(void** ptr, size_t size);
cudaError_t cudaMemcpy(void* dst, const void* src, size_t count, enum cudaMemcpyKind kind);
cudaError_t cudaMemcpyAsync(void* dst, const void* src, size_t count, enum cudaMemcpyKind kind, cudaStream_t stream);
cudaError_t cudaMemset(void* devPtr, int value, size_t count);
cudaError_t cudaMemsetAsync(void* devPtr, int value, size_t count, cudaStream_t stream);
cudaError_t cudaPeekAtLastError();
cudaError_t cudaEventCreate(cudaEvent_t* event);
cudaError_t cudaEventCreateWithFlags(cudaEvent_t* event, int flags);
cudaError_t cudaEventSynchronize(cudaEvent_t event);
cudaError_t cudaEventRecord(cudaEvent_t event, cudaStream_t stream);
cudaError_t cudaFreeHost(void* ptr);
cudaError_t cudaDeviceReset();
cudaError_t cudaStreamCreate(cudaStream_t* pStream);

template<class T, class S>
T atomicAdd(T* address, S val) {
  const T old = *address;
  *address += val;
  return old;
}

template<class T>
T max(const T& a, const T& b) {
  return std::max(a, b);
}

template<class T>
T min(const T& a, const T& b) {
  return std::min(a, b);
}

unsigned int atomicInc(unsigned int* address,
                       unsigned int val);

half_t __float2half(float value);

#define cudaCheck(stmt)                                    \
  {                                                        \
    cudaError_t err = stmt;                                \
    if (err != cudaSuccess) {                              \
      std::cerr << "Failed to run " << #stmt << std::endl; \
      throw std::invalid_argument("cudaCheck failed");     \
    }                                                      \
  }

#define cudaCheckKernelCall(stmt, kernel_name)                      \
  {                                                                 \
    cudaError_t err = stmt;                                         \
    if (err != cudaSuccess) {                                       \
      std::cerr << "Failed to invoke " << kernel_name << std::endl; \
      throw std::invalid_argument("cudaCheckKernelCall failed");    \
    }                                                               \
  }

#else

// ---------------
// GPU compilation
// ---------------

#include "cuda_runtime.h"
#include <mma.h>
#define half_t half

/**
 * @brief Macro to check cuda calls.
 */
#define cudaCheck(stmt)                                    \
  {                                                        \
    cudaError_t err = stmt;                                \
    if (err != cudaSuccess) {                              \
      std::cerr << "Failed to run " << #stmt << std::endl; \
      std::cerr << cudaGetErrorString(err) << std::endl;   \
      throw std::invalid_argument("cudaCheck failed");     \
    }                                                      \
  }

#define cudaCheckKernelCall(stmt, kernel_name)                      \
  {                                                                 \
    cudaError_t err = stmt;                                         \
    if (err != cudaSuccess) {                                       \
      std::cerr << "Failed to invoke " << kernel_name << std::endl; \
      std::cerr << cudaGetErrorString(err) << std::endl;            \
      throw std::invalid_argument("cudaCheckKernelCall failed");    \
    }                                                               \
  }

#endif

/**
 * @brief Cross architecture for statement.
 * @details It can be used to iterate with variable _TYPE _I from 0 through _END.
 */
#ifdef __CUDA_ARCH__
#define FOR_STATEMENT(_TYPE, _I, _END) for (_TYPE _I = threadIdx.x; _I < _END; _I += blockDim.x)
#else
#define FOR_STATEMENT(_TYPE, _I, _END) for (_TYPE _I = 0; _I < _END; ++_I)
#endif

void print_gpu_memory_consumption();

std::tuple<bool, std::string> set_device(int cuda_device, size_t stream_id);
