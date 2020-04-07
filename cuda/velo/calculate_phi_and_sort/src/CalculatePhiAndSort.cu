#include "VeloDefinitions.cuh"
#include "CalculatePhiAndSort.cuh"
#include "CudaMathConstants.h"
#include "VeloTools.cuh"

/**
 * @brief Track forwarding algorithm based on triplet finding
 */
__global__ void velo_calculate_phi_and_sort::velo_calculate_phi_and_sort(
  velo_calculate_phi_and_sort::Parameters parameters)
{
  __shared__ int16_t shared_hit_phis[Velo::Constants::max_numhits_in_module];

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
    shared_hit_phis,
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    parameters.dev_hit_phi,
    parameters.dev_hit_permutation);

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

/**
 * @brief Calculates a phi side
 */
__device__ void velo_calculate_phi_and_sort::calculate_phi(
  int16_t* shared_hit_phis,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  Velo::ConstClusters& velo_cluster_container,
  int16_t* hit_Phis,
  uint* hit_permutations)
{
  for (uint module = 0; module < Velo::Constants::n_modules; ++module) {
    const auto hit_start = module_hitStarts[module];
    const auto hit_num = module_hitNums[module];

    assert(hit_num < Velo::Constants::max_numhits_in_module);

    // Calculate phis
    for (uint hit_rel_id = threadIdx.x; hit_rel_id < hit_num; hit_rel_id += blockDim.x) {
      const auto hit_index = hit_start + hit_rel_id;
      const auto hit_phi_int = hit_phi_16(velo_cluster_container.x(hit_index), velo_cluster_container.y(hit_index), module % 2);
      shared_hit_phis[hit_rel_id] = hit_phi_int;
    }

    // shared_hit_phis
    __syncthreads();

    // Find the permutations given the phis in shared_hit_phis
    for (uint hit_rel_id = threadIdx.x; hit_rel_id < hit_num; hit_rel_id += blockDim.x) {
      const auto hit_index = hit_start + hit_rel_id;
      const auto phi = shared_hit_phis[hit_rel_id];

      // Find out local position
      uint position = 0;
      for (uint j = 0; j < hit_num; ++j) {
        const auto other_phi = shared_hit_phis[j];
        // Stable sorting
        position += phi > other_phi || (phi == other_phi && hit_rel_id > j);
      }
      assert(position < Velo::Constants::max_numhits_in_module);

      // Store it in hit permutations and in hit_Phis, already ordered
      const auto global_position = hit_start + position;
      hit_permutations[global_position] = hit_index;
      hit_Phis[global_position] = phi;
    }

    // shared_hit_phis
    __syncthreads();
  }
}

/**
 * @brief Sorts all VELO decoded data by phi onto another container.
 */
__device__ void velo_calculate_phi_and_sort::sort_by_phi(
  const uint event_hit_start,
  const uint event_number_of_hits,
  Velo::ConstClusters& velo_cluster_container,
  Velo::Clusters& velo_sorted_cluster_container,
  uint* hit_permutations)
{
  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_x(event_hit_start + i, velo_cluster_container.x(hit_index_global));
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_y(event_hit_start + i, velo_cluster_container.y(hit_index_global));
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_z(event_hit_start + i, velo_cluster_container.z(hit_index_global));
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_id(event_hit_start + i, velo_cluster_container.id(hit_index_global));
  }
}