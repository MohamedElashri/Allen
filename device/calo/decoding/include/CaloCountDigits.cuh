#pragma once

#include "CaloGeometry.cuh"
#include "DeviceAlgorithm.cuh"

namespace calo_count_digits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_ecal_num_digits_t, unsigned) dev_ecal_num_digits;
    DEVICE_OUTPUT(dev_hcal_num_digits_t, unsigned) dev_hcal_num_digits;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  __global__ void calo_count_digits(Parameters parameters, const char* dev_ecal_geometry, const char* dev_hcal_geometry);

  // Algorithm
  struct calo_count_digits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      Allen::Context const&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace calo_count_digits
