/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

#pragma once

#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"

namespace calo_find_twoclusters {
  struct Parameters {

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_twoclusters_t, unsigned) host_number_of_twoclusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_cluster1_idx_t, unsigned) dev_cluster1_idx;
    DEVICE_INPUT(dev_cluster2_idx_t, unsigned) dev_cluster2_idx;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;

    DEVICE_OUTPUT(dev_ecal_twoclusters_t, TwoCaloCluster) dev_ecal_twoclusters;

    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  __global__ void calo_find_twoclusters(Parameters parameters);

  // Algorithm
  struct calo_find_twoclusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&)
      const;

    __host__ void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 128};
  };
} // namespace calo_find_twoclusters
