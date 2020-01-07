#pragma once

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_find_permutation {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, uint) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_hit_permutations_t, uint) dev_ut_hit_permutations;
  };

  __global__ void ut_find_permutation(Arguments, const uint* dev_unique_x_sector_layer_offsets);

  template<typename T>
  struct ut_find_permutation_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"ut_find_permutation_t"};
    decltype(global_function(ut_find_permutation)) function {ut_find_permutation};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_hit_permutations_t>(manager, value<host_accumulated_number_of_ut_hits_t>(manager));
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function.invoke(
        dim3(value<host_number_of_selected_events_t>(manager), constants.host_unique_x_sector_layer_offsets[4]),
        block_dimension(),
        cuda_stream)(
        Arguments {offset<dev_ut_hits_t>(manager),
                   offset<dev_ut_hit_offsets_t>(manager),
                   offset<dev_ut_hit_permutations_t>(manager)},
        constants.dev_unique_x_sector_layer_offsets.data());
    }
  };
} // namespace ut_find_permutation