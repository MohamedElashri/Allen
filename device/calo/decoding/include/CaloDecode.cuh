#pragma once

#include "CaloRawEvent.cuh"
#include "CaloRawBanks.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

namespace calo_decode {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_ecal_raw_input_t, char), dev_ecal_raw_input),
    (DEVICE_INPUT(dev_ecal_raw_input_offsets_t, unsigned), dev_ecal_raw_input_offsets),
    (DEVICE_INPUT(dev_hcal_raw_input_t, char), dev_hcal_raw_input),
    (DEVICE_INPUT(dev_hcal_raw_input_offsets_t, unsigned), dev_hcal_raw_input_offsets),
    (DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit), dev_ecal_digits),
    (DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit), dev_hcal_digits),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned), block_dim))

  // Global function
  __global__ void calo_decode(Parameters parameters, const char* dev_ecal_geometry, const char* dev_hcal_geometry);
  __global__ void calo_decode_mep(Parameters parameters, const char* dev_ecal_geometry, const char* dev_hcal_geometry);

  // Algorithm
  struct calo_decode_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace calo_decode
