/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// Associate Velo tracks to PVs using their impact parameter and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"

namespace velo_pv_ip {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char), dev_velo_kalman_beamline_states),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex), dev_multi_fit_vertices),
    (DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, unsigned), dev_number_of_multi_fit_vertices),
    (DEVICE_OUTPUT(dev_velo_pv_ip_t, char), dev_velo_pv_ip),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void velo_pv_ip(Parameters);

  struct velo_pv_ip_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_pv_ip