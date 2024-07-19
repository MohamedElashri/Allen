/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"

namespace calo_seed_clusters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_of_digits;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_OUTPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
    DEVICE_OUTPUT(dev_ecal_seed_clusters_t, CaloSeedCluster) dev_ecal_seed_clusters;
    DEVICE_OUTPUT(dev_ecal_digit_is_seed_t, unsigned) dev_ecal_digit_is_seed;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
    PROPERTY(ecal_min_adc_t, "ecal_min_adc", "ECal seed cluster minimum ADC", int16_t) ecal_min_adc;
  };

  // Global function
  __global__ void calo_seed_clusters(Parameters parameters, const char* raw_ecal_geometry, const int16_t ecal_min_adc);

  // Algorithm
  struct calo_seed_clusters_t : public DeviceAlgorithm, Parameters {

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
    Property<block_dim_x_t> m_block_dim_x {this, 128};
    Property<ecal_min_adc_t> m_ecal_min_adc {this, 50};
  };
} // namespace calo_seed_clusters
