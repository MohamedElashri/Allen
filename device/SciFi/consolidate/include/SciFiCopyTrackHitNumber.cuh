/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"

namespace scifi_copy_track_hit_number {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_scifi_tracks_t, SciFi::TrackHits), dev_scifi_tracks),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned), dev_atomics_scifi),
    (DEVICE_OUTPUT(dev_scifi_track_hit_number_t, unsigned), dev_scifi_track_hit_number),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void scifi_copy_track_hit_number(Parameters);

  struct scifi_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
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
    Property<block_dim_t> m_block_dim {this, {{512, 1, 1}}};
  };
} // namespace scifi_copy_track_hit_number