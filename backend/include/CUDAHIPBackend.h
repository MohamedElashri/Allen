/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#ifdef TARGET_DEVICE_CUDAHIP

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
  struct Context {
  private:
    cudaStream_t m_stream;
    cudaEvent_t m_event;

  public:
    void initialize() {
      cudaCheck(cudaStreamCreate(&m_stream));
      cudaCheck(cudaEventCreateWithFlags(&m_event, cudaEventBlockingSync));
    }

    cudaStream_t inline stream() const { return m_stream; }

    cudaEvent_t inline event() const { return m_event; }
  };

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

  void inline memcpy_async(void* dst, const void* src, size_t count, Allen::memcpy_kind kind, const Context& context)
  {
    cudaCheck(cudaMemcpyAsync(dst, src, count, convert_allen_to_cuda_kind(kind), context.stream()));
  }

  void inline memset(void* devPtr, int value, size_t count) { cudaCheck(cudaMemset(devPtr, value, count)); }

  void inline memset_async(void* ptr, int value, size_t count, const Context& context)
  {
    cudaCheck(cudaMemsetAsync(ptr, value, count, context.stream()));
  }

  void inline free_host(void* ptr) { cudaCheck(cudaFreeHost(ptr)); }

  void inline free(void* ptr) { cudaCheck(cudaFree(ptr)); }

  void inline synchronize(const Context& context)
  {
    cudaEventRecord(context.event(), context.stream());
    cudaEventSynchronize(context.event());
  }

  void inline device_reset() { cudaCheck(cudaDeviceReset()); }

  void inline peek_at_last_error() { cudaCheckKernelCall(cudaPeekAtLastError()); }

  void inline host_unregister(void* ptr) { cudaCheck(cudaHostUnregister(ptr)); }

  void inline host_register(void* ptr, size_t size, host_register_kind flags)
  {
    cudaCheck(cudaHostRegister(ptr, size, convert_allen_to_cuda_host_register_kind(flags)));
  }
} // namespace Allen

#endif
