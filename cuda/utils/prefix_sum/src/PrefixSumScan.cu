#include "PrefixSum.cuh"
#include "PrefixSumHandler.cuh"
#include "Invoke.cuh"

void prefix_sum_velo_clusters_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void prefix_sum_velo_track_hit_number_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void prefix_sum_ut_track_hit_number_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void prefix_sum_ut_hits_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void prefix_sum_scifi_track_hit_number_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void prefix_sum_scifi_hits_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void lf_prefix_sum_first_layer_window_size_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void lf_prefix_sum_candidates_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void muon_pre_decoding_prefix_sum_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}

void muon_station_ocurrence_prefix_sum_t::invoke() {
  invoke_helper(handler_reduce);
  invoke_helper(handler_single_block);
  invoke_helper(handler_scan);
}


__global__ void prefix_sum_scan(uint* dev_main_array, uint* dev_auxiliary_array, const uint array_size)
{
  // Note: The first block is already correctly populated.
  //       Start on the second block.
  const uint element = (blockIdx.x + 1) * blockDim.x + threadIdx.x;

  if (element < array_size) {
    const uint cluster_offset = dev_auxiliary_array[blockIdx.x + 1];
    dev_main_array[element] += cluster_offset;
  }
}
