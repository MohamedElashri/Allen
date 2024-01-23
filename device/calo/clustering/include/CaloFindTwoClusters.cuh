/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

#pragma once

#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace calo_find_twoclusters {
  struct Parameters {

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_twoclusters_t, unsigned) host_number_of_twoclusters;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;

    DEVICE_INPUT(dev_neutral_particles_t, Allen::Views::Physics::MultiEventNeutralBasicParticles) dev_neutral_particles;
    DEVICE_INPUT(dev_cluster1_idx_t, unsigned) dev_cluster1_idx;
    DEVICE_INPUT(dev_cluster2_idx_t, unsigned) dev_cluster2_idx;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_child_pointers_t,
      DEPENDENCIES(dev_neutral_particles_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_child_pointers;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_twocluster_view_t,
      DEPENDENCIES(dev_child_pointers_t),
      Allen::Views::Physics::CompositeParticle)
    dev_twocluster_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_twoclusters_view_t,
      DEPENDENCIES(dev_twocluster_view_t),
      Allen::Views::Physics::CompositeParticles)
    dev_twoclusters_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_twoclusters_view_t,
      DEPENDENCIES(dev_twoclusters_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_twoclusters_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_twoclusters_ptr_t,
      DEPENDENCIES(dev_multi_event_twoclusters_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles*)
    dev_multi_event_twoclusters_ptr;

    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  __global__ void calo_find_twoclusters(Parameters parameters);

  // Algorithm
  struct calo_find_twoclusters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    __host__ void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 128};
  };
} // namespace calo_find_twoclusters
