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

#include "ParKalmanDefinitions.cuh"
#include "ParticleTypes.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"

namespace make_long_track_particles {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_lepton_id_t, uint8_t) dev_lepton_id;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_kalman_states_view_t, Allen::Views::Physics::KalmanStates) dev_kalman_states_view;
    DEVICE_INPUT(dev_kalman_pv_tables_t, Allen::Views::Physics::PVTable) dev_kalman_pv_tables;
    DEVICE_INPUT(dev_multi_event_long_tracks_t, Allen::IMultiEventContainer) dev_multi_event_long_tracks;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_particle_view_t,
      DEPENDENCIES(
        dev_multi_event_long_tracks_t,
        dev_kalman_states_view_t,
        dev_multi_final_vertices_t,
        dev_kalman_pv_tables_t,
        dev_lepton_id_t),
      Allen::Views::Physics::BasicParticle)
    dev_long_track_particle_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_particles_view_t,
      DEPENDENCIES(dev_long_track_particle_view_t),
      Allen::Views::Physics::BasicParticles)
    dev_long_track_particles_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_basic_particles_view_t,
      DEPENDENCIES(dev_long_track_particles_view_t),
      Allen::Views::Physics::MultiEventBasicParticles)
    dev_multi_event_basic_particles_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_basic_particles_ptr_t,
      DEPENDENCIES(dev_multi_event_basic_particles_view_t),
      Allen::Views::Physics::MultiEventBasicParticles*)
    dev_multi_event_basic_particles_ptr;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_particles(Parameters parameters);

  struct make_long_track_particles_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };

} // namespace make_long_track_particles