#include "Tools.h"
#include "CudaCommon.h"

void reset() { cudaCheck(cudaDeviceReset()); }

void reserve_pinned(void** buffer, size_t size) { cudaCheck(cudaMallocHost(buffer, size)); }

/**
 * @brief Prints the memory consumption of the device.
 */
void print_gpu_memory_consumption()
{
  size_t free_byte;
  size_t total_byte;
  cudaCheck(cudaMemGetInfo(&free_byte, &total_byte));
  float free_percent = (float) free_byte / total_byte * 100;
  float used_percent = (float) (total_byte - free_byte) / total_byte * 100;
  verbose_cout << "GPU memory: " << free_percent << " percent free, " << used_percent << " percent used " << std::endl;
}

std::pair<size_t, std::string> set_device(int cuda_device)
{
  int n_devices = 0;
  cudaDeviceProp device_properties;
  cudaCheck(cudaGetDeviceCount(&n_devices));

  debug_cout << "There are " << n_devices << " CUDA devices available" << std::endl;
  for (int cd = 0; cd < n_devices; ++cd) {
    cudaDeviceProp device_properties;
    cudaCheck(cudaGetDeviceProperties(&device_properties, cd));
    debug_cout << std::setw(3) << cd << " " << device_properties.name << std::endl;
  }

  if (cuda_device >= n_devices) {
    error_cout << "Chosen device (" << cuda_device << ") is not available." << std::endl;
    return {0, ""};
  }
  debug_cout << std::endl;

  cudaCheck(cudaSetDevice(cuda_device));
  cudaCheck(cudaGetDeviceProperties(&device_properties, cuda_device));
  return {n_devices, device_properties.name};
}
