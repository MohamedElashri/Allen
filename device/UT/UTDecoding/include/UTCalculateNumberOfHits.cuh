#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_calculate_number_of_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_OUTPUT(dev_ut_hit_sizes_t, uint) dev_ut_hit_sizes;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void ut_calculate_number_of_hits(
    Parameters,
    const char* ut_boards,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  __global__ void ut_calculate_number_of_hits_mep(
    Parameters,
    const char* ut_boards,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets,
    const uint* dev_unique_x_sector_offsets);

  template<typename T>
  struct ut_calculate_number_of_hits_t : public DeviceAlgorithm, Parameters {


    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const HostBuffers&) const
    {
      set_size<dev_ut_hit_sizes_t>(
        arguments,
        first<host_number_of_selected_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4]);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_ut_hit_sizes_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {data<dev_event_list_t>(arguments),
                                          data<dev_ut_raw_input_t>(arguments),
                                          data<dev_ut_raw_input_offsets_t>(arguments),
                                          data<dev_ut_hit_sizes_t>(arguments)};

      using function_t = decltype(global_function(ut_calculate_number_of_hits));
      function_t function = runtime_options.mep_layout ? function_t{ut_calculate_number_of_hits_mep} : function_t{ut_calculate_number_of_hits};
      function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        parameters,
        constants.dev_ut_boards.data(),
        constants.dev_ut_region_offsets.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_x_sector_offsets.data());
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 4, 1}}};
  };
} // namespace ut_calculate_number_of_hits
