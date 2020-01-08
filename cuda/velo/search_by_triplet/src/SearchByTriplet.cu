#include "SearchByTriplet.cuh"
#include "ClusteringDefinitions.cuh"

__constant__ float Configuration::velo_search_by_triplet::forward_phi_tolerance;
__constant__ float Configuration::velo_search_by_triplet::max_chi2;
__constant__ float Configuration::velo_search_by_triplet::max_scatter_forwarding;
__constant__ float Configuration::velo_search_by_triplet::max_scatter_seeding;
__constant__ uint Configuration::velo_search_by_triplet::max_skipped_modules;
__constant__ uint Configuration::velo_search_by_triplet::max_weak_tracks;
__constant__ float Configuration::velo_search_by_triplet::phi_extrapolation_base;
__constant__ float Configuration::velo_search_by_triplet::phi_extrapolation_coef;
__constant__ uint Configuration::velo_search_by_triplet::ttf_modulo;
__constant__ int Configuration::velo_search_by_triplet::ttf_modulo_mask;

/**
 * @brief Track forwarding algorithm based on triplet finding
 * @detail For details, check out paper
 *         "A fast local algorithm for track reconstruction on parallel architectures"
 *
 *         Note: All hit arrays are contained in the dev_velo_cluster_container.
 *               By having a single array and offsetting it every time, less registers are
 *               required.
 *
 *               Hereby all the pointers and how to access them:
 *
 *         const float* hit_Xs = (float*) (dev_velo_cluster_container + 5 * number_of_hits + hit_offset);
 *         const float* hit_Ys = (float*) (dev_velo_cluster_container + hit_offset);
 *         const float* hit_Zs = (float*) (dev_velo_cluster_container + number_of_hits + hit_offset);
 *         const float* hit_Phis = (float*) (dev_velo_cluster_container + 4 * number_of_hits + hit_offset);
 *
 *         Note: Atomics is another case where we need several variables from an array.
 *               We just keep dev_atomics_velo, and access the required ones upon request.
 *
 *               Below are all atomics used by this algorithm:
 *
 *         const int ip_shift = gridDim.x + blockIdx.x * (Velo::num_atomics - 1);
 *         uint* tracks_insert_pointer = (uint*) dev_atomics_velo + event_number;
 *         uint* weaktracks_insert_pointer = (uint*) dev_atomics_velo + ip_shift;
 *         uint* tracklets_insert_pointer = (uint*) dev_atomics_velo + ip_shift + 1;
 *         uint* ttf_insert_pointer = (uint*) dev_atomics_velo + ip_shift + 2;
 *         uint* local_number_of_hits = (uint*) dev_atomics_velo + ip_shift + 3;
 */

__global__ void velo_search_by_triplet::velo_search_by_triplet(
  velo_search_by_triplet::Parameters parameters,
  const VeloGeometry* dev_velo_geometry)
{
  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;
  const uint tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];

  // Think whether this offset'ed container is a good solution
  const auto velo_cluster_container = Velo::Clusters<const uint> {
    parameters.dev_sorted_velo_cluster_container.get() + hit_offset, total_estimated_number_of_clusters};

  const auto hit_phi = parameters.dev_hit_phi + hit_offset;

  // Per event datatypes
  Velo::TrackHits* tracks = parameters.dev_tracks + tracks_offset;

  // Per side datatypes
  bool* hit_used = parameters.dev_hit_used + hit_offset;
  const short* h0_candidates = parameters.dev_h0_candidates + 2 * hit_offset;
  const short* h2_candidates = parameters.dev_h2_candidates + 2 * hit_offset;

  uint* tracks_to_follow =
    parameters.dev_tracks_to_follow + event_number * Configuration::velo_search_by_triplet::ttf_modulo;
  Velo::TrackletHits* three_hit_tracks =
    parameters.dev_three_hit_tracks + event_number * Configuration::velo_search_by_triplet::max_weak_tracks;
  Velo::TrackletHits* tracklets =
    parameters.dev_tracklets + event_number * Configuration::velo_search_by_triplet::ttf_modulo;
  unsigned short* h1_rel_indices = parameters.dev_rel_indices + event_number * Velo::Constants::max_numhits_in_module;

  // Shared memory size is defined externally
  __shared__ float module_data[12];

  process_modules(
    (Velo::Module*) &module_data[0],
    hit_used,
    h0_candidates,
    h2_candidates,
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    hit_phi,
    tracks_to_follow,
    three_hit_tracks,
    tracklets,
    tracks,
    total_estimated_number_of_clusters,
    h1_rel_indices,
    hit_offset,
    dev_velo_geometry->module_zs,
    parameters.dev_atomics_velo + blockIdx.x * Velo::num_atomics,
    parameters.dev_number_of_velo_tracks);
}
