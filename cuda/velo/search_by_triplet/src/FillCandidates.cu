#include "FillCandidates.cuh"
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "VeloTools.cuh"
#include "BinarySearch.cuh"
#include <cassert>
#include <cstdio>
#include <tuple>

/**
 * @brief Fills candidates according to the phi window,
 *        with no restriction on the number of candidates.
 *        Returns a tuple<int, int>, with the structure:
 *
 *        * first candidate
 *        * size of window
 */
__device__ std::tuple<int, int> candidate_binary_search(
  const float* hit_Phis,
  const int module_hit_start,
  const int module_number_of_hits,
  const float h1_phi,
  const float phi_window) {
  // Do a binary search for the first candidate
  const auto first_candidate =
    binary_search_leftmost(hit_Phis + module_hit_start, module_number_of_hits, h1_phi - phi_window);

  if (
    first_candidate == module_number_of_hits ||
    fabsf(hit_Phis[module_hit_start + first_candidate] - h1_phi) > phi_window) {
    return {-1, 0};
  }
  else {
    // Find number of candidates with a second binary search
    const auto number_of_candidates = binary_search_leftmost(
      hit_Phis + module_hit_start + first_candidate, module_number_of_hits - first_candidate, h1_phi + phi_window);
    return {first_candidate, number_of_candidates};
  }
}

/**
 * @brief Finds candidates with a maximum number of candidates to the
 *        left and right wrt the h1 phi.
 */
__device__ std::tuple<int, int> candidate_capped_search(
  const float* hit_Phis,
  const int module_hit_start,
  const int module_number_of_hits,
  const float h1_phi,
  const float phi_window,
  const int maximum_candidates_side) {
  int first_candidate = -1;
  int number_of_candidates = 0;

  if (module_number_of_hits > 0) {
    // Do a binary search for h0 candidates
    const auto candidate_position = binary_search_leftmost(hit_Phis + module_hit_start, module_number_of_hits, h1_phi);

    if (
      candidate_position < module_number_of_hits &&
      hit_Phis[module_hit_start + candidate_position] > (h1_phi - phi_window) &&
      hit_Phis[module_hit_start + candidate_position] < (h1_phi + phi_window)) {

      first_candidate = candidate_position;
      number_of_candidates = 1;

      // Find a maximum of candidates to both sides
      for (int i = 0; i < maximum_candidates_side; ++i) {
        const auto current_left_candidate = candidate_position - i - 1;
        if (
          current_left_candidate >= 0 && hit_Phis[module_hit_start + current_left_candidate] > (h1_phi - phi_window)) {
          first_candidate = current_left_candidate;
          number_of_candidates++;
        }

        const auto current_right_candidate = candidate_position + i + 1;
        if (
          current_right_candidate < module_number_of_hits &&
          hit_Phis[module_hit_start + current_right_candidate] < (h1_phi + phi_window)) {
          number_of_candidates++;
        }
      }
    }
  }

  return {first_candidate, number_of_candidates};
}

/**
 * @brief Implementation of FillCandidates for a single module.
 */
__device__ void fill_candidates_impl(
  short* h0_candidates,
  short* h2_candidates,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  const Velo::Clusters<const uint32_t>& velo_cluster_container,
  const float* hit_Phis,
  const uint hit_offset)
{
  // Notation is m0, m1, m2 in reverse order for each module
  // A hit in those is h0, h1, h2 respectively

  // Assign a h1 to each threadIdx.x
  const auto module_index = blockIdx.y + 2; // 48 blocks y
  const auto m1_hitNums = module_hitNums[module_index];
  for (uint h1_rel_index = threadIdx.x; h1_rel_index < m1_hitNums; h1_rel_index += blockDim.x) {
    // Find for module module_index, hit h1_rel_index the candidates
    const auto m0_hitStarts = module_hitStarts[module_index + 2];
    const auto m2_hitStarts = module_hitStarts[module_index - 2];
    const auto m0_hitNums = module_hitNums[module_index + 2];
    const auto m2_hitNums = module_hitNums[module_index - 2];

    const auto h1_index = module_hitStarts[module_index] + h1_rel_index;

    // Calculate phi limits
    const auto h1_phi = hit_Phis[h1_index];
    const auto phi_window =
      Configuration::velo_search_by_triplet::phi_extrapolation_base +
      fabsf(velo_cluster_container.z(h1_index)) * Configuration::velo_search_by_triplet::phi_extrapolation_coef;

    const auto found_h0_candidates = candidate_binary_search(hit_Phis, m0_hitStarts, m0_hitNums, h1_phi, phi_window);

    h0_candidates[2 * h1_index] = std::get<0>(found_h0_candidates) + m0_hitStarts - hit_offset;
    h0_candidates[2 * h1_index + 1] = std::get<1>(found_h0_candidates);

    const auto found_h2_candidates = candidate_binary_search(hit_Phis, m2_hitStarts, m2_hitNums, h1_phi, phi_window);

    h2_candidates[2 * h1_index] = std::get<0>(found_h2_candidates) + m2_hitStarts - hit_offset;
    h2_candidates[2 * h1_index + 1] = std::get<1>(found_h2_candidates);
  }
}

/**
 * @brief Fills the first candidate and size for each hit in a middle module.
 * @details Considering hits in consecutive modules m0, m1 and m2, for every
 *          hit h1 in module m1, the following structure is created:
 *
 *          * h0 first candidate
 *          * h0 number of candidates
 *          * h2 first candidate
 *          * h2 number of candidates
 *
 *          These candidates will be then iterated in the seeding step of Sbt.
 */
__global__ void velo_fill_candidates::velo_fill_candidates(velo_fill_candidates::Parameters parameters) {
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_modules;
  const auto hit_offset = module_hitStarts[0];

  const auto velo_cluster_container =
    Velo::Clusters<const uint>{parameters.dev_sorted_velo_cluster_container.get(), total_estimated_number_of_clusters};

  fill_candidates_impl(
    parameters.dev_h0_candidates, parameters.dev_h2_candidates, module_hitStarts, module_hitNums, velo_cluster_container, parameters.dev_hit_phi, hit_offset);
}
