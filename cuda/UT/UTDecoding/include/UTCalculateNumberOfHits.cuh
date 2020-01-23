#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_calculate_number_of_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_OUTPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_OUTPUT(dev_ut_hit_sizes_t, uint) dev_ut_hit_sizes;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {64, 4, 1});
  };

  __global__ void ut_calculate_number_of_hits(
    Parameters,
    const char* ut_boards,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  template<typename T, char... S>
  struct ut_calculate_number_of_hits_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(ut_calculate_number_of_hits)) function {ut_calculate_number_of_hits};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_ut_raw_input_t>(arguments, std::get<0>(runtime_options.host_ut_events).size_bytes());
      set_size<dev_ut_raw_input_offsets_t>(arguments, std::get<1>(runtime_options.host_ut_events).size_bytes() / sizeof(uint));
      set_size<dev_ut_hit_sizes_t>(
        arguments,
        value<host_number_of_selected_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4]);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemcpyAsync(
        begin<dev_ut_raw_input_t>(arguments),
        std::get<0>(runtime_options.host_ut_events).begin(),
        std::get<0>(runtime_options.host_ut_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        begin<dev_ut_raw_input_offsets_t>(arguments),
        std::get<1>(runtime_options.host_ut_events).begin(),
        std::get<1>(runtime_options.host_ut_events).size_bytes(),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        begin<dev_ut_hit_sizes_t>(arguments), 0, size<dev_ut_hit_sizes_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_event_list_t>(arguments),
                   begin<dev_ut_raw_input_t>(arguments),
                   begin<dev_ut_raw_input_offsets_t>(arguments),
                   begin<dev_ut_hit_sizes_t>(arguments)},
        constants.dev_ut_boards.data(),
        constants.dev_ut_region_offsets.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_x_sector_offsets.data());
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace ut_calculate_number_of_hits