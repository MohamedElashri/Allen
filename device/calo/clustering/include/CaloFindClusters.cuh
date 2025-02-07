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
#include <cfloat>
#include "AllenMonitoring.h"

namespace calo_find_clusters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_INPUT(dev_ecal_seed_clusters_t, CaloSeedCluster) dev_ecal_seed_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_ecal_digits_isTrackMatched_t, bool) dev_ecal_digits_isTrackMatched;
    DEVICE_INPUT(dev_ecal_digits_isBremMatched_t, bool) dev_ecal_digits_isBremMatched;
    DEVICE_INPUT(dev_ecal_corrections_t, float) dev_ecal_corrections;
    DEVICE_OUTPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_OUTPUT(dev_ecal_neutral_cluster_offsets_t, unsigned) dev_ecal_neutral_cluster_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  // Global function
  __global__ void calo_find_clusters(
    Parameters parameters,
    const char* raw_ecal_geometry,
    const int16_t min_adc,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType);

  // Algorithm
  struct calo_find_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    __host__ void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension X"};
    Allen::Property<int16_t> m_ecal_min_adc {this, "ecal_min_adc", 10, "cluster neighbors' minimum ADC"};

    Allen::Monitoring::Histogram<> m_histogram_n_clusters {this, "n_ecal_clusters", "NClusters", {401u, -0.5f, 400.5f}};
    Allen::Monitoring::Histogram<> m_histogram_ecal_digit_e {this, "ecal_digit_e", "EcalDigitE", {1000u, 0.f, 10000.f}};
    Allen::Monitoring::Histogram<> m_histogram_ecal_cluster_e {this,
                                                               "ecal_cluster_e",
                                                               "EcalClusterE",
                                                               {5000u, 0.f, 50000.f}};
    Allen::Monitoring::Histogram<> m_histogram_ecal_cluster_et {this,
                                                                "ecal_cluster_et",
                                                                "EcalClusterEt",
                                                                {500u, 0.f, 5000.f}};
    Allen::Monitoring::Histogram<> m_histogram_ecal_cluster_x {this,
                                                               "ecal_cluster_x",
                                                               "EcalClusterX",
                                                               {800u, -4000.f, 4000.f}};
    Allen::Monitoring::Histogram<> m_histogram_ecal_cluster_y {this,
                                                               "ecal_cluster_y",
                                                               "EcalClusterY",
                                                               {800u, -4000.f, 4000.f}};
  };
} // namespace calo_find_clusters
