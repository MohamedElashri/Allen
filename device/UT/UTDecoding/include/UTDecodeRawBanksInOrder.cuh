#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

namespace ut_decode_raw_banks_in_order {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, uint) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_ut_pre_decoded_hits_t, char) dev_ut_pre_decoded_hits;
    DEVICE_OUTPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_permutations_t, uint) dev_ut_hit_permutations;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void ut_decode_raw_banks_in_order(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets);

  __global__ void ut_decode_raw_banks_in_order_mep(
    Parameters,
    const char* ut_boards,
    const char* ut_geometry,
    const uint* dev_ut_region_offsets,
    const uint* dev_unique_x_sector_layer_offsets);

  template<typename T>
  struct ut_decode_raw_banks_in_order_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(ut_decode_raw_banks_in_order)) function {ut_decode_raw_banks_in_order};
    decltype(global_function(ut_decode_raw_banks_in_order_mep)) function_mep {ut_decode_raw_banks_in_order_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_hits_t>(
        arguments,
        first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::Hits::element_size);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto parameters = Parameters {data<dev_ut_raw_input_t>(arguments),
                                          data<dev_ut_raw_input_offsets_t>(arguments),
                                          data<dev_event_list_t>(arguments),
                                          data<dev_ut_hit_offsets_t>(arguments),
                                          data<dev_ut_pre_decoded_hits_t>(arguments),
                                          data<dev_ut_hits_t>(arguments),
                                          data<dev_ut_hit_permutations_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(
          dim3(first<host_number_of_selected_events_t>(arguments), UT::Constants::n_layers),
          property<block_dim_t>(),
          cuda_stream)(
          parameters,
          constants.dev_ut_boards.data(),
          constants.dev_ut_geometry.data(),
          constants.dev_ut_region_offsets.data(),
          constants.dev_unique_x_sector_layer_offsets.data());
      }
      else {
        function(
          dim3(first<host_number_of_selected_events_t>(arguments), UT::Constants::n_layers),
          property<block_dim_t>(),
          cuda_stream)(
          parameters,
          constants.dev_ut_boards.data(),
          constants.dev_ut_geometry.data(),
          constants.dev_ut_region_offsets.data(),
          constants.dev_unique_x_sector_layer_offsets.data());
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };
} // namespace ut_decode_raw_banks_in_order
