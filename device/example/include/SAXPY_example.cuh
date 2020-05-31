/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace saxpy {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_OUTPUT(dev_saxpy_output_t, float), dev_saxpy_output),
    (PROPERTY(saxpy_scale_factor_t, "saxpy_scale_factor", "scale factor a used in a*x + y", float), saxpy_scale_factor),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  struct saxpy_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters>,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t&,
      cudaEvent_t&) const;

  private:
    Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

  __global__ void saxpy(Parameters, const unsigned number_of_events);
} // namespace saxpy
