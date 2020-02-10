#include "Tools.h"
#include "CudaCommon.h"

void reserve_pinned(void** buffer, size_t size) { cudaCheck(cudaMallocHost(buffer, size)); }

void populate_verbosity_constant_in_device(const uint verbosity) {
  cudaMemcpyToSymbol(Configuration::verbosity_level, &verbosity, sizeof(uint));
}

#ifdef CPU

#include <fstream>
#include <regex>

void reset() {}
void print_gpu_memory_consumption() {}

#ifdef linux
#include <ext/stdio_filebuf.h>
std::tuple<bool, std::string> set_device(int, size_t)
{
  // Assume a linux system and try to get the CPU type
  FILE* cmd = popen("cat /proc/cpuinfo | grep 'model name' | head -n1 | awk '{ print substr($0, index($0,$4)) }'", "r");
  if (cmd == NULL) return {true, "CPU"};

  // Get a string that identifies the CPU
  const int fd = fileno(cmd);
  __gnu_cxx::stdio_filebuf<char> filebuf {fd, std::ios::in};
  std::istream cmd_ifstream {&filebuf};
  std::string processor_name {(std::istreambuf_iterator<char>(cmd_ifstream)), (std::istreambuf_iterator<char>())};

  // Clean the string
  const std::regex regex_to_remove {"(\\(R\\))|(CPU )|( @.*)|(\\(TM\\))"};
  processor_name = std::regex_replace(processor_name, regex_to_remove, std::string {});

  return {true, processor_name};
}
#else
std::tuple<bool, std::string> set_device(int, size_t) { return {true, "CPU"}; }
#endif // linux-dependent CPU detection

std::tuple<bool, int> get_device_id(std::string) {
  return {true, 0};
}

#else

void reset() { cudaCheck(cudaDeviceReset()); }

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

std::tuple<bool, std::string> set_device(int cuda_device, size_t stream_id)
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
      return {false, ""};
    }
    debug_cout << "\n";

    cudaCheck(cudaSetDevice(cuda_device));
    cudaCheck(cudaGetDeviceProperties(&device_properties, cuda_device));

    if (n_devices == 0) {
      error_cout << "Failed to select device " << cuda_device << "\n";
      return {false, ""};
    }
    else {
      debug_cout << "Stream " << stream_id << " selected cuda device " << cuda_device << ": " << device_properties.name
                 << "\n\n";
    }
  } catch (const std::invalid_argument& e) {
    error_cout << e.what() << std::endl;
    error_cout << "Stream " << stream_id << " failed to select cuda device " << cuda_device << "\n";
    return {false, ""};
  }

  if (device_properties.major > 7 || (device_properties.major == 7 && device_properties.minor >= 5)) {
    // Setup cache configuration on Turing onwards to L1
    cudaCheck(cudaDeviceSetCacheConfig(cudaFuncCachePreferL1));
  }

  return {true, device_properties.name};
}

std::tuple<bool, int> get_device_id(std::string pci_bus_id) {
  int device = 0;
  try {
    cudaCheck(cudaDeviceGetByPCIBusId(&device, pci_bus_id.c_str()));
  } catch (std::invalid_argument& a) {
    error_cout << "Failed to get device by PCI bus ID: " << pci_bus_id << "\n";
    return {false, 0};
  }
  return {true, device};
}

#endif
