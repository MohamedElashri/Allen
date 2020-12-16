/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#ifdef TARGET_DEVICE_HIP

#if !defined(__HCC__) && !defined(__HIP__)
#define __HIP_PLATFORM_HCC__
#include <hip/hip_runtime_api.h>
#else
#include <hip/hip_runtime.h>
#include <hip/math_functions.h>
#endif

#include "Logger.h"
#include <iomanip>
#include <hip/hip_fp16.h>
#define half_t half

// syncwarp is not supported in HIP. Use syncthreads instead
#define __syncwarp __syncthreads

/**
 * @brief Macro to check hip calls.
 */
#define hipCheck(stmt)                                                                                            \
  {                                                                                                               \
    hipError_t err = stmt;                                                                                        \
    if (err != hipSuccess) {                                                                                      \
      fprintf(                                                                                                    \
        stderr, "Failed to run %s\n%s (%d) at %s: %d\n", #stmt, hipGetErrorString(err), err, __FILE__, __LINE__); \
      throw std::invalid_argument("hipCheck failed");                                                             \
    }                                                                                                             \
  }

#define hipCheckKernelCall(stmt)                                                                                  \
  {                                                                                                               \
    hipError_t err = stmt;                                                                                        \
    if (err != hipSuccess) {                                                                                      \
      fprintf(                                                                                                    \
        stderr, "Failed to invoke kernel\n%s (%d) at %s: %d\n", hipGetErrorString(err), err, __FILE__, __LINE__); \
      throw std::invalid_argument("hipCheckKernelCall failed");                                                   \
    }                                                                                                             \
  }

namespace Allen {
#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  struct Context {
    void initialize() {}
  };
#else
  struct Context {
  private:
    hipStream_t m_stream;

  public:
    Context() {}

    void initialize() { hipCheck(hipStreamCreate(&m_stream)); }

    hipStream_t inline stream() const { return m_stream; }
  };
#endif

  // Convert kind from Allen::memcpy_kind to hipMemcpyKind
  hipMemcpyKind inline convert_allen_to_hip_kind(Allen::memcpy_kind kind)
  {
    switch (kind) {
    case memcpyHostToHost: return hipMemcpyHostToHost;
    case memcpyHostToDevice: return hipMemcpyHostToDevice;
    case memcpyDeviceToHost: return hipMemcpyDeviceToHost;
    case memcpyDeviceToDevice: return hipMemcpyDeviceToDevice;
    default: return hipMemcpyDefault;
    }
  }

  unsigned inline convert_allen_to_hip_host_register_kind(Allen::host_register_kind kind)
  {
    switch (kind) {
    case hostRegisterPortable: return hipHostRegisterPortable;
    case hostRegisterMapped: return hipHostRegisterMapped;
    default: return hipHostRegisterDefault;
    }
  }

  void inline malloc(void** devPtr, size_t size) { hipCheck(hipMalloc(devPtr, size)); }

  void inline malloc_host(void** ptr, size_t size) { hipCheck(hipMallocHost(ptr, size)); }

  void inline memcpy(void* dst, const void* src, size_t count, Allen::memcpy_kind kind)
  {
    hipCheck(hipMemcpy(dst, src, count, convert_allen_to_hip_kind(kind)));
  }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline memcpy_async(void* dst, const void* src, size_t count, Allen::memcpy_kind kind, const Context&)
  {
    memcpy(dst, src, count, kind);
  }
#else
  void inline memcpy_async(void* dst, const void* src, size_t count, Allen::memcpy_kind kind, const Context& context)
  {
    hipCheck(hipMemcpyAsync(dst, src, count, convert_allen_to_hip_kind(kind), context.stream()));
  }
#endif

  void inline memset(void* devPtr, int value, size_t count) { hipCheck(hipMemset(devPtr, value, count)); }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline memset_async(void* ptr, int value, size_t count, const Context&) { memset(ptr, value, count); }
#else
  void inline memset_async(void* ptr, int value, size_t count, const Context& context)
  {
    hipCheck(hipMemsetAsync(ptr, value, count, context.stream()));
  }
#endif

  void inline free_host(void* ptr) { hipCheck(hipFreeHost(ptr)); }

  void inline free(void* ptr) { hipCheck(hipFree(ptr)); }

#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  void inline synchronize(const Context&) {}
#else
  void inline synchronize(const Context& context) { hipCheck(hipStreamSynchronize(context.stream())); }
#endif

  void inline device_reset() { hipCheck(hipDeviceReset()); }

  void inline peek_at_last_error() { hipCheckKernelCall(hipPeekAtLastError()); }

  void inline host_unregister(void* ptr) { hipCheck(hipHostUnregister(ptr)); }

  void inline host_register(void* ptr, size_t size, host_register_kind flags)
  {
    hipCheck(hipHostRegister(ptr, size, convert_allen_to_hip_host_register_kind(flags)));
  }

  /**
   * @brief Prints the memory consumption of the device.
   */
  void inline print_device_memory_consumption()
  {
    size_t free_byte;
    size_t total_byte;
    hipCheck(hipMemGetInfo(&free_byte, &total_byte));
    float free_percent = (float) free_byte / total_byte * 100;
    float used_percent = (float) (total_byte - free_byte) / total_byte * 100;
    verbose_cout << "GPU memory: " << free_percent << " percent free, " << used_percent << " percent used "
                 << std::endl;
  }

  std::tuple<bool, std::string, unsigned> inline set_device(int hip_device, size_t stream_id)
  {
    int n_devices = 0;
    hipDeviceProp device_properties;

    try {
      hipCheck(hipGetDeviceCount(&n_devices));

      debug_cout << "There are " << n_devices << " hip devices available\n";
      for (int cd = 0; cd < n_devices; ++cd) {
        hipDeviceProp device_properties;
        hipCheck(hipGetDeviceProperties(&device_properties, cd));
        debug_cout << std::setw(3) << cd << " " << device_properties.name << "\n";
      }

      if (hip_device >= n_devices) {
        error_cout << "Chosen device (" << hip_device << ") is not available.\n";
        return {false, "", 0};
      }
      debug_cout << "\n";

      hipCheck(hipSetDevice(hip_device));
      hipCheck(hipGetDeviceProperties(&device_properties, hip_device));

      if (n_devices == 0) {
        error_cout << "Failed to select device " << hip_device << "\n";
        return {false, "", 0};
      }
      else {
        debug_cout << "Stream " << stream_id << " selected hip device " << hip_device << ": " << device_properties.name
                   << "\n\n";
      }
    } catch (const std::invalid_argument& e) {
      error_cout << e.what() << std::endl;
      error_cout << "Stream " << stream_id << " failed to select hip device " << hip_device << "\n";
      return {false, "", 0};
    }

    if (device_properties.major == 7 && device_properties.minor == 5) {
      // Turing architecture benefits from setting up cache config to L1
      hipCheck(hipDeviceSetCacheConfig(hipFuncCachePreferL1));
    }

    return {true, device_properties.name, device_properties.textureAlignment};
  }

  std::tuple<bool, int> inline get_device_id(const std::string& pci_bus_id)
  {
    int device = 0;
    try {
      hipCheck(hipDeviceGetByPCIBusId(&device, pci_bus_id.c_str()));
    } catch (std::invalid_argument& a) {
      error_cout << "Failed to get device by PCI bus ID: " << pci_bus_id << "\n";
      return {false, 0};
    }
    return {true, device};
  }
} // namespace Allen

#endif
