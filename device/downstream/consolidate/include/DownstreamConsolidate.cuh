/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
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
#include "States.cuh"
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "VeloConsolidated.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamCache.cuh"
#include "DownstreamCreateTracks.cuh"

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include "Gaudi/Accumulators/Histogram.h"
#endif

/**
 * @brief This is difinition file for downstream consolidation algorithm
 * This algorithm is responsible for consolidating downstream tracks from the downstream hits
 * implementation file is downstream_consolidate.cu
 */

namespace downstream_consolidate {
  struct Parameters {
    // Basic input
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Host statistics
    HOST_INPUT(host_number_of_hits_in_downstream_tracks_t, unsigned) host_number_of_hits_in_downstream_tracks;
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;

    // Downstream input
    DEVICE_INPUT(dev_downstream_track_hit_number_t, unsigned) dev_downstream_track_hit_number;
    DEVICE_INPUT(dev_offsets_downstream_hit_numbers_t, unsigned) dev_offsets_downstream_hit_numbers;
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    DEVICE_INPUT(dev_downstream_tracks_t, char) dev_downstream_tracks;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Scifi input
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;

    // Output
    DEVICE_OUTPUT(dev_downstream_track_states_t, char) dev_downstream_track_states;
    DEVICE_OUTPUT(dev_downstream_track_hits_t, char) dev_downstream_track_hits;
    DEVICE_OUTPUT(dev_downstream_track_qops_t, float) dev_downstream_track_qops;
    DEVICE_OUTPUT(dev_downstream_track_scifi_idx_t, unsigned) dev_downstream_track_scifi_idx;

