#include "CalculatePhiAndSort.cuh"

/**
 * @brief Track forwarding algorithm based on triplet finding
 */
__global__ void velo_calculate_phi_and_sort::velo_calculate_phi_and_sort(
  velo_calculate_phi_and_sort::Parameters parameters)
{
  __shared__ half_t shared_hit_phis[Velo::Constants::max_numhits_in_module];

  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_modules;

  const auto velo_cluster_container =
    Velo::ConstClusters {parameters.dev_velo_cluster_container, total_estimated_number_of_clusters};
  auto velo_sorted_cluster_container =
    Velo::Clusters {parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters};

  const uint event_hit_start = module_hitStarts[0];
  const uint event_number_of_hits = module_hitStarts[Velo::Constants::n_modules] - event_hit_start;

  // Calculate phi and populate hit_permutations
  calculate_phi(
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    parameters.dev_hit_phi,
    parameters.dev_hit_permutation,
    shared_hit_phis);

  // Due to phi RAW
  __syncthreads();

  // Sort by phi
  sort_by_phi(
    event_hit_start,
    event_number_of_hits,
    velo_cluster_container,
    velo_sorted_cluster_container,
    parameters.dev_hit_permutation);
}
