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

namespace calo_prefilter_clusters {

  struct Parameters {

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_neutral_particles_t, Allen::Views::Physics::MultiEventNeutralBasicParticles) dev_neutral_particles;

    DEVICE_OUTPUT(dev_prefiltered_clusters_idx_t, unsigned) dev_prefiltered_clusters_idx;
    DEVICE_OUTPUT(dev_num_prefiltered_clusters_t, unsigned) dev_num_prefiltered_clusters;
    DEVICE_OUTPUT(dev_ecal_num_twoclusters_t, unsigned) dev_ecal_num_twoclusters;

    PROPERTY(minEt_clusters_t, "minEt_clusters", "minEt of each cluster", float) minEt_clusters;
    PROPERTY(minE19_clusters_t, "minE19_clusters", "min CaloNeutralE19 of each cluster", float) minE19_clusters;
    PROPERTY(block_dim_prefilter_t, "block_dim_prefilter", "block dimensions for prefilter step", DeviceDimensions)
    block_dim_prefilter;
  };

  __global__ void calo_prefilter_clusters(Parameters);

  __global__ void count_twoclusters(Parameters);

  struct calo_prefilter_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<minEt_clusters_t> m_minEt_clusters {this, 400.f}; // MeV
    Property<minE19_clusters_t> m_minE19_clusters {this, 0.6f};
    Property<block_dim_prefilter_t> m_block_dim_prefilter {this, {{256, 1, 1}}};
  };

} // namespace calo_prefilter_clusters
