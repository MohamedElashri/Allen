#pragma once

#include "VeloConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace saxpy {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);

    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;

    DEVICE_OUTPUT(dev_saxpy_output_t, float) dev_saxpy_output;

    PROPERTY(saxpy_scale_factor_t, float, "saxpy_scale_factor", "scale factor a used in a*x + y") saxpy_scale_factor;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

__global__ void saxpy(Parameters);


  template<typename T, char... S>
  struct saxpy_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(saxpy)) function {saxpy};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_saxpy_output_t>(
                                   arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments) / property<block_dim_t>().get().x), property<block_dim_t>(), cuda_stream)(
                                                                                                              Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                   begin<dev_offsets_velo_track_hit_number_t>(arguments),
                   begin<dev_saxpy_output_t>(arguments),                                                                  property<saxpy_scale_factor_t>()});
    }

    private:
      Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
      Property<block_dim_t> m_block_dim {this, {32, 1, 1}};
  };
} // namespace saxpy
