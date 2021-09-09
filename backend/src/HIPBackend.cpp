/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#include <HIPBackend.h>
#include <Logger.h>

void Allen::print_device_memory_consumption()
{
  size_t free_byte;
  size_t total_byte;
  hipCheck(hipMemGetInfo(&free_byte, &total_byte));
  float free_percent = (float) free_byte / total_byte * 100;
  float used_percent = (float) (total_byte - free_byte) / total_byte * 100;
  verbose_cout << "GPU memory: " << free_percent << " percent free, " << used_percent << " percent used " << std::endl;
}

std::tuple<bool, std::string, unsigned> Allen::set_device(int hip_device, size_t stream_id)
{
  int n_devices = 0;
  hipDeviceProp_t device_properties;
  std::string device_name = "";

  try {
    hipCheck(hipGetDeviceCount(&n_devices));

    debug_cout << "There are " << n_devices << " hip devices available\n";
    for (int cd = 0; cd < n_devices; ++cd) {
      hipDeviceProp_t device_properties;
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

    device_name = std::string {device_properties.name} == "Device 738c" ? "MI100" : device_properties.name;

    if (n_devices == 0) {
      error_cout << "Failed to select device " << hip_device << "\n";
      return {false, "", 0};
    }
    else {
      debug_cout << "Stream " << stream_id << " selected hip device " << hip_device << ": " << device_name << "\n\n";
    }
  } catch (const std::invalid_argument& e) {
    error_cout << e.what() << std::endl;
    error_cout << "Stream " << stream_id << " failed to select hip device " << hip_device << "\n";
    return {false, "", 0};
  }

  return {true, device_name, device_properties.textureAlignment};
}

std::tuple<bool, int> Allen::get_device_id(const std::string& pci_bus_id)
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
