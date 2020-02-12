#pragma once

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_find_permutation {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_hit_permutations_t, uint) dev_ut_hit_permutations;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {16, 1, 1});
  };

  __global__ void ut_find_permutation(Parameters, const uint* dev_unique_x_sector_layer_offsets);

  template<typename T, char... S>
  struct ut_find_permutation_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(ut_find_permutation)) function {ut_find_permutation};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_hit_permutations_t>(arguments, value<host_accumulated_number_of_ut_hits_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(
        dim3(value<host_number_of_selected_events_t>(arguments), constants.host_unique_x_sector_layer_offsets[4]),
        property<block_dim_t>(),
        cuda_stream)(
        Parameters {begin<dev_ut_hits_t>(arguments),
                   begin<dev_ut_hit_offsets_t>(arguments),
                   begin<dev_ut_hit_permutations_t>(arguments)},
        constants.dev_unique_x_sector_layer_offsets.data());
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace ut_find_permutation