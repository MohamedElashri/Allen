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

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "VertexDefinitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"

namespace FilterMFTracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_selected_events_mf_t, unsigned) host_selected_events_mf;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack) dev_mf_tracks;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, unsigned) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_mf_track_offsets_t, unsigned) dev_mf_track_offsets;
    DEVICE_INPUT(dev_event_list_mf_t, unsigned) dev_event_list_mf;
    DEVICE_OUTPUT(dev_mf_sv_atomics_t, unsigned) dev_mf_sv_atomics;
    DEVICE_OUTPUT(dev_svs_kf_idx_t, unsigned) dev_svs_kf_idx;
    DEVICE_OUTPUT(dev_svs_mf_idx_t, unsigned) dev_svs_mf_idx;
  };

  __global__ void filter_mf_tracks(
    Parameters,
    const unsigned number_of_events,
    const float kf_track_min_pt,
    const float kf_track_min_ipchi2,
    const float mf_track_min_pt);

  struct filter_mf_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_kfminpt {this, "kf_track_min_pt", 800.f, "minimum track pT"};
    Allen::Property<float> m_kfminipchi2 {this, "kf_track_min_ipchi2", 16.f, "minimum track IP chi2"};
    Allen::Property<float> m_mfminpt {this, "mf_track_min_pt", 200.f, "minimum velo-UT-muon track pt"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 16, 1}, "block dimensions"};
  };

} // namespace FilterMFTracks
