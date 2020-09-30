/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#if defined(TARGET_DEVICE_CPU)
#include "CPUBackend.h"
#elif defined(TARGET_DEVICE_HIP)
#include "HIPBackend.h"
#elif defined(TARGET_DEVICE_CUDA)
#include "CUDABackend.h"
#endif

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
