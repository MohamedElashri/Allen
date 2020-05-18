#pragma once

#include "VeloConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace saxpy {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint), dev_velo_track_hit_number),
    (DEVICE_OUTPUT(dev_saxpy_output_t, float), dev_saxpy_output),
    (PROPERTY(saxpy_scale_factor_t, "saxpy_scale_factor", "scale factor a used in a*x + y", float), saxpy_scale_factor),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void saxpy(Parameters);

  struct saxpy_t : public DeviceAlgorithm, Parameters {
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
    Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace saxpy
