/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

namespace Allen {
  // Holds an execution context. An execution
  // context allows to execute kernels in parallel,
  // and provides a manner for execution to be stopped.
  struct Context;

  // Memcpy kind used in memory transfers, analogous to cudaMemcpyKind
  enum memcpy_kind { memcpyHostToHost, memcpyHostToDevice, memcpyDeviceToHost, memcpyDeviceToDevice, memcpyDefault };

  enum host_register_kind { hostRegisterDefault, hostRegisterPortable, hostRegisterMapped };

  enum class error { success, errorMemoryAllocation };

  void malloc(void** devPtr, size_t size);
  void malloc_host(void** ptr, size_t size);
  void memcpy(void* dst, const void* src, size_t count, enum memcpy_kind kind);
  void memcpy_async(void* dst, const void* src, size_t count, enum memcpy_kind kind, const Context& context);
  void memset(void* devPtr, int value, size_t count);
  void memset_async(void* ptr, int value, size_t count, const Context& context);
  void free_host(void* ptr);
  void free(void* ptr);
  void synchronize(const Context& context);
  void device_reset();
  void peek_at_last_error();
  void host_unregister(void* ptr);
  void host_register(void* ptr, size_t size, enum host_register_kind flags);
  std::tuple<bool, std::string, unsigned> set_device(int cuda_device, size_t stream_id);
  void print_device_memory_consumption();
  std::tuple<bool, int> get_device_id(const std::string& pci_bus_id);

  namespace constants {
    // Do not include cmath or math_constants just for this one constant
    constexpr float pi_f_float = 3.141592654f;
  } // namespace constants
} // namespace Allen
