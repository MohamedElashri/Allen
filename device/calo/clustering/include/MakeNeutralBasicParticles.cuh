/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "ParticleTypes.cuh"
#include "CaloCluster.cuh"
#include "AlgorithmTypes.cuh"

namespace make_neutral_basic_particles {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_neutral_clusters_t, unsigned) host_number_of_neutral_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_INPUT(dev_ecal_neutral_cluster_offsets_t, unsigned) dev_ecal_neutral_cluster_offsets;
    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_neutral_basic_particle_view_t,
      DEPENDENCIES(dev_ecal_clusters_t),
      Allen::Views::Physics::NeutralBasicParticle)
    dev_neutral_basic_particle_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_neutral_basic_particles_view_t,
      DEPENDENCIES(dev_neutral_basic_particle_view_t),
      Allen::Views::Physics::NeutralBasicParticles)
    dev_neutral_basic_particles_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_neutral_particles_view_t,
      DEPENDENCIES(dev_neutral_basic_particles_view_t),
      Allen::Views::Physics::MultiEventNeutralBasicParticles)
    dev_multi_event_neutral_particles_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_container_neutral_particles_t,
      DEPENDENCIES(dev_multi_event_neutral_particles_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_container_neutral_particles;
  };

  __global__ void make_particles(Parameters parameters);

  struct make_neutral_particles_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };

} // namespace make_neutral_basic_particles