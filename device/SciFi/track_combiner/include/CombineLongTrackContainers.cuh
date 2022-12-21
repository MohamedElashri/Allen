/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace combine_long_track_containers {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_0_t, unsigned) host_number_of_reconstructed_scifi_tracks_0;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_1_t, unsigned) host_number_of_reconstructed_scifi_tracks_1;
    HOST_OUTPUT(host_number_of_reconstructed_scifi_tracks_output_t, unsigned)
    host_number_of_reconstructed_scifi_tracks_output;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_long_track_view_0_t, Allen::Views::Physics::LongTrack) dev_long_track_view_0;
    DEVICE_INPUT(dev_offset_tracks_0_t, unsigned) dev_offset_tracks_0;
    DEVICE_INPUT(dev_scifi_states_0_t, MiniState) dev_scifi_states_0;
    DEVICE_INPUT(dev_long_track_view_1_t, Allen::Views::Physics::LongTrack) dev_long_track_view_1;
    DEVICE_INPUT(dev_offset_tracks_1_t, unsigned) dev_offset_tracks_1;
    DEVICE_INPUT(dev_scifi_states_1_t, MiniState) dev_scifi_states_1;
    DEVICE_OUTPUT(dev_offset_tracks_output_t, unsigned) dev_offset_tracks_output;
    DEVICE_OUTPUT(dev_scifi_states_output_t, MiniState) dev_scifi_states_output;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_track_view_output_t,
      DEPENDENCIES(dev_long_track_view_0_t, dev_long_track_view_1_t),
      Allen::Views::Physics::LongTrack)
    dev_long_track_view_output;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_long_tracks_view_output_t,
      DEPENDENCIES(dev_long_track_view_output_t, dev_offset_tracks_output_t),
      Allen::Views::Physics::LongTracks)
    dev_long_tracks_view_output;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_view_output_t,
      DEPENDENCIES(dev_long_tracks_view_output_t),
      Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_long_tracks_view_output;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_long_tracks_ptr_output_t,
      DEPENDENCIES(dev_multi_event_long_tracks_view_output_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_long_tracks_ptr_output;
  };

  struct combine_long_track_containers_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };
} // namespace combine_long_track_containers
