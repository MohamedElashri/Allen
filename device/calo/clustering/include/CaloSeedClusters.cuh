#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "CaloCluster.cuh"
#include "DeviceAlgorithm.cuh"

namespace calo_seed_clusters {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_ecal_digits_t, CaloDigit), dev_ecal_digits),
    (DEVICE_INPUT(dev_hcal_digits_t, CaloDigit), dev_hcal_digits),
    (DEVICE_OUTPUT(dev_ecal_num_clusters_t, unsigned), dev_ecal_num_clusters),
    (DEVICE_OUTPUT(dev_hcal_num_clusters_t, unsigned), dev_hcal_num_clusters),
    (DEVICE_OUTPUT(dev_ecal_seed_clusters_t, CaloSeedCluster), dev_ecal_seed_clusters),
    (DEVICE_OUTPUT(dev_hcal_seed_clusters_t, CaloSeedCluster), dev_hcal_seed_clusters),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned), block_dim),
    (PROPERTY(ecal_min_adc_t, "ecal_min_adc", "ECal seed cluster minimum ADC", int16_t), ecal_min_adc),
    (PROPERTY(hcal_min_adc_t, "hcal_min_adc", "HCal seed cluster minimum ADC", int16_t), hcal_min_adc))

  // Global function
  __global__ void calo_seed_clusters(Parameters parameters,
                                     const char* raw_ecal_geometry, const char* raw_hcal_geometry,
                                     const int16_t ecal_min_adc, const int16_t hcal_min_adc);

  // Algorithm
  struct calo_seed_clusters_t : public DeviceAlgorithm, Parameters {

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
    Property<ecal_min_adc_t> m_ecal_min_adc {this, 20};
    Property<hcal_min_adc_t> m_hcal_min_adc {this, 20};
  };
} // namespace calo_seed_clusters
