#pragma once

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsUT.cuh"

__global__ void ut_find_permutation(
  uint32_t* dev_ut_hits,
  uint32_t* dev_ut_hit_offsets,
  uint* dev_hit_permutations,
  const uint* dev_unique_x_sector_layer_offsets);

struct ut_find_permutation_t : public DeviceAlgorithm {
  constexpr static auto name {"ut_find_permutation_t"};
  decltype(global_function(ut_find_permutation)) function {ut_find_permutation};
  using Arguments = std::tuple<dev_ut_hits, dev_ut_hit_offsets, dev_ut_hit_permutations>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
