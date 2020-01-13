#include "VeloDefinitions.cuh"
#include "CalculatePhiAndSort.cuh"

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
    velo_sorted_cluster_container.x(event_hit_start + i) = velo_cluster_container.x(hit_index_global);
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.y(event_hit_start + i) = velo_cluster_container.y(hit_index_global);
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.z(event_hit_start + i) = velo_cluster_container.z(hit_index_global);
  }

  for (uint i = threadIdx.x; i < event_number_of_hits; i += blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.id(event_hit_start + i) = velo_cluster_container.id(hit_index_global);
  }
}
