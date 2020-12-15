/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_select_velo_tracks {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_beamline_states_t, char), dev_velo_beamline_states),
    (DEVICE_INPUT(dev_accepted_velo_tracks_t, bool), dev_accepted_velo_tracks),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_velo_track_hits_t, char), dev_velo_track_hits),
    (DEVICE_OUTPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned), dev_ut_number_of_selected_velo_tracks),
    (DEVICE_OUTPUT(dev_ut_selected_velo_tracks_t, unsigned), dev_ut_selected_velo_tracks),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __device__ bool velo_track_in_UTA_acceptance(const MiniState& state);

  __global__ void ut_select_velo_tracks(Parameters);

  struct ut_select_velo_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace ut_select_velo_tracks
