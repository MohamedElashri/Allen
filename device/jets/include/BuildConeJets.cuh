/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "JetDefinitions.cuh"
#include "CaloCluster.cuh"

namespace build_cone_jets {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_tracks_t, unsigned) host_number_of_tracks;
    HOST_INPUT(host_number_of_neutrals_t, unsigned) host_number_of_neutrals;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_long_track_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_long_track_particle_container;
    DEVICE_INPUT(dev_neutral_particle_container_t, Allen::Views::Physics::MultiEventNeutralBasicParticles)
    dev_neutral_particle_container;

    // Total sum holder for the prefix sum.
    HOST_OUTPUT(host_number_of_jets_t, unsigned) host_number_of_jets;

    DEVICE_OUTPUT(dev_jet_data_t, Jets::Jet) dev_jet_data;
    // Encode the jet kinematics in CALO clusters, which can be used to make
    // persistable neutral particles.
    DEVICE_OUTPUT(dev_jet_clusters_t, CaloCluster) dev_jet_clusters;
    // Output the number of jets so this can be used to construct the neutral
    // particle views, event though for now this is always just the maximum
    // number of jets. This way we can use the prefix sum machinery to make sure
    // everything is done correctly.
    // DEVICE_OUTPUT(dev_n_jets_t, unsigned) dev_n_jets;
    DEVICE_OUTPUT(dev_jet_offsets_t, unsigned) dev_jet_offsets;

    DEVICE_OUTPUT(dev_track_masks_t, int) dev_track_masks;
    DEVICE_OUTPUT(dev_neutral_masks_t, int) dev_neutral_masks;
  };

  __global__ void
  build_jets(Parameters parameters, const unsigned n_max_jets, const float cone_radius, unsigned* host_number_of_jets);

  struct build_cone_jets_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension X"};
    Allen::Property<unsigned> m_n_max_jets {this, "n_max_jets", 8, "Maximum number of jets"};
    Allen::Property<float> m_cone_radius {this, "cone_radius", 0.5, "Radius of jet cone"};
  };

} // namespace build_cone_jets