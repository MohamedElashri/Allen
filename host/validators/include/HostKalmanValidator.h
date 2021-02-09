/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "HostAlgorithm.cuh"
#include "States.cuh"
#include "ParKalmanFilter.cuh"

namespace host_kalman_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_velo_kalman_states_t, char) dev_velo_kalman_states;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, unsigned) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  struct host_kalman_validator_t : public HostAlgorithm, Parameters {
    inline void set_arguments_size(
      ArgumentReferences<Parameters>,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&) const;

  private:
    Property<root_output_filename_t> m_root_output_filename {this, "PrCheckerPlots.root"};
  };
} // namespace host_kalman_validator
