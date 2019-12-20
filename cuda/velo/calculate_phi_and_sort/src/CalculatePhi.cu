#include "VeloDefinitions.cuh"
#include "CalculatePhiAndSort.cuh"
#include "CudaMathConstants.h"
#include "VeloTools.cuh"

using namespace velo_calculate_phi_and_sort;

/**
 * @brief Calculates a phi side
 */
template<class T>
__device__ void calculate_phi_side(
  float* shared_hit_phis,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  const Velo::Clusters<const uint32_t>& velo_cluster_container,
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
      const auto hit_phi = calculate_hit_phi(velo_cluster_container.x(hit_index), velo_cluster_container.y(hit_index));
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
  const Velo::Clusters<const uint32_t>& velo_cluster_container,
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