    //
    // Views outputs : UT tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_hits_view_t,
      DEPENDENCIES(dev_scifi_tracks_view_t, dev_downstream_tracks_t, dev_downstream_track_hits_t),
      Allen::Views::UT::Consolidated::Hits)
    dev_downstream_hits_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_ut_track_view_t,
      DEPENDENCIES(dev_downstream_hits_view_t, dev_downstream_tracks_t, dev_downstream_track_hits_t),
      Allen::Views::UT::Consolidated::Track)
    dev_downstream_ut_track_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_ut_tracks_view_t,
      DEPENDENCIES(dev_downstream_ut_track_view_t),
      Allen::Views::UT::Consolidated::Tracks)
    dev_downstream_ut_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_ut_tracks_view_t,
      DEPENDENCIES(dev_downstream_ut_tracks_view_t),
      Allen::Views::UT::Consolidated::MultiEventTracks)
    dev_multi_event_downstream_ut_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_ut_tracks_view_ptr_t,
      DEPENDENCIES(dev_multi_event_downstream_ut_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_downstream_ut_tracks_view_ptr;

    //
    // Views outputs : states
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_states_view_t,
      DEPENDENCIES(dev_scifi_tracks_view_t, dev_downstream_tracks_t, dev_downstream_track_states_t),
      Allen::Views::Physics::KalmanStates)
    dev_downstream_track_states_view;

    //
    // Views outputs : Downstream tracks
    //
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_track_view_t,
      DEPENDENCIES(dev_offsets_downstream_tracks_t, dev_downstream_ut_tracks_view_t, dev_downstream_track_qops_t),
      Allen::Views::Physics::DownstreamTrack)
    dev_downstream_track_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_downstream_tracks_view_t,
      DEPENDENCIES(dev_downstream_track_view_t),
      Allen::Views::Physics::DownstreamTracks)
    dev_downstream_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_tracks_view_t,
      DEPENDENCIES(dev_downstream_tracks_view_t),
      Allen::Views::Physics::MultiEventDownstreamTracks)
    dev_multi_event_downstream_tracks_view;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_downstream_tracks_view_ptr_t,
      DEPENDENCIES(dev_multi_event_downstream_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_downstream_tracks_view_ptr;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;

    //
    // Monitoring
    //
    PROPERTY(
      histogram_downstream_track_eta_min_t,
      "histogram_downstream_track_eta_min",
      "histogram_downstream_track_eta_min description",
      float)
    histogram_downstream_track_eta_min;
    PROPERTY(
      histogram_downstream_track_eta_max_t,
      "histogram_downstream_track_eta_max",
      "histogram_downstream_track_eta_max description",
      float)
    histogram_downstream_track_eta_max;
    PROPERTY(
      histogram_downstream_track_eta_nbins_t,
      "histogram_downstream_track_eta_nbins",
      "histogram_downstream_track_eta_nbins description",
      unsigned int)
    histogram_downstream_track_eta_nbins;

    PROPERTY(
      histogram_downstream_track_phi_min_t,
      "histogram_downstream_track_phi_min",
      "histogram_downstream_track_phi_min description",
      float)
    histogram_downstream_track_phi_min;
    PROPERTY(
      histogram_downstream_track_phi_max_t,
      "histogram_downstream_track_phi_max",
      "histogram_downstream_track_phi_max description",
      float)
    histogram_downstream_track_phi_max;
    PROPERTY(
      histogram_downstream_track_phi_nbins_t,
      "histogram_downstream_track_phi_nbins",
      "histogram_downstream_track_phi_nbins description",
      unsigned int)
    histogram_downstream_track_phi_nbins;

    PROPERTY(
      histogram_downstream_track_nhits_min_t,
      "histogram_downstream_track_nhits_min",
      "histogram_downstream_track_nhits_min description",
      float)
    histogram_downstream_track_nhits_min;
    PROPERTY(
      histogram_downstream_track_nhits_max_t,
      "histogram_downstream_track_nhits_max",
      "histogram_downstream_track_nhits_max description",
      float)
    histogram_downstream_track_nhits_max;
    PROPERTY(
      histogram_downstream_track_nhits_nbins_t,
      "histogram_downstream_track_nhits_nbins",
      "histogram_downstream_track_nhits_nbins description",
      unsigned int)
    histogram_downstream_track_nhits_nbins;
  };

  __global__ void downstream_consolidate(
    Parameters,
    const unsigned* dev_unique_x_sector_layer_offsets,
    gsl::span<unsigned>,
    gsl::span<unsigned>);
  __global__ void
  downstream_create_tracks_view(Parameters, gsl::span<unsigned>, gsl::span<unsigned>, gsl::span<unsigned>);

  struct lhcb_id_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct downstream_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const downstream_consolidate::Parameters& parameters,
      const Allen::Views::Physics::DownstreamTrack downstream_track,
      const Allen::Views::Physics::KalmanState downstream_state,
      gsl::span<unsigned>,
      gsl::span<unsigned>,
      gsl::span<unsigned>);

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};

    //
    // Monitoring
    //
    Property<histogram_downstream_track_eta_min_t> m_histogramDownstreamEtaMin {this, 0.f};
    Property<histogram_downstream_track_eta_max_t> m_histogramDownstreamEtaMax {this, 10.f};
    Property<histogram_downstream_track_eta_nbins_t> m_histogramDownstreamEtaNBins {this, 40u};
    Property<histogram_downstream_track_phi_min_t> m_histogramDownstreamPhiMin {this, -4.f};
    Property<histogram_downstream_track_phi_max_t> m_histogramDownstreamPhiMax {this, 4.f};
    Property<histogram_downstream_track_phi_nbins_t> m_histogramDownstreamPhiNBins {this, 16u};
    Property<histogram_downstream_track_nhits_min_t> m_histogramDownstreamNhitsMin {this, 0.f};
    Property<histogram_downstream_track_nhits_max_t> m_histogramDownstreamNhitsMax {this, 50.f};
    Property<histogram_downstream_track_nhits_nbins_t> m_histogramDownstreamNhitsNBins {this, 50u};

#ifndef ALLEN_STANDALONE
  private:
    Gaudi::Accumulators::Counter<>* m_downstream_tracks;
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_downstream_tracks;
    gaudi_monitoring::Lockable_Histogram<>* histogram_downstream_track_eta;
    gaudi_monitoring::Lockable_Histogram<>* histogram_downstream_track_phi;
    gaudi_monitoring::Lockable_Histogram<>* histogram_downstream_track_nhits;
#endif
  };
} // namespace downstream_consolidate