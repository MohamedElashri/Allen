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

#include "AllenMonitoring.h"

namespace make_long_track_particles {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_lepton_id_t, uint8_t) dev_lepton_id;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_kalman_states_view_t, Allen::Views::Physics::KalmanStates) dev_kalman_states_view;
    DEVICE_INPUT(dev_kalman_pv_tables_t, Allen::Views::Physics::PVTable) dev_kalman_pv_tables;
    DEVICE_INPUT(dev_multi_event_long_tracks_t, Allen::IMultiEventContainer*) dev_multi_event_long_tracks;
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
      dev_multi_event_container_basic_particles_t,
      DEPENDENCIES(dev_multi_event_basic_particles_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_container_basic_particles;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_particles(
    Parameters parameters,
    unsigned event_list_size,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_trks,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_eta,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_phi,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_pt);

  struct make_long_track_particles_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};

    Allen::Monitoring::Histogram<> m_histogram_n_trks {
      this,
      "number_of_trks",
      "NTrks",
      {UT::Constants::max_num_tracks + 1, -0.5f, UT::Constants::max_num_tracks + 0.5}};
    Allen::Monitoring::Histogram<> m_histogram_trk_eta {this, "trk_eta", "etaTrk", {400u, 0.f, 10.f}};
    Allen::Monitoring::Histogram<> m_histogram_trk_phi {this, "trk_phi", "phiTrk", {1000u, -3.2f, 3.2f}};
    Allen::Monitoring::Histogram<> m_histogram_trk_pt {this, "trk_pt", "ptTrk", {1000u, 0.f, 1e4f}};
  };

} // namespace make_long_track_particles
