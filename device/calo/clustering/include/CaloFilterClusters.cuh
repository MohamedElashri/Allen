/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "AllenMonitoring.h"

namespace calo_filter_clusters {

  struct Parameters {

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_twoclusters_t, unsigned) host_ecal_number_of_twoclusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_neutral_particles_t, Allen::Views::Physics::MultiEventNeutralBasicParticles) dev_neutral_particles;
    DEVICE_INPUT(dev_num_prefiltered_clusters_t, unsigned) dev_num_prefiltered_clusters;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    DEVICE_INPUT(dev_prefiltered_clusters_idx_t, unsigned) dev_prefiltered_clusters_idx;

    // The ECAL cluster offsets are only needed for monitoring.
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;

    DEVICE_OUTPUT(dev_cluster1_idx_t, unsigned) dev_cluster1_idx;
    DEVICE_OUTPUT(dev_cluster2_idx_t, unsigned) dev_cluster2_idx;
  };

  __global__ void calo_filter_clusters(Parameters, Allen::Monitoring::AveragingCounter<>::DeviceType);

  struct calo_filter_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim_filter {this,
                                              "block_dim_filter",
                                              {64, 16, 1},
                                              "block dimensions for filter step"};
    Allen::Monitoring::AveragingCounter<> m_calo_clusters {this, "n_calo_clusters"};
  };

} // namespace calo_filter_clusters
