/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"

namespace calo_overlap_clusters {
  struct Parameters {
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_INPUT(dev_ecal_seed_clusters_t, CaloSeedCluster) dev_ecal_seed_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_ecal_digit_is_seed_t, unsigned) dev_ecal_digit_is_seed;
    DEVICE_OUTPUT(dev_ecal_corrections_t, float) dev_ecal_corrections;
  };

  // Global function
  __global__ void
  calo_overlap_clusters(Parameters parameters, const char* raw_ecal_geometry, const int16_t ecal_min_adc);

  // Algorithm
  struct calo_overlap_clusters_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 128, "block dimension X"};
    Allen::Property<int16_t> m_ecal_min_adc {this, "ecal_min_adc", 0, "ECal seed cluster minimum ADC"};
  };
} // namespace calo_overlap_clusters
