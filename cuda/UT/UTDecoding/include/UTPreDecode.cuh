#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

namespace ut_pre_decode {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_OUTPUT(dev_ut_hit_count_t, uint) dev_ut_hit_count;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {64, 4, 1});
  };

  __global__ void ut_pre_decode(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  __global__ void ut_pre_decode_mep(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  template<typename T, char... S>
  struct ut_pre_decode_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(ut_pre_decode)) function {ut_pre_decode};
    decltype(global_function(ut_pre_decode_mep)) function_mep {ut_pre_decode_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_hits_t>(
        arguments,
        UT::hits_number_of_arrays * value<host_accumulated_number_of_ut_hits_t>(arguments) * sizeof(uint32_t));
      set_size<dev_ut_hit_count_t>(
        arguments,
        value<host_number_of_selected_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4]);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      initialize<dev_ut_hit_count_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {begin<dev_ut_raw_input_t>(arguments),
                                          begin<dev_ut_raw_input_offsets_t>(arguments),
                                          begin<dev_event_list_t>(arguments),
                                          begin<dev_ut_hit_offsets_t>(arguments),
                                          begin<dev_ut_hits_t>(arguments),
                                          begin<dev_ut_hit_count_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters,
          constants.dev_ut_boards.data(),
          constants.dev_ut_geometry.data(),
          constants.dev_ut_region_offsets.data(),
          constants.dev_unique_x_sector_layer_offsets.data(),
          constants.dev_unique_x_sector_offsets.data());
      }
      else {
        function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
          parameters,
          constants.dev_ut_boards.data(),
          constants.dev_ut_geometry.data(),
          constants.dev_ut_region_offsets.data(),
          constants.dev_unique_x_sector_layer_offsets.data(),
          constants.dev_unique_x_sector_offsets.data());
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace ut_pre_decode
