/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "States.cuh"
#include "ParticleTypes.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"
#include "CopyTrackParameters.cuh"

#ifndef ALLEN_STANDALONE
#include <Gaudi/Accumulators.h>
#include "GaudiMonitoring.h"
#endif

namespace matching_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_matched_tracks_t, unsigned) host_number_of_reconstructed_matched_tracks;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_matched_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_matched_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_matched_tracks_t, unsigned) dev_atomics_matched;
    DEVICE_INPUT(dev_offsets_matched_hit_number_t, unsigned) dev_matched_track_hit_number; // fishy
    DEVICE_INPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_OUTPUT(dev_matched_track_hits_t, char) dev_matched_track_hits;
    DEVICE_OUTPUT(dev_matched_qop_t, float) dev_matched_qop;
    DEVICE_OUTPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_OUTPUT(dev_matched_track_velo_indices_t, unsigned) dev_matched_track_velo_indices;
    DEVICE_OUTPUT(dev_matched_track_scifi_indices_t, unsigned) dev_matched_track_scifi_indices;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_OUTPUT(dev_accepted_and_unused_velo_tracks_t, bool) dev_accepted_and_unused_velo_tracks;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_view_t,
      DEPENDENCIES(
        dev_scifi_tracks_view_t,
        dev_velo_tracks_view_t,
        dev_matched_qop_t,
        dev_matched_track_velo_indices_t,
        dev_matched_track_scifi_indices_t),
      Allen::Views::Physics::LongTrack)
    dev_long_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_tracks_view_t,
      DEPENDENCIES(dev_long_track_view_t),
      Allen::Views::Physics::LongTracks)
    dev_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_view_t,
      DEPENDENCIES(dev_long_tracks_view_t),
      Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_ptr_t,
      DEPENDENCIES(dev_multi_event_long_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_long_tracks_ptr;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;

    PROPERTY(
      histogram_long_track_matching_eta_min_t,
      "histogram_long_track_matching_eta_min",
      "histogram_long_track_matching_eta_min description",
      float)
    histogram_long_track_matching_eta_min;
    PROPERTY(
      histogram_long_track_matching_eta_max_t,
      "histogram_long_track_matching_eta_max",
      "histogram_long_track_matching_eta_max description",
      float)
    histogram_long_track_matching_eta_max;
    PROPERTY(
      histogram_long_track_matching_eta_nbins_t,
      "histogram_long_track_matching_eta_nbins",
      "histogram_long_track_matching_eta_nbins description",
      unsigned int)
    histogram_long_track_matching_eta_nbins;

    PROPERTY(
      histogram_long_track_matching_phi_min_t,
      "histogram_long_track_matching_phi_min",
      "histogram_long_track_matching_phi_min description",
      float)
    histogram_long_track_matching_phi_min;
    PROPERTY(
      histogram_long_track_matching_phi_max_t,
      "histogram_long_track_matching_phi_max",
      "histogram_long_track_matching_phi_max description",
      float)
    histogram_long_track_matching_phi_max;
    PROPERTY(
      histogram_long_track_matching_phi_nbins_t,
      "histogram_long_track_matching_phi_nbins",
      "histogram_long_track_matching_phi_nbins description",
      unsigned int)
    histogram_long_track_matching_phi_nbins;

    PROPERTY(
      histogram_long_track_matching_nhits_min_t,
      "histogram_long_track_matching_nhits_min",
      "histogram_long_track_matching_nhits_min description",
      float)
    histogram_long_track_matching_nhits_min;
    PROPERTY(
      histogram_long_track_matching_nhits_max_t,
      "histogram_long_track_matching_nhits_max",
      "histogram_long_track_matching_nhits_max description",
      float)
    histogram_long_track_matching_nhits_max;
    PROPERTY(
      histogram_long_track_matching_nhits_nbins_t,
      "histogram_long_track_matching_nhits_nbins",
      "histogram_long_track_matching_nhits_nbins description",
      unsigned int)
    histogram_long_track_matching_nhits_nbins;
  };

  __global__ void matching_consolidate_tracks(
    Parameters,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>);

  struct matching_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const matching_consolidate_tracks::Parameters& parameters,
      const SciFi::MatchedTrack matched_track,
      const Allen::Views::Velo::Consolidated::Track velo_track,
      const Allen::Views::Physics::KalmanState velo_state,
      gsl::span<unsigned>,
      gsl::span<unsigned>,
      gsl::span<unsigned>);

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<histogram_long_track_matching_eta_min_t> m_histogramLongEtaMin {this, 0.f};
    Property<histogram_long_track_matching_eta_max_t> m_histogramLongEtaMax {this, 10.f};
    Property<histogram_long_track_matching_eta_nbins_t> m_histogramLongEtaNBins {this, 40u};
    Property<histogram_long_track_matching_phi_min_t> m_histogramLongPhiMin {this, -4.f};
    Property<histogram_long_track_matching_phi_max_t> m_histogramLongPhiMax {this, 4.f};
    Property<histogram_long_track_matching_phi_nbins_t> m_histogramLongPhiNBins {this, 16u};
    Property<histogram_long_track_matching_nhits_min_t> m_histogramLongNhitsMin {this, 0.f};
    Property<histogram_long_track_matching_nhits_max_t> m_histogramLongNhitsMax {this, 50.f};
    Property<histogram_long_track_matching_nhits_nbins_t> m_histogramLongNhitsNBins {this, 50u};

#ifndef ALLEN_STANDALONE
  private:
    Gaudi::Accumulators::Counter<>* m_long_tracks_matching;
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_long_tracks_matching;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_matching_eta;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_matching_phi;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_matching_nhits;
#endif
  };
} // namespace matching_consolidate_tracks
