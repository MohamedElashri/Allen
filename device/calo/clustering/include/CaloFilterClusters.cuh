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
    HOST_INPUT(host_ecal_number_of_twoclusters_t, unsigned) host_ecal_number_of_twoclusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_num_prefiltered_clusters_t, unsigned) dev_num_prefiltered_clusters;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    DEVICE_INPUT(dev_prefiltered_clusters_idx_t, unsigned) dev_prefiltered_clusters_idx;

    DEVICE_OUTPUT(dev_cluster1_idx_t, unsigned) dev_cluster1_idx;
    DEVICE_OUTPUT(dev_cluster2_idx_t, unsigned) dev_cluster2_idx;

    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

  __global__ void calo_filter_clusters(Parameters);

  struct calo_filter_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_filter_t> m_block_dim_filter {this, {{64, 16, 1}}};
  };

} // namespace calo_filter_clusters
