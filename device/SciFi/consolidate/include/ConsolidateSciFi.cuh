/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "ParticleTypes.cuh"
#include "CopyTrackParameters.cuh"

#ifndef ALLEN_STANDALONE
#include <Gaudi/Accumulators.h>
#include "GaudiMonitoring.h"
#endif

namespace scifi_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_scifi_tracks;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, unsigned) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_scifi_lf_parametrization_consolidate_t, float) dev_scifi_lf_parametrization_consolidate;
    DEVICE_OUTPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_OUTPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_OUTPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_OUTPUT(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    HOST_INPUT(host_scifi_hit_count_t, unsigned) host_scifi_hit_count;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_OUTPUT(dev_used_scifi_hits_t, unsigned) dev_used_scifi_hits;
    DEVICE_OUTPUT(dev_accepted_and_unused_velo_tracks_t, bool) dev_accepted_and_unused_velo_tracks;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_hits_view_t,
      DEPENDENCIES(dev_scifi_track_hits_t),
      Allen::Views::SciFi::Consolidated::Hits)
    dev_scifi_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_track_view_t,
      DEPENDENCIES(dev_scifi_hits_view_t, dev_tracks_view_t, dev_scifi_qop_t),
      Allen::Views::SciFi::Consolidated::Track)
    dev_scifi_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_tracks_view_t,
      DEPENDENCIES(dev_scifi_track_view_t),
      Allen::Views::SciFi::Consolidated::Tracks)
    dev_scifi_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_scifi_multi_event_tracks_view_t,
      DEPENDENCIES(dev_scifi_tracks_view_t),
      Allen::Views::SciFi::Consolidated::MultiEventTracks)
    dev_scifi_multi_event_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_view_t,
      DEPENDENCIES(dev_scifi_multi_event_tracks_view_t, dev_tracks_view_t),
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
      histogram_long_track_forward_eta_min_t,
      "histogram_long_track_forward_eta_min",
      "histogram_long_track_forward_eta_min description",
      float)
    histogram_long_track_forward_eta_min;
    PROPERTY(
      histogram_long_track_forward_eta_max_t,
      "histogram_long_track_forward_eta_max",
      "histogram_long_track_forward_eta_max description",
      float)
    histogram_long_track_forward_eta_max;
    PROPERTY(
      histogram_long_track_forward_eta_nbins_t,
      "histogram_long_track_forward_eta_nbins",
      "histogram_long_track_forward_eta_nbins description",
      unsigned int)
    histogram_long_track_forward_eta_nbins;

    PROPERTY(
      histogram_long_track_forward_phi_min_t,
      "histogram_long_track_forward_phi_min",
      "histogram_long_track_forward_phi_min description",
      float)
    histogram_long_track_forward_phi_min;
    PROPERTY(
      histogram_long_track_forward_phi_max_t,
      "histogram_long_track_forward_phi_max",
      "histogram_long_track_forward_phi_max description",
      float)
    histogram_long_track_forward_phi_max;
    PROPERTY(
      histogram_long_track_forward_phi_nbins_t,
      "histogram_long_track_forward_phi_nbins",
      "histogram_long_track_forward_phi_nbins description",
      unsigned int)
    histogram_long_track_forward_phi_nbins;

    PROPERTY(
      histogram_long_track_forward_nhits_min_t,
      "histogram_long_track_forward_nhits_min",
      "histogram_long_track_forward_nhits_min description",
      float)
    histogram_long_track_forward_nhits_min;
    PROPERTY(
      histogram_long_track_forward_nhits_max_t,
      "histogram_long_track_forward_nhits_max",
      "histogram_long_track_forward_nhits_max description",
      float)
    histogram_long_track_forward_nhits_max;
    PROPERTY(
      histogram_long_track_forward_nhits_nbins_t,
      "histogram_long_track_forward_nhits_nbins",
      "histogram_long_track_forward_nhits_nbins description",
      unsigned int)
    histogram_long_track_forward_nhits_nbins;
  };

  __global__ void scifi_consolidate_tracks(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity,
    gsl::span<unsigned>,
    gsl::span<unsigned>);

  struct scifi_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const scifi_consolidate_tracks::Parameters& parameters,
      const Allen::Views::Physics::LongTrack long_track,
      const Allen::Views::Physics::KalmanState velo_state,
      gsl::span<unsigned>,
      gsl::span<unsigned>,
      gsl::span<unsigned>);

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<histogram_long_track_forward_eta_min_t> m_histogramLongEtaMin {this, 0.f};
    Property<histogram_long_track_forward_eta_max_t> m_histogramLongEtaMax {this, 10.f};
    Property<histogram_long_track_forward_eta_nbins_t> m_histogramLongEtaNBins {this, 40u};
    Property<histogram_long_track_forward_phi_min_t> m_histogramLongPhiMin {this, -4.f};
    Property<histogram_long_track_forward_phi_max_t> m_histogramLongPhiMax {this, 4.f};
    Property<histogram_long_track_forward_phi_nbins_t> m_histogramLongPhiNBins {this, 16u};
    Property<histogram_long_track_forward_nhits_min_t> m_histogramLongNhitsMin {this, 0.f};
    Property<histogram_long_track_forward_nhits_max_t> m_histogramLongNhitsMax {this, 50.f};
    Property<histogram_long_track_forward_nhits_nbins_t> m_histogramLongNhitsNBins {this, 50u};

#ifndef ALLEN_STANDALONE
  private:
    Gaudi::Accumulators::Counter<>* m_long_tracks_forward;
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_long_tracks_forward;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_forward_eta;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_forward_phi;
    gaudi_monitoring::Lockable_Histogram<>* histogram_long_track_forward_nhits;
#endif
  };

} // namespace scifi_consolidate_tracks
