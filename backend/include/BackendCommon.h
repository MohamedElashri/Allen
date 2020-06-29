/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#include <tuple>
#include <string>
#include <cassert>

// Dispatch to the right backend
#if defined(TARGET_DEVICE_CPU)
#include "CPUBackend.h"
#elif defined(TARGET_DEVICE_HIP)
#include "HIPBackend.h"
#elif defined(TARGET_DEVICE_CUDA)
#include "CUDABackend.h"
#endif

namespace Allen {
  /**
   * @brief Returns the current local ID.
   * @details This refers in CUDA to threadIdx.x, y, z.
   *          In HIP, threadIdx.x, y, z.
   *          In CPU backend, it is always 0.
   */
  template<unsigned long I>
  unsigned local_id()
  {
    return local_t<I>::id();
  }

  /**
   * @brief Returns the current local ID.
   * @details This refers in CUDA to blockDim.x, y, z.
   *          In HIP, blockDim.x, y, z.
   *          In CPU backend, it is always 0.
   */
  template<unsigned long I>
  unsigned local_size()
  {
    return local_t<I>::size();
  }

  /**
   * @brief Returns current global ID.
   */
  template<unsigned long I>
  unsigned global_id()
  {
    return global_t<I>::id();
  }

  /**
   * @brief Returns current global size.
   */
  template<unsigned long I>
  unsigned global_size()
  {
    return global_t<I>::size();
  }
} // namespace Allen

// Replacement for gsl::span in CUDA code
namespace cuda {
  template<class T>
  struct span {
    T* __ptr;
    size_t __size;

    __device__ __host__ T* data() const { return __ptr; }
    __device__ __host__ size_t size() const { return __size; }
    __device__ __host__ T& operator[](int i) { return __ptr[i]; }
    __device__ __host__ const T operator[](int i) const { return __ptr[i]; }
  };
} // namespace cuda

/**
 * @brief Macro to avoid warnings on Release builds with variables used by asserts.
 */
#define _unused(x) ((void) (x))

void print_gpu_memory_consumption();

std::tuple<bool, std::string> set_device(int cuda_device, size_t stream_id);

// Helper structure to deal with constness of T
template<typename T, typename U>
struct ForwardType {
  using t = U;
};

template<typename T, typename U>
struct ForwardType<const T, U> {
  using t = const U;
};

std::tuple<bool, int> get_device_id(std::string pci_bus_id);
