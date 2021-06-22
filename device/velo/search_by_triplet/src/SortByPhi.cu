/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VeloDefinitions.cuh"
#include "SortByPhi.cuh"
#include "VeloTools.cuh"
#include "Vector.h"
#include <numeric>
#include <algorithm>

using namespace Allen::device;

void velo_sort_by_phi::velo_sort_by_phi_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_sorted_velo_cluster_container_t>(arguments, size<dev_velo_cluster_container_t>(arguments));
  set_size<dev_hit_permutation_t>(arguments, first<host_total_number_of_velo_clusters_t>(arguments));
}

void velo_sort_by_phi::velo_sort_by_phi_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_hit_permutation_t>(arguments, 0, context);

  global_function(velo_sort_by_phi)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "VELO clusters after velo_sort_by_phi:\n";
    print_velo_clusters<
      dev_sorted_velo_cluster_container_t,
      dev_offsets_estimated_input_size_t,
      dev_module_cluster_num_t,
      host_total_number_of_velo_clusters_t,
      host_number_of_events_t>(arguments);
  }
}

/**
 * @brief Track forwarding algorithm based on triplet finding
 */
__global__ void velo_sort_by_phi::velo_sort_by_phi(
  velo_sort_by_phi::Parameters parameters)
{
  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Pointers to data within the event
  const unsigned total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_module_pairs * number_of_events];
  const unsigned* module_pair_hit_start =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const unsigned* module_pair_hit_num =
    parameters.dev_module_cluster_num + event_number * Velo::Constants::n_module_pairs;

  const auto velo_cluster_container = parameters.dev_velo_clusters[event_number];
  auto velo_sorted_cluster_container =
    Velo::Clusters {parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters};

  const unsigned event_hit_start = module_pair_hit_start[0];
  const unsigned event_number_of_hits = module_pair_hit_start[Velo::Constants::n_module_pairs] - event_hit_start;

  // Calculate hit_permutations
  calculate_permutation(module_pair_hit_start, module_pair_hit_num, velo_cluster_container, parameters.dev_hit_permutation);

  // Due to hit_permutations RAW
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
__device__ void velo_sort_by_phi::calculate_permutation(
  const unsigned* module_pair_hit_start,
  const unsigned* module_pair_hit_num,
  const Velo::Clusters& velo_cluster_container,
  unsigned* hit_permutations)
{
  for (unsigned module_pair = threadIdx.x; module_pair < Velo::Constants::n_module_pairs; module_pair += blockDim.x) {
    const auto hit_start = module_pair_hit_start[module_pair];
    const auto hit_num = module_pair_hit_num[module_pair];

    // Synchronize to increase chances of coalesced accesses
    __syncthreads();

    // Find the permutations with phi
    for (unsigned hit_rel_id = threadIdx.y; hit_rel_id < hit_num; hit_rel_id += blockDim.y) {
      const auto hit_index = hit_start + hit_rel_id;
      const auto phi = velo_cluster_container.phi(hit_index);

      // Find out local position
      unsigned position = 0;
      for (unsigned j = 0; j < hit_num; ++j) {
        const auto other_hit_index = hit_start + j;
        const auto other_phi = velo_cluster_container.phi(other_hit_index);

        // Ensure sorting is reproducible
        position +=
          phi > other_phi || (hit_index != other_hit_index && phi == other_phi &&
                              velo_cluster_container.id(hit_index) > velo_cluster_container.id(other_hit_index));
      }

      // Store it in hit permutations
      const auto global_position = hit_start + position;
      hit_permutations[global_position] = hit_index;
    }
  }
}

/**
 * @brief Sorts all VELO decoded data by phi onto another container.
 */
__device__ void velo_sort_by_phi::sort_by_phi(
  const unsigned event_hit_start,
  const unsigned event_number_of_hits,
  const Velo::Clusters& velo_cluster_container,
  Velo::Clusters& velo_sorted_cluster_container,
  unsigned* hit_permutations)
{
  for (unsigned i = threadIdx.x * blockDim.y + threadIdx.y; i < event_number_of_hits; i += blockDim.y * blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_id(event_hit_start + i, velo_cluster_container.id(hit_index_global));
  }

  for (unsigned i = threadIdx.x * blockDim.y + threadIdx.y; i < event_number_of_hits; i += blockDim.y * blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_phi(event_hit_start + i, velo_cluster_container.phi(hit_index_global));
  }

  for (unsigned i = threadIdx.x * blockDim.y + threadIdx.y; i < event_number_of_hits; i += blockDim.y * blockDim.x) {
    const auto hit_index_global = hit_permutations[event_hit_start + i];
    velo_sorted_cluster_container.set_x(event_hit_start + i, velo_cluster_container.x(hit_index_global));
    velo_sorted_cluster_container.set_y(event_hit_start + i, velo_cluster_container.y(hit_index_global));
    velo_sorted_cluster_container.set_z(event_hit_start + i, velo_cluster_container.z(hit_index_global));
  }
}
