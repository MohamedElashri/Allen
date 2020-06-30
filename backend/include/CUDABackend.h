/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#ifdef TARGET_DEVICE_CUDA

#include "BackendCommonInterface.h"

#if !defined(DEVICE_COMPILER)
#include <cuda_runtime_api.h>
#endif

#include <cuda_fp16.h>
#define half_t half

#include "math_constants.h"

#if defined(DEVICE_COMPILER)
namespace Allen {
  namespace device {
    template<>
    struct local_t<0> {
      __device__ static unsigned id() { return threadIdx.x; }
      __device__ static unsigned size() { return blockDim.x; }
    };

    template<>
    struct local_t<1> {
      __device__ static unsigned id() { return threadIdx.y; }
      __device__ static unsigned size() { return blockDim.y; }
    };

    template<>
    struct local_t<2> {
      __device__ static unsigned id() { return threadIdx.z; }
      __device__ static unsigned size() { return blockDim.z; }
    };

    template<>
    struct global_t<0> {
      __device__ static unsigned id() { return blockIdx.x; }
      __device__ static unsigned size() { return gridDim.x; }
    };

    template<>
    struct global_t<1> {
      __device__ static unsigned id() { return blockIdx.y; }
      __device__ static unsigned size() { return gridDim.y; }
    };

    template<>
    struct global_t<2> {
      __device__ static unsigned id() { return blockIdx.z; }
      __device__ static unsigned size() { return gridDim.z; }
    };

    __device__ inline void barrier() {
      __syncthreads();
    }
  } // namespace device
} // namespace Allen
#endif

/**
 * @brief Macro to check cuda calls.
 */
#define cudaCheck(stmt)                                \
  {                                                    \
    cudaError_t err = stmt;                            \
    if (err != cudaSuccess) {                          \
      std::cerr << "Failed to run " << #stmt << "\n";  \
      std::cerr << cudaGetErrorString(err) << "\n";    \
      throw std::invalid_argument("cudaCheck failed"); \
    }                                                  \
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

#endif