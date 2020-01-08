#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_calculate_number_of_hits {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_OUTPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_OUTPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
  };

  __global__ void ut_calculate_number_of_hits(
    Arguments,
    const char* ut_boards,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  template<typename T>
  struct ut_calculate_number_of_hits_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"ut_calculate_number_of_hits_t"};
    decltype(global_function(ut_calculate_number_of_hits)) function {ut_calculate_number_of_hits};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_ut_raw_input_t>(arguments, std::get<0>(runtime_options.host_ut_events).size_bytes());
      set_size<dev_ut_raw_input_offsets_t>(arguments, std::get<1>(runtime_options.host_ut_events).size_bytes());
      set_size<dev_ut_hit_offsets_t>(
        arguments,
        value<host_number_of_selected_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4] + 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemcpyAsync(
        offset<dev_ut_raw_input_t>(arguments),
        std::get<0>(runtime_options.host_ut_events).begin(),
        std::get<0>(runtime_options.host_ut_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        offset<dev_ut_raw_input_offsets_t>(arguments),
        std::get<1>(runtime_options.host_ut_events).begin(),
        std::get<1>(runtime_options.host_ut_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<dev_ut_hit_offsets_t>(arguments), 0, size<dev_ut_hit_offsets_t>(arguments), cuda_stream));

      function.invoke(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Arguments {offset<dev_event_list_t>(arguments),
                   offset<dev_ut_raw_input_t>(arguments),
                   offset<dev_ut_raw_input_offsets_t>(arguments),
                   offset<dev_ut_hit_offsets_t>(arguments)},
        constants.dev_ut_boards.data(),
        constants.dev_ut_region_offsets.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_x_sector_offsets.data());
    }
  };
} // namespace ut_calculate_number_of_hits