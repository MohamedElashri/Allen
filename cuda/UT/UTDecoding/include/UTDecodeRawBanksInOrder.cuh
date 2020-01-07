#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

namespace ut_decode_raw_banks_in_order {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_hits_t, uint) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_permutations_t, uint) dev_ut_hit_permutations;
  };

  __global__ void ut_decode_raw_banks_in_order(
    Arguments,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets);

  template<typename T>
  struct ut_decode_raw_banks_in_order_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"ut_decode_raw_banks_in_order_t"};
    decltype(global_function(ut_decode_raw_banks_in_order)) function {ut_decode_raw_banks_in_order};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {}

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function.invoke(
        dim3(value<host_number_of_selected_events_t>(manager), UT::Constants::n_layers),
        block_dimension(),
        cuda_stream)(
        Arguments {offset<dev_ut_raw_input_t>(manager),
                   offset<dev_ut_raw_input_offsets_t>(manager),
                   offset<dev_event_list_t>(manager),
                   offset<dev_ut_hit_offsets_t>(manager),
                   offset<dev_ut_hits_t>(manager),
                   offset<dev_ut_hit_permutations_t>(manager)},
        constants.dev_ut_boards.data(),
        constants.dev_ut_geometry.data(),
        constants.dev_ut_region_offsets.data(),
        constants.dev_unique_x_sector_layer_offsets.data());
    }
  };
} // namespace ut_decode_raw_banks_in_order