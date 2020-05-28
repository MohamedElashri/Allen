#pragma once

#include "CaloRawEvent.cuh"
#include "CaloRawBanks.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

#define CARD_CHANNELS 32
#define ECAL_MAX_CELLID 0b11000000000000
#define HCAL_MAX_CELLID 0b10000000000000
// Max distance based on CellIDs is 64 steps away, so the iteration in which a cell is clustered can never be more than 64.
#define UNCLUSTERED 65


namespace calo_decode {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_OUTPUT(dev_ecal_raw_input_t, char), dev_ecal_raw_input),
    (DEVICE_OUTPUT(dev_ecal_raw_input_offsets_t, uint), dev_ecal_raw_input_offsets),
    (DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit), dev_ecal_digits),
    (DEVICE_OUTPUT(dev_hcal_raw_input_t, char), dev_hcal_raw_input),
    (DEVICE_OUTPUT(dev_hcal_raw_input_offsets_t, uint), dev_hcal_raw_input_offsets),
    (DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit), dev_hcal_digits),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", uint), block_dim))

  // Global function
  __global__ void calo_decode(Parameters parameters, const uint number_of_events,
                                  const char* dev_ecal_geometry, const char* dev_hcal_geometry);
  __global__ void calo_decode_mep(Parameters parameters, const uint number_of_events,
                                      const char* dev_ecal_geometry, const char* dev_hcal_geometry);

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
} // namespace calo_get_digits
