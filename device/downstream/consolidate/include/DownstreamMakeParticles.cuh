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

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include "Gaudi/Accumulators/Histogram.h"
#endif

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
    gsl::span<unsigned> dev_histogram_n_trks,
    gsl::span<unsigned> dev_histogram_trk_eta,
    gsl::span<unsigned> dev_histogram_trk_phi,
    gsl::span<unsigned> dev_histogram_trk_pt);

  struct downstream_make_particles_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
#ifndef ALLEN_STANDALONE
  private:
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_trks;
    gaudi_monitoring::Lockable_Histogram<>* histogram_trk_eta;
    gaudi_monitoring::Lockable_Histogram<>* histogram_trk_phi;
    gaudi_monitoring::Lockable_Histogram<>* histogram_trk_pt;
#endif
  };
} // namespace downstream_make_particles
