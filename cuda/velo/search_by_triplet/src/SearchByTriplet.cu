#include "SearchByTriplet.cuh"
#include "ClusteringDefinitions.cuh"

__constant__ float Configuration::velo_search_by_triplet_t::forward_phi_tolerance;
__constant__ float Configuration::velo_search_by_triplet_t::max_chi2;
__constant__ float Configuration::velo_search_by_triplet_t::max_scatter_forwarding;
__constant__ float Configuration::velo_search_by_triplet_t::max_scatter_seeding;
__constant__ uint Configuration::velo_search_by_triplet_t::max_skipped_modules;
__constant__ uint Configuration::velo_search_by_triplet_t::max_weak_tracks;
__constant__ float Configuration::velo_search_by_triplet_t::phi_extrapolation_base;
__constant__ float Configuration::velo_search_by_triplet_t::phi_extrapolation_coef;
__constant__ uint Configuration::velo_search_by_triplet_t::ttf_modulo;
__constant__ int Configuration::velo_search_by_triplet_t::ttf_modulo_mask;

void velo_search_by_triplet_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_tracks>(host_buffers.host_number_of_selected_events[0] * Velo::Constants::max_tracks);
  arguments.set_size<dev_tracklets>(
    host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("ttf_modulo"));
  arguments.set_size<dev_tracks_to_follow>(
    host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("ttf_modulo"));
  arguments.set_size<dev_weak_tracks>(
    host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("max_weak_tracks"));
  arguments.set_size<dev_hit_used>(host_buffers.host_total_number_of_velo_clusters[0]);
  arguments.set_size<dev_atomics_velo>(host_buffers.host_number_of_selected_events[0] * Velo::num_atomics);
  arguments.set_size<dev_rel_indices>(
    host_buffers.host_number_of_selected_events[0] * 2 * Velo::Constants::max_numhits_in_module);
}

void velo_search_by_triplet_t::visit(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cudaCheck(cudaMemsetAsync(arguments.offset<dev_atomics_velo>(), 0, arguments.size<dev_atomics_velo>(), cuda_stream));
  cudaCheck(cudaMemsetAsync(arguments.offset<dev_hit_used>(), 0, arguments.size<dev_hit_used>(), cuda_stream));

  algorithm.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_velo_cluster_container>(),
    arguments.offset<dev_estimated_input_size>(),
    arguments.offset<dev_module_cluster_num>(),
    arguments.offset<dev_tracks>(),
    arguments.offset<dev_tracklets>(),
    arguments.offset<dev_tracks_to_follow>(),
    arguments.offset<dev_weak_tracks>(),
    arguments.offset<dev_hit_used>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_h0_candidates>(),
    arguments.offset<dev_h2_candidates>(),
    arguments.offset<dev_rel_indices>(),
    constants.dev_velo_geometry);
}

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

__global__ void velo_search_by_triplet(
  uint32_t* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  uint* dev_module_cluster_num,
  Velo::TrackHits* dev_tracks,
  Velo::TrackletHits* dev_tracklets,
  uint* dev_tracks_to_follow,
  Velo::TrackletHits* dev_weak_tracks,
  bool* dev_hit_used,
  uint* dev_atomics_velo,
  short* dev_h0_candidates,
  short* dev_h2_candidates,
  unsigned short* dev_rel_indices,
  const VeloGeometry* dev_velo_geometry)
{
  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;
  const uint tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const uint number_of_hits = dev_module_cluster_start[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_module_cluster_start + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = dev_module_cluster_num + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];
  assert((module_hitStarts[52] - module_hitStarts[0]) < Velo::Constants::max_number_of_hits_per_event);

  // Per event datatypes
  Velo::TrackHits* tracks = dev_tracks + tracks_offset;

  // Per side datatypes
  bool* hit_used = dev_hit_used + hit_offset;
  short* h0_candidates = dev_h0_candidates + 2 * hit_offset;
  short* h2_candidates = dev_h2_candidates + 2 * hit_offset;

  uint* tracks_to_follow = dev_tracks_to_follow + event_number * Configuration::velo_search_by_triplet_t::ttf_modulo;
  Velo::TrackletHits* weak_tracks =
    dev_weak_tracks + event_number * Configuration::velo_search_by_triplet_t::max_weak_tracks;
  Velo::TrackletHits* tracklets = dev_tracklets + event_number * Configuration::velo_search_by_triplet_t::ttf_modulo;
  unsigned short* h1_rel_indices = dev_rel_indices + event_number * Velo::Constants::max_numhits_in_module;

  // Shared memory size is defined externally
  __shared__ float module_data[12];

  process_modules(
    (Velo::Module*) &module_data[0],
    hit_used,
    h0_candidates,
    h2_candidates,
    module_hitStarts,
    module_hitNums,
    (float*) dev_velo_cluster_container + hit_offset,
    tracks_to_follow,
    weak_tracks,
    tracklets,
    tracks,
    number_of_hits,
    h1_rel_indices,
    hit_offset,
    dev_velo_geometry->module_zs,
    dev_atomics_velo);
}
