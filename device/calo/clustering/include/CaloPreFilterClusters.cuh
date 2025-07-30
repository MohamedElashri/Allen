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
    HOST_INPUT(host_ecal_number_of_neutral_clusters_t, unsigned) host_ecal_number_neutral_of_clusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_neutral_particles_t, Allen::Views::Physics::MultiEventNeutralBasicParticles) dev_neutral_particles;

    DEVICE_OUTPUT(dev_prefiltered_clusters_idx_t, unsigned) dev_prefiltered_clusters_idx;
    DEVICE_OUTPUT(dev_num_prefiltered_clusters_t, unsigned) dev_num_prefiltered_clusters;
    DEVICE_OUTPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  __global__ void calo_prefilter_clusters(Parameters, const float, const float);

  __global__ void count_twoclusters(Parameters);

  struct calo_prefilter_clusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_minEt_clusters {this, "minEt_clusters", 400.f, "minEt of each cluster"}; // MeV
    Allen::Property<float> m_minE19_clusters {this, "minE19_clusters", 0.6f, "min CaloNeutralE19 of each cluster"};
    Allen::Property<dim3> m_block_dim_prefilter {this,
                                                 "block_dim_prefilter",
                                                 {256, 1, 1},
                                                 "block dimensions for prefilter step"};
  };

} // namespace calo_prefilter_clusters
