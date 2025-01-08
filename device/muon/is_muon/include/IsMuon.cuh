/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"
#include "ParticleTypes.cuh"
#include "AllenMonitoring.h"

namespace is_muon {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    // DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_OUTPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_OUTPUT(dev_muon_idxs_t, unsigned) dev_muon_idxs;
    DEVICE_OUTPUT(dev_lepton_id_t, uint8_t) dev_lepton_id;
    DEVICE_OUTPUT(dev_muon_hit_offsets_t, unsigned) dev_muon_hit_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  __global__ void is_muon(
    Parameters,
    const Muon::Constants::FieldOfInterest* dev_muon_foi,
    const float* dev_muon_momentum_cuts,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType);

  template<typename MultiEventTracks>
  __device__ void is_muon_implementation(
    Parameters parameters,
    const MultiEventTracks* dev_long_tracks_view,
    const Muon::Constants::FieldOfInterest* dev_muon_foi,
    const float* dev_muon_momentum_cuts,
    Allen::Monitoring::Histogram<>::DeviceType dev_histo_n_muons,
    Allen::Monitoring::Histogram<>::DeviceType dev_histo_muon_n_stations,
    Allen::Monitoring::Histogram<>::DeviceType dev_histo_muon_pt);

  struct is_muon_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 128, "block dimension X"};
    Allen::Monitoring::Histogram<> m_histogram_n_muons {this, "n_muons", "# muons", {2u, -0.5f, 1.5f}};
    Allen::Monitoring::Histogram<> m_histogram_muon_n_stations {this, "pv_x", "pv_x", {3u, 1.5f, 4.5f}};
    Allen::Monitoring::Histogram<> m_histogram_muon_pt {this, "pv_y", "pv_y", {1000u, 0.f, 1e4}};
  };
} // namespace is_muon
