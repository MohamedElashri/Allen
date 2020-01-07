#pragma once

#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsUT.cuh"
#include "UTEventModel.cuh"

__global__ void ut_decode_raw_banks_in_order(
  const char* dev_ut_raw_input,
  const uint32_t* dev_ut_raw_input_offsets,
  const uint* dev_event_list,
  const char* ut_boards,
  const char* ut_geometry,
  const uint* dev_ut_region_offsets,
  const uint* dev_unique_x_sector_layer_offsets,
  const uint32_t* dev_ut_hit_offsets,
  uint32_t* dev_ut_hits,
  uint* dev_hit_permutations);

struct ut_decode_raw_banks_in_order_t : public DeviceAlgorithm {
  constexpr static auto name {"ut_decode_raw_banks_in_order_t"};
  decltype(global_function(ut_decode_raw_banks_in_order)) function {ut_decode_raw_banks_in_order};
  using Arguments = std::tuple<
    dev_ut_raw_input,
    dev_ut_raw_input_offsets,
    dev_ut_hits,
    dev_ut_hit_offsets,
    dev_ut_hit_permutations,
    dev_event_list>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const {}

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
