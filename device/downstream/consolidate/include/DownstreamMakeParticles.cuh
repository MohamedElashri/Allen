/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

// Event Model
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

#include "AllenMonitoring.h"

/**
 * @brief This is definition file for downstream_make_particles algorithm.
 * implementation is in downstream_make_particles.cu
 */

namespace downstream_make_particles {
  struct Parameters {

    // Basics
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Downstream tracks
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    DEVICE_INPUT(dev_multi_event_downstream_tracks_view_t, Allen::Views::Physics::MultiEventDownstreamTracks)
    dev_multi_event_downstream_tracks_view;
    DEVICE_INPUT(dev_downstream_track_states_view_t, Allen::Views::Physics::KalmanStates)
    dev_downstream_track_states_view;

    // Outputs
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_particle_view_t,
      DEPENDENCIES(dev_multi_event_downstream_tracks_view_t, dev_downstream_track_states_view_t),
      Allen::Views::Physics::BasicParticle)
    dev_downstream_track_particle_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_particles_view_t,
      DEPENDENCIES(dev_downstream_track_particle_view_t),
      Allen::Views::Physics::BasicParticles)
    dev_downstream_track_particles_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_track_particles_view_t,
      DEPENDENCIES(dev_downstream_track_particles_view_t),
      Allen::Views::Physics::MultiEventBasicParticles)
    dev_multi_event_downstream_track_particles_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_track_particles_view_ptr_t,
      DEPENDENCIES(dev_multi_event_downstream_track_particles_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_downstream_track_particles_view_ptr;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void downstream_make_particles(
    Parameters,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_trks,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_eta,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_phi,
    Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_pt);

  struct downstream_make_particles_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};

    Allen::Monitoring::Histogram<> m_histogram_n_trks {
      this,
      "number_of_trks",
      "NTrks",
      {UT::Constants::max_num_tracks, 0, UT::Constants::max_num_tracks}};
    Allen::Monitoring::Histogram<> m_histogram_trk_eta {this, "trk_eta", "etaTrk", {400u, 0.f, 10.f}};
    Allen::Monitoring::Histogram<> m_histogram_trk_phi {this, "trk_phi", "phiTrk", {100u, -3.2f, 3.2f}};
    Allen::Monitoring::Histogram<> m_histogram_trk_pt {this, "trk_pt", "ptTrk", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_make_particles
