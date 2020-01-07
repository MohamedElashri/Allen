#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

namespace ut_pre_decode {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_ut_hits, uint);
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_hits_t, uint) dev_ut_hits;
    DEVICE_OUTPUT(dev_ut_hit_count_t, uint) dev_ut_hit_count;
  };

  __global__ void ut_pre_decode(
    Arguments,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  template<typename T>
  struct ut_pre_decode_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"ut_pre_decode_t"};
    decltype(global_function(ut_pre_decode)) function {ut_pre_decode};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_hits_t>(manager, UT::Hits::number_of_arrays * value<host_accumulated_number_of_ut_hits>(manager));
      set_size<dev_ut_hit_count_t>(
        manager, value<host_number_of_selected_events_t>(manager) * constants.host_unique_x_sector_layer_offsets[4]);
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(
        cudaMemsetAsync(offset<dev_ut_hit_count_t>(manager), 0, size<dev_ut_hit_count_t>(manager), cuda_stream));

      function.invoke(dim3(value<host_number_of_selected_events_t>(manager)), block_dimension(), cuda_stream)(
        Arguments {offset<dev_ut_raw_input_t>(manager),
                   offset<dev_ut_raw_input_offsets_t>(manager),
                   offset<dev_event_list_t>(manager),
                   offset<dev_ut_hit_offsets_t>(manager),
                   offset<dev_ut_hits_t>(manager),
                   offset<dev_ut_hit_count_t>(manager)},

        constants.dev_ut_boards.data(),
        constants.dev_ut_geometry.data(),
        constants.dev_ut_region_offsets.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_x_sector_offsets.data());
    }
  };
} // namespace ut_pre_decode