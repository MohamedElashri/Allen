/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "ParticleTypes.cuh"
#include "AlgorithmTypes.cuh"

namespace make_hits_container {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT_OPTIONAL(host_number_of_reconstructed_scifi_tracks_t, unsigned)
    host_number_of_reconstructed_scifi_tracks;
    HOST_INPUT(host_hits_container_size_t, unsigned) host_hits_container_size;
    DEVICE_INPUT_OPTIONAL(dev_hits_offsets_t, unsigned) dev_hits_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT_OPTIONAL(dev_long_track_particles_t, Allen::Views::Physics::BasicParticles) dev_long_track_particles;
    DEVICE_OUTPUT(dev_hits_container_t, unsigned) dev_hits_container;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_container(Parameters);

  struct make_hits_container_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{512, 1, 1}}};
  };

} // namespace make_hits_container