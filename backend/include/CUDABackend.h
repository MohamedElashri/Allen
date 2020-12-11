/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#if defined(TARGET_DEVICE_CUDA) || defined(TARGET_DEVICE_CUDACLANG)

#if !defined(DEVICE_COMPILER)
#include <cuda_runtime_api.h>

#if defined(TARGET_DEVICE_CUDACLANG)
inline const char* cudaGetErrorString(cudaError_t error) { return ""; }
#endif

#endif

#include "Logger.h"
#include <iomanip>
#include <cuda_fp16.h>
#define half_t half

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

namespace Allen {
#ifdef SYNCHRONOUS_DEVICE_EXECUTION
  struct Context {
    void initialize() {}
  };
#else
  struct Context {
  private:
    cudaStream_t m_stream;

  public:
    Context() {}

    void initialize() { cudaCheck(cudaStreamCreate(&m_stream)); }

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
    default: return cudaHostRegisterDefault;
    }
  }

  void inline malloc(void** devPtr, size_t size) { cudaCheck(cudaMalloc(devPtr, size)); }

  void inline malloc_host(void** ptr, size_t size) { cudaCheck(cudaMallocHost(ptr, size)); }

  void inline memcpy(void* dst, const void* src, size_t count, Allen::memcpy_kind kind)
  {
    cudaCheck(cudaMemcpy(dst, src, count, convert_allen_to_cuda_kind(kind)));
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

  /**
   * @brief Prints the memory consumption of the device.
   */
  void inline print_device_memory_consumption()
  {
    size_t free_byte;
    size_t total_byte;
    cudaCheck(cudaMemGetInfo(&free_byte, &total_byte));
    float free_percent = (float) free_byte / total_byte * 100;
    float used_percent = (float) (total_byte - free_byte) / total_byte * 100;
    verbose_cout << "GPU memory: " << free_percent << " percent free, " << used_percent << " percent used "
                 << std::endl;
  }

  std::tuple<bool, std::string, unsigned> inline set_device(int cuda_device, size_t stream_id)
  {
    int n_devices = 0;
    cudaDeviceProp device_properties;

    try {
      cudaCheck(cudaGetDeviceCount(&n_devices));

      debug_cout << "There are " << n_devices << " CUDA devices available\n";
      for (int cd = 0; cd < n_devices; ++cd) {
        cudaDeviceProp device_properties;
        cudaCheck(cudaGetDeviceProperties(&device_properties, cd));
        debug_cout << std::setw(3) << cd << " " << device_properties.name << "\n";
      }

      if (cuda_device >= n_devices) {
        error_cout << "Chosen device (" << cuda_device << ") is not available.\n";
        return {false, "", 0};
      }
      debug_cout << "\n";

      cudaCheck(cudaSetDevice(cuda_device));
      cudaCheck(cudaGetDeviceProperties(&device_properties, cuda_device));

      if (n_devices == 0) {
        error_cout << "Failed to select device " << cuda_device << "\n";
        return {false, "", 0};
      }
      else {
        debug_cout << "Stream " << stream_id << " selected cuda device " << cuda_device << ": "
                   << device_properties.name << "\n\n";
      }
    } catch (const std::invalid_argument& e) {
      error_cout << e.what() << std::endl;
      error_cout << "Stream " << stream_id << " failed to select cuda device " << cuda_device << "\n";
      return {false, "", 0};
    }

    if (device_properties.major == 7 && device_properties.minor == 5) {
      // Turing architecture benefits from setting up cache config to L1
      cudaCheck(cudaDeviceSetCacheConfig(cudaFuncCachePreferL1));
    }

    return {true, device_properties.name, device_properties.textureAlignment};
  }

  std::tuple<bool, int> inline get_device_id(const std::string& pci_bus_id)
  {
    int device = 0;
    try {
      cudaCheck(cudaDeviceGetByPCIBusId(&device, pci_bus_id.c_str()));
    } catch (std::invalid_argument& a) {
      error_cout << "Failed to get device by PCI bus ID: " << pci_bus_id << "\n";
      return {false, 0};
    }
    return {true, device};
  }
} // namespace Allen

#endif