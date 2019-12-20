#include "CalculatePhiAndSort.cuh"

using namespace velo_calculate_phi_and_sort;

/**
 * @brief Track forwarding algorithm based on triplet finding
 */
__global__ void velo_calculate_phi_and_sort::velo_calculate_phi_and_sort(
  dev_offsets_estimated_input_size_t dev_offsets_estimated_input_size,
  dev_module_cluster_num_t dev_module_cluster_num,
  dev_velo_cluster_container_t dev_velo_cluster_container,
  dev_sorted_velo_cluster_container_t dev_sorted_velo_cluster_container,
  dev_hit_permutation_t dev_hit_permutations,
  dev_hit_phi_t dev_hit_phi) {
  __shared__ float shared_hit_phis[Velo::Constants::max_numhits_in_module];

  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = dev_module_cluster_num + event_number * Velo::Constants::n_modules;

  const auto velo_cluster_container = Velo::Clusters<const uint>{dev_velo_cluster_container.get(), total_estimated_number_of_clusters};
  auto velo_sorted_cluster_container = Velo::Clusters<uint>{dev_sorted_velo_cluster_container.get(), total_estimated_number_of_clusters};

  const uint event_hit_start = module_hitStarts[0];
  const uint event_number_of_hits = module_hitStarts[Velo::Constants::n_modules] - event_hit_start;

  // Calculate phi and populate hit_permutations
  calculate_phi(
    module_hitStarts, module_hitNums, velo_cluster_container, dev_hit_phi, dev_hit_permutations, shared_hit_phis);

  // Due to phi RAW
  __syncthreads();

  // Sort by phi
  sort_by_phi(
    event_hit_start, event_number_of_hits, velo_cluster_container, velo_sorted_cluster_container, dev_hit_permutations);
}
