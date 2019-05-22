#include "Tools.h"
#include "CudaCommon.h"

void reset() {
  cudaCheck(cudaDeviceReset());
}

void reserve_pinned(void** buffer, size_t size) {
  cudaCheck(cudaMallocHost(buffer, size));
}
