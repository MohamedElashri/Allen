#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

#define ECAL_BANKS 28
#define HCAL_BANKS 8
// #define CARD_CHANNELS 32
#define ECAL_MAX_CELLID 0b11000000000000
#define HCAL_MAX_CELLID 0b10000000000000


namespace calo_find_local_maxima {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit), dev_ecal_digits),
    (DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit), dev_hcal_digits),
    (DEVICE_OUTPUT(dev_ecal_num_clusters_t, uint), dev_ecal_num_clusters),
    (DEVICE_OUTPUT(dev_hcal_num_clusters_t, uint), dev_hcal_num_clusters),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", uint), block_dim))

  // Global function
  __global__ void calo_find_local_maxima(Parameters parameters, const uint number_of_events,
    const char* raw_ecal_geometry, const char* raw_hcal_geometry);

  // Algorithm
  struct calo_find_local_maxima_t : public DeviceAlgorithm, Parameters {

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
} // namespace calo_find_local_maxima
