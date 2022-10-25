/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"

namespace calo_filter_clusters {

  struct Parameters {

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;

    DEVICE_OUTPUT(dev_cluster_atomics_t, unsigned) dev_cluster_atomics;
    DEVICE_OUTPUT(dev_cluster1_idx_t, unsigned) dev_cluster1_idx;
    DEVICE_OUTPUT(dev_cluster2_idx_t, unsigned) dev_cluster2_idx;
    DEVICE_OUTPUT(dev_cluster_prefilter_result_t, bool) dev_cluster_prefilter_result;

    PROPERTY(minEt_clusters_t, "minEt_clusters", "minEt of each cluster", float) minEt_clusters;
    PROPERTY(minE19_clusters_t, "minE19_clusters", "min CaloNeutralE19 of each cluster", float) minE19_clusters;
    PROPERTY(block_dim_prefilter_t, "block_dim_prefilter", "block dimensions for prefilter step", DeviceDimensions)
    block_dim_prefilter;
    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

  __global__ void prefilter_clusters(Parameters);

  __global__ void filter_clusters(Parameters);

  struct calo_filter_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<minEt_clusters_t> m_minEt_clusters {this, 500.f}; // MeV
    Property<minE19_clusters_t> m_minE19_clusters {this, 0.6f};
    Property<block_dim_prefilter_t> m_block_dim_prefilter {this, {{256, 1, 1}}};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{64, 16, 1}}};
  };

} // namespace calo_filter_clusters
