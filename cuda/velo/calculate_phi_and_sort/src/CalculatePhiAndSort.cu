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
  __shared__ float shared_hit_phis[Velo::Constants::max_numhits_in_module];

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

template<typename L, typename R>
__device__ void apply_permutation(
  const uint event_hit_start,
  const uint event_number_of_hits,
  Velo::ConstClusters& velo_cluster_container,
  Velo::Clusters& velo_sorted_cluster_container,
  uint* hit_permutations,
  const L& lvalue_accessor,
  const R& const_accessor) {
  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    lvalue_accessor(velo_sorted_cluster_container, event_hit_start + i) = const_accessor(velo_cluster_container, hit_index_global);
  }
}

/**
 * @brief Calculates phi for each hit
 */
__device__ void velo_calculate_phi_and_sort::sort_by_phi(
  const uint event_hit_start,
  const uint event_number_of_hits,
  Velo::ConstClusters& velo_cluster_container,
  Velo::Clusters& velo_sorted_cluster_container,
  uint* hit_permutations)
{
  // Apply permutation across all arrays
  // TODO: How to do this?
  // apply_permutation(event_hit_start, event_number_of_hits, velo_cluster_container, velo_sorted_cluster_container, hit_permutations,
  //   [] (auto container, const uint index) -> uint& { return container.x(index); },
  //   [] (auto container, const uint index) { return container.x(index); });

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

/**
 * @brief Calculates a phi side
 */
template<class T>
__device__ void calculate_phi_side(
  float* shared_hit_phis,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  Velo::ConstClusters& velo_cluster_container,
  float* hit_Phis,
  uint* hit_permutations,
  const uint starting_module,
  T calculate_hit_phi)
{
  for (uint module = starting_module; module < Velo::Constants::n_modules; module += 2) {
    const auto hit_start = module_hitStarts[module];
    const auto hit_num = module_hitNums[module];

    assert(hit_num < Velo::Constants::max_numhits_in_module);

    // Calculate phis
    for (uint hit_rel_id = threadIdx.x; hit_rel_id < hit_num; hit_rel_id += blockDim.x) {
      const auto hit_index = hit_start + hit_rel_id;
      const float hit_phi {calculate_hit_phi(velo_cluster_container.x(hit_index), velo_cluster_container.y(hit_index))};
      shared_hit_phis[hit_rel_id] = hit_phi;
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
 * @brief Calculates phi for each hit
 */
__device__ void velo_calculate_phi_and_sort::calculate_phi(
  const uint* module_hitStarts,
  const uint* module_hitNums,
  Velo::ConstClusters& velo_cluster_container,
  float* hit_Phis,
  uint* hit_permutations,
  float* shared_hit_phis)
{
  // Odd modules
  calculate_phi_side(
    shared_hit_phis,
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    hit_Phis,
    hit_permutations,
    1,
    [](const float x, const float y) { return hit_phi_odd(x, y); });

  // Even modules
  calculate_phi_side(
    shared_hit_phis,
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    hit_Phis,
    hit_permutations,
    0,
    [](const float x, const float y) { return hit_phi_even(x, y); });
}
