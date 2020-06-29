/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#ifdef TARGET_DEVICE_CUDA

#include "BackendCommonInterface.h"

#if !defined(__CUDACC__)
#include <cuda_runtime_api.h>
#endif

#include <cuda_fp16.h>
#define half_t half

#include "math_constants.h"

namespace Allen {
  template<>
  class local_t<0> {
    constexpr static unsigned id() {
#ifdef __CUDA_ARCH__
      return threadIdx.x;
#else
      return 0;
#endif
    }

    constexpr static unsigned size() {
#ifdef __CUDA_ARCH__
      return blockDim.x;
#else
      return 0;
#endif
    }
  };

  // template<>
  // class local_t<1> {
  //   constexpr static unsigned id() { return threadIdx.y; }
  //   constexpr static unsigned size() { return blockDim.y; }
  // };

  // template<>
  // class local_t<2> {
  //   constexpr static unsigned id() { return threadIdx.z; }
  //   constexpr static unsigned size() { return blockDim.z; }
  // };

  // template<>
  // class global_t<0> {
  //   constexpr static unsigned id() { return blockIdx.x; }
  //   constexpr static unsigned size() { return gridDim.x; }
  // };

  // template<>
  // class global_t<1> {
  //   constexpr static unsigned id() { return blockIdx.y; }
  //   constexpr static unsigned size() { return gridDim.y; }
  // };

  // template<>
  // class global_t<2> {
  //   constexpr static unsigned id() { return blockIdx.z; }
  //   constexpr static unsigned size() { return gridDim.z; }
  // };
} // namespace Allen

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