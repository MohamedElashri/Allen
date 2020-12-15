/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#include <tuple>
#include <string>
#include <cassert>
#include "TupleTools.cuh"

// Host / device compiler identification
#if defined(TARGET_DEVICE_CPU) || (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__)) || \
  (defined(TARGET_DEVICE_CUDACLANG) && defined(__clang__) && defined(__CUDA__)) ||        \
  (defined(TARGET_DEVICE_HIP) && (defined(__HCC__) || defined(__HIP__)))
#define DEVICE_COMPILER
#endif

// Dispatch to the right backend
#if defined(TARGET_DEVICE_CPU)
#include "CPUBackend.h"
#elif defined(TARGET_DEVICE_HIP)
#include "HIPBackend.h"
#elif defined(TARGET_DEVICE_CUDA) || defined(TARGET_DEVICE_CUDACLANG)
#include "CUDABackend.h"
#endif

#if defined(DEVICE_COMPILER)
namespace Allen {
  namespace device {
    // Dispatcher targets
    namespace target {
      struct Default {
      };
      struct CPU {
      };
      struct HIP {
      };
      struct CUDA {
      };
    } // namespace target

    /**
     * @brief Allows to write several functions specialized per target.
     * @details Usage:
     *
     *          dispatch<target::Default, target::CPU>(fn0, fn1)(arguments...);
     *
     *          The concrete target on the executing platform is sought first. If none is
     *          available, the default one is chosen. If the default doesn't exist, a static_assert
     *          fails.
     *
     *          List of possible targets:
     *
     *          * Default
     *          * CPU
     *          * HIP
     *          * CUDA
     */
    template<typename... Ts, typename... Fns>
    __device__ constexpr auto dispatch(Fns&&... fns)
    {
      using targets_t = std::tuple<Ts...>;
#if !defined(ALWAYS_DISPATCH_TO_DEFAULT)
#if defined(TARGET_DEVICE_CPU)
      constexpr auto configured_target = index_of_v<target::CPU, targets_t>;
#elif defined(TARGET_DEVICE_CUDA)
      constexpr auto configured_target = index_of_v<target::CUDA, targets_t>;
#elif defined(TARGET_DEVICE_HIP)
      constexpr auto configured_target = index_of_v<target::HIP, targets_t>;
#endif
      if constexpr (configured_target == std::tuple_size<targets_t>::value) {
#endif
        // Dispatch to the default target, check with a static_assert its existence
        constexpr auto default_target = index_of_v<target::Default, targets_t>;
        static_assert(default_target != std::tuple_size<targets_t>::value, "target available for current platform");
        const auto fn = std::get<default_target>(std::tuple<Fns...> {fns...});
        return [fn](auto&&... args) { return fn(args...); };
#if !defined(ALWAYS_DISPATCH_TO_DEFAULT)
      }
      else {
        // Dispatch to the specific target
        const auto fn = std::get<configured_target>(std::tuple<Fns...> {fns...});
        return [fn](auto&&... args) { return fn(args...); };
      }
#endif
    }
  } // namespace device
} // namespace Allen
#endif

// Replacement for gsl::span in device code
namespace Allen {
  namespace device {
    template<class T>
    struct span {
      T* __ptr;
      size_t __size;

      __device__ __host__ T* data() const { return __ptr; }
      __device__ __host__ size_t size() const { return __size; }
      __device__ __host__ T& operator[](int i) { return __ptr[i]; }
      __device__ __host__ const T& operator[](int i) const { return __ptr[i]; }
    };
  } // namespace device
} // namespace Allen

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
  using t = std::add_const_t<U>;
};

std::tuple<bool, int> get_device_id(std::string pci_bus_id);

struct HashNotPopulatedException : public std::exception {
private:
  std::string m_algorithm_name;

public:
  HashNotPopulatedException(const std::string& algorithm_name) :
    m_algorithm_name("Pre or post-scaler hash not populated in selection algorithm " + algorithm_name)
  {}

  const char* what() const noexcept override { return m_algorithm_name.c_str(); }
};

__device__ inline float signselect(const float& s, const float& a, const float& b) { return (s > 0) ? a : b; }
