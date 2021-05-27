#pragma once

#include <tuple>
#include "ConfiguredInputAggregates.h"
#include "..//device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"
#include "..//device/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"
#include "..//host/data_provider/include/HostDataProvider.h"
#include "..//host/init_event_list/include/HostInitEventList.h"
#include "..//device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"
#include "..//device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"
#include "..//device/velo/search_by_triplet/include/SearchByTriplet.cuh"
#include "..//host/init_event_list/include/HostInitNumberOfEvents.h"
#include "..//host/global_event_cut/include/HostGlobalEventCut.h"
#include "..//device/velo/mask_clustering/include/MaskedVeloClustering.cuh"
#include "..//device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"
#include "..//host/prefix_sum/include/HostPrefixSum.h"
#include "..//host/data_provider/include/DataProvider.h"
#include "..//device/velo/mask_clustering/include/EstimateInputSize.cuh"

struct initialize_event_lists__host_event_list_output_t : host_init_event_list::Parameters::host_event_list_output_t {
  using type = host_init_event_list::Parameters::host_event_list_output_t::type;
  using deps = host_init_event_list::Parameters::host_event_list_output_t::deps;
};
struct initialize_event_lists__dev_event_list_output_t : host_init_event_list::Parameters::dev_event_list_output_t {
  using type = host_init_event_list::Parameters::dev_event_list_output_t::type;
  using deps = host_init_event_list::Parameters::dev_event_list_output_t::deps;
};
struct host_scifi_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                            host_global_event_cut::Parameters::host_scifi_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  using deps = host_data_provider::Parameters::host_raw_banks_t::deps;
};
struct host_scifi_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                              host_global_event_cut::Parameters::host_scifi_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  using deps = host_data_provider::Parameters::host_raw_offsets_t::deps;
};
struct host_scifi_banks__host_raw_bank_version_t : host_data_provider::Parameters::host_raw_bank_version_t,
                                                   host_global_event_cut::Parameters::host_ut_raw_bank_version_t {
  using type = host_data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = host_data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct host_ut_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                         host_global_event_cut::Parameters::host_ut_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  using deps = host_data_provider::Parameters::host_raw_banks_t::deps;
};
struct host_ut_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                           host_global_event_cut::Parameters::host_ut_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  using deps = host_data_provider::Parameters::host_raw_offsets_t::deps;
};
struct host_ut_banks__host_raw_bank_version_t : host_data_provider::Parameters::host_raw_bank_version_t {
  using type = host_data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = host_data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct gec__host_event_list_output_t : host_global_event_cut::Parameters::host_event_list_output_t {
  using type = host_global_event_cut::Parameters::host_event_list_output_t::type;
  using deps = host_global_event_cut::Parameters::host_event_list_output_t::deps;
};
struct gec__host_number_of_events_t : host_global_event_cut::Parameters::host_number_of_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_events_t::type;
  using deps = host_global_event_cut::Parameters::host_number_of_events_t::deps;
};
struct gec__host_number_of_selected_events_t : host_global_event_cut::Parameters::host_number_of_selected_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_selected_events_t::type;
  using deps = host_global_event_cut::Parameters::host_number_of_selected_events_t::deps;
};
struct gec__dev_number_of_events_t : host_global_event_cut::Parameters::dev_number_of_events_t {
  using type = host_global_event_cut::Parameters::dev_number_of_events_t::type;
  using deps = host_global_event_cut::Parameters::dev_number_of_events_t::deps;
};
struct gec__dev_event_list_output_t : host_global_event_cut::Parameters::dev_event_list_output_t,
                                      velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
                                      velo_estimate_input_size::Parameters::dev_event_list_t,
                                      velo_masked_clustering::Parameters::dev_event_list_t,
                                      velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
                                      velo_search_by_triplet::Parameters::dev_event_list_t,
                                      velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
                                      velo_consolidate_tracks::Parameters::dev_event_list_t {
  using type = host_global_event_cut::Parameters::dev_event_list_output_t::type;
  using deps = host_global_event_cut::Parameters::dev_event_list_output_t::deps;
};
struct initialize_number_of_events__host_number_of_events_t
  : host_init_number_of_events::Parameters::host_number_of_events_t,
    velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
    velo_estimate_input_size::Parameters::host_number_of_events_t,
    velo_masked_clustering::Parameters::host_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
    velo_search_by_triplet::Parameters::host_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
    velo_copy_track_hit_number::Parameters::host_number_of_events_t,
    velo_consolidate_tracks::Parameters::host_number_of_events_t {
  using type = host_init_number_of_events::Parameters::host_number_of_events_t::type;
  using deps = host_init_number_of_events::Parameters::host_number_of_events_t::deps;
};
struct initialize_number_of_events__dev_number_of_events_t
  : host_init_number_of_events::Parameters::dev_number_of_events_t,
    velo_masked_clustering::Parameters::dev_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
    velo_search_by_triplet::Parameters::dev_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
    velo_consolidate_tracks::Parameters::dev_number_of_events_t {
  using type = host_init_number_of_events::Parameters::dev_number_of_events_t::type;
  using deps = host_init_number_of_events::Parameters::dev_number_of_events_t::deps;
};
struct velo_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
                                     velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
                                     velo_masked_clustering::Parameters::dev_velo_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct velo_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct velo_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct velo_calculate_number_of_candidates__dev_number_of_candidates_t
  : velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::type;
  using deps = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::deps;
};
struct prefix_sum_offsets_velo_candidates__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_candidates__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_candidates__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
    velo_masked_clustering::Parameters::dev_candidates_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_estimate_input_size__dev_estimated_input_size_t
  : velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::deps;
};
struct velo_estimate_input_size__dev_module_candidate_num_t
  : velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
    velo_masked_clustering::Parameters::dev_module_candidate_num_t {
  using type = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::deps;
};
struct velo_estimate_input_size__dev_cluster_candidates_t
  : velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
    velo_masked_clustering::Parameters::dev_cluster_candidates_t {
  using type = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
    velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
    velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
    velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
    velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
    velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
    velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_masked_clustering__dev_module_cluster_num_t
  : velo_masked_clustering::Parameters::dev_module_cluster_num_t,
    velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
    velo_search_by_triplet::Parameters::dev_module_cluster_num_t {
  using type = velo_masked_clustering::Parameters::dev_module_cluster_num_t::type;
  using deps = velo_masked_clustering::Parameters::dev_module_cluster_num_t::deps;
};
struct velo_masked_clustering__dev_velo_cluster_container_t
  : velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
    velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t {
  using type = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::type;
  using deps = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::deps;
};
struct velo_masked_clustering__dev_velo_clusters_t : velo_masked_clustering::Parameters::dev_velo_clusters_t,
                                                     velo_calculate_phi_and_sort::Parameters::dev_velo_clusters_t,
                                                     velo_search_by_triplet::Parameters::dev_velo_clusters_t {
  using type = velo_masked_clustering::Parameters::dev_velo_clusters_t::type;
  using deps = velo_masked_clustering::Parameters::dev_velo_clusters_t::deps;
};
struct velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t
  : velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
    velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
    velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
    velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::deps;
};
struct velo_calculate_phi_and_sort__dev_hit_permutation_t
  : velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::deps;
};
struct velo_calculate_phi_and_sort__dev_hit_phi_t : velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
                                                    velo_search_by_triplet::Parameters::dev_hit_phi_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::deps;
};
struct velo_search_by_triplet__dev_tracks_t : velo_search_by_triplet::Parameters::dev_tracks_t,
                                              velo_copy_track_hit_number::Parameters::dev_tracks_t,
                                              velo_consolidate_tracks::Parameters::dev_tracks_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracks_t::deps;
};
struct velo_search_by_triplet__dev_tracklets_t : velo_search_by_triplet::Parameters::dev_tracklets_t {
  using type = velo_search_by_triplet::Parameters::dev_tracklets_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracklets_t::deps;
};
struct velo_search_by_triplet__dev_tracks_to_follow_t : velo_search_by_triplet::Parameters::dev_tracks_to_follow_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::deps;
};
struct velo_search_by_triplet__dev_three_hit_tracks_t
  : velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
    velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t {
  using type = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::deps;
};
struct velo_search_by_triplet__dev_hit_used_t : velo_search_by_triplet::Parameters::dev_hit_used_t,
                                                velo_three_hit_tracks_filter::Parameters::dev_hit_used_t {
  using type = velo_search_by_triplet::Parameters::dev_hit_used_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_hit_used_t::deps;
};
struct velo_search_by_triplet__dev_atomics_velo_t : velo_search_by_triplet::Parameters::dev_atomics_velo_t,
                                                    velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t {
  using type = velo_search_by_triplet::Parameters::dev_atomics_velo_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_atomics_velo_t::deps;
};
struct velo_search_by_triplet__dev_rel_indices_t : velo_search_by_triplet::Parameters::dev_rel_indices_t {
  using type = velo_search_by_triplet::Parameters::dev_rel_indices_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_rel_indices_t::deps;
};
struct velo_search_by_triplet__dev_number_of_velo_tracks_t
  : velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::deps;
};
struct velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
    velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::type;
  using deps = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::deps;
};
struct velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::type;
  using deps = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::type;
  using deps = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::deps;
};
struct velo_copy_track_hit_number__dev_velo_track_hit_number_t
  : velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::type;
  using deps = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::deps;
};
struct velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
    velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::type;
  using deps = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_consolidate_tracks__dev_accepted_velo_tracks_t
  : velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t {
  using type = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::type;
  using deps = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::deps;
};
struct velo_consolidate_tracks__dev_velo_track_hits_t : velo_consolidate_tracks::Parameters::dev_velo_track_hits_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::type;
  using deps = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::deps;
};

static_assert(all_host_or_all_device_v<
              initialize_event_lists__host_event_list_output_t,
              host_init_event_list::Parameters::host_event_list_output_t>);
static_assert(all_host_or_all_device_v<
              initialize_event_lists__dev_event_list_output_t,
              host_init_event_list::Parameters::dev_event_list_output_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_banks_t,
              host_data_provider::Parameters::host_raw_banks_t,
              host_global_event_cut::Parameters::host_scifi_raw_banks_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_offsets_t,
              host_data_provider::Parameters::host_raw_offsets_t,
              host_global_event_cut::Parameters::host_scifi_raw_offsets_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_bank_version_t,
              host_data_provider::Parameters::host_raw_bank_version_t,
              host_global_event_cut::Parameters::host_ut_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_banks_t,
              host_data_provider::Parameters::host_raw_banks_t,
              host_global_event_cut::Parameters::host_ut_raw_banks_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_offsets_t,
              host_data_provider::Parameters::host_raw_offsets_t,
              host_global_event_cut::Parameters::host_ut_raw_offsets_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_bank_version_t,
              host_data_provider::Parameters::host_raw_bank_version_t>);
static_assert(
  all_host_or_all_device_v<gec__host_event_list_output_t, host_global_event_cut::Parameters::host_event_list_output_t>);
static_assert(
  all_host_or_all_device_v<gec__host_number_of_events_t, host_global_event_cut::Parameters::host_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              gec__host_number_of_selected_events_t,
              host_global_event_cut::Parameters::host_number_of_selected_events_t>);
static_assert(
  all_host_or_all_device_v<gec__dev_number_of_events_t, host_global_event_cut::Parameters::dev_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              gec__dev_event_list_output_t,
              host_global_event_cut::Parameters::dev_event_list_output_t,
              velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
              velo_estimate_input_size::Parameters::dev_event_list_t,
              velo_masked_clustering::Parameters::dev_event_list_t,
              velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
              velo_search_by_triplet::Parameters::dev_event_list_t,
              velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
              velo_consolidate_tracks::Parameters::dev_event_list_t>);
static_assert(all_host_or_all_device_v<
              initialize_number_of_events__host_number_of_events_t,
              host_init_number_of_events::Parameters::host_number_of_events_t,
              velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
              velo_estimate_input_size::Parameters::host_number_of_events_t,
              velo_masked_clustering::Parameters::host_number_of_events_t,
              velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
              velo_search_by_triplet::Parameters::host_number_of_events_t,
              velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
              velo_copy_track_hit_number::Parameters::host_number_of_events_t,
              velo_consolidate_tracks::Parameters::host_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              initialize_number_of_events__dev_number_of_events_t,
              host_init_number_of_events::Parameters::dev_number_of_events_t,
              velo_masked_clustering::Parameters::dev_number_of_events_t,
              velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
              velo_search_by_triplet::Parameters::dev_number_of_events_t,
              velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
              velo_consolidate_tracks::Parameters::dev_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              velo_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
              velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
              velo_masked_clustering::Parameters::dev_velo_raw_input_t>);
static_assert(all_host_or_all_device_v<
              velo_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
              velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
              velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t>);
static_assert(
  all_host_or_all_device_v<velo_banks__host_raw_bank_version_t, data_provider::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_number_of_candidates__dev_number_of_candidates_t,
              velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
              velo_masked_clustering::Parameters::dev_candidates_offsets_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_estimated_input_size_t,
              velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_module_candidate_num_t,
              velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
              velo_masked_clustering::Parameters::dev_module_candidate_num_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_cluster_candidates_t,
              velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
              velo_masked_clustering::Parameters::dev_cluster_candidates_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
              velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
              velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
              velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
              velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
              velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
              velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_module_cluster_num_t,
              velo_masked_clustering::Parameters::dev_module_cluster_num_t,
              velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
              velo_search_by_triplet::Parameters::dev_module_cluster_num_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_velo_cluster_container_t,
              velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
              velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_velo_clusters_t,
              velo_masked_clustering::Parameters::dev_velo_clusters_t,
              velo_calculate_phi_and_sort::Parameters::dev_velo_clusters_t,
              velo_search_by_triplet::Parameters::dev_velo_clusters_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
              velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
              velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
              velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
              velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_hit_permutation_t,
              velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_hit_phi_t,
              velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
              velo_search_by_triplet::Parameters::dev_hit_phi_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracks_t,
              velo_search_by_triplet::Parameters::dev_tracks_t,
              velo_copy_track_hit_number::Parameters::dev_tracks_t,
              velo_consolidate_tracks::Parameters::dev_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracklets_t,
              velo_search_by_triplet::Parameters::dev_tracklets_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracks_to_follow_t,
              velo_search_by_triplet::Parameters::dev_tracks_to_follow_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_three_hit_tracks_t,
              velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
              velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_hit_used_t,
              velo_search_by_triplet::Parameters::dev_hit_used_t,
              velo_three_hit_tracks_filter::Parameters::dev_hit_used_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_atomics_velo_t,
              velo_search_by_triplet::Parameters::dev_atomics_velo_t,
              velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_rel_indices_t,
              velo_search_by_triplet::Parameters::dev_rel_indices_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_number_of_velo_tracks_t,
              velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
              velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
              velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t>);
static_assert(all_host_or_all_device_v<
              velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
              velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
              velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
              velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
              velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
              velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__dev_velo_track_hit_number_t,
              velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
              velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t>);
static_assert(all_host_or_all_device_v<
              velo_consolidate_tracks__dev_accepted_velo_tracks_t,
              velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_consolidate_tracks__dev_velo_track_hits_t,
              velo_consolidate_tracks::Parameters::dev_velo_track_hits_t>);

using configured_arguments_t = std::tuple<
  initialize_event_lists__host_event_list_output_t,
  initialize_event_lists__dev_event_list_output_t,
  host_scifi_banks__host_raw_banks_t,
  host_scifi_banks__host_raw_offsets_t,
  host_scifi_banks__host_raw_bank_version_t,
  host_ut_banks__host_raw_banks_t,
  host_ut_banks__host_raw_offsets_t,
  host_ut_banks__host_raw_bank_version_t,
  gec__host_event_list_output_t,
  gec__host_number_of_events_t,
  gec__host_number_of_selected_events_t,
  gec__dev_number_of_events_t,
  gec__dev_event_list_output_t,
  initialize_number_of_events__host_number_of_events_t,
  initialize_number_of_events__dev_number_of_events_t,
  velo_banks__dev_raw_banks_t,
  velo_banks__dev_raw_offsets_t,
  velo_banks__host_raw_bank_version_t,
  velo_calculate_number_of_candidates__dev_number_of_candidates_t,
  prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
  prefix_sum_offsets_velo_candidates__host_output_buffer_t,
  prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
  velo_estimate_input_size__dev_estimated_input_size_t,
  velo_estimate_input_size__dev_module_candidate_num_t,
  velo_estimate_input_size__dev_cluster_candidates_t,
  prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
  prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
  prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
  velo_masked_clustering__dev_module_cluster_num_t,
  velo_masked_clustering__dev_velo_cluster_container_t,
  velo_masked_clustering__dev_velo_clusters_t,
  velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
  velo_calculate_phi_and_sort__dev_hit_permutation_t,
  velo_calculate_phi_and_sort__dev_hit_phi_t,
  velo_search_by_triplet__dev_tracks_t,
  velo_search_by_triplet__dev_tracklets_t,
  velo_search_by_triplet__dev_tracks_to_follow_t,
  velo_search_by_triplet__dev_three_hit_tracks_t,
  velo_search_by_triplet__dev_hit_used_t,
  velo_search_by_triplet__dev_atomics_velo_t,
  velo_search_by_triplet__dev_rel_indices_t,
  velo_search_by_triplet__dev_number_of_velo_tracks_t,
  velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
  velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
  prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
  prefix_sum_offsets_velo_tracks__host_output_buffer_t,
  prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
  velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
  velo_copy_track_hit_number__dev_velo_track_hit_number_t,
  velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
  prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
  prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
  prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
  velo_consolidate_tracks__dev_accepted_velo_tracks_t,
  velo_consolidate_tracks__dev_velo_track_hits_t>;

using configured_sequence_t = std::tuple<
  host_init_event_list::host_init_event_list_t,
  host_data_provider::host_data_provider_t,
  host_data_provider::host_data_provider_t,
  host_global_event_cut::host_global_event_cut_t,
  host_init_number_of_events::host_init_number_of_events_t,
  data_provider::data_provider_t,
  velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_estimate_input_size::velo_estimate_input_size_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_masked_clustering::velo_masked_clustering_t,
  velo_calculate_phi_and_sort::velo_calculate_phi_and_sort_t,
  velo_search_by_triplet::velo_search_by_triplet_t,
  velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_copy_track_hit_number::velo_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_consolidate_tracks::velo_consolidate_tracks_t>;

using configured_sequence_arguments_t = std::tuple<
  std::tuple<initialize_event_lists__host_event_list_output_t, initialize_event_lists__dev_event_list_output_t>,
  std::tuple<
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_bank_version_t>,
  std::
    tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t, host_ut_banks__host_raw_bank_version_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_bank_version_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    gec__host_event_list_output_t,
    gec__host_number_of_events_t,
    gec__host_number_of_selected_events_t,
    gec__dev_number_of_events_t,
    gec__dev_event_list_output_t>,
  std::tuple<initialize_number_of_events__host_number_of_events_t, initialize_number_of_events__dev_number_of_events_t>,
  std::tuple<velo_banks__dev_raw_banks_t, velo_banks__dev_raw_offsets_t, velo_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t>,
  std::tuple<
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t,
    prefix_sum_offsets_velo_candidates__host_output_buffer_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_number_of_events__host_number_of_events_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t,
    gec__dev_event_list_output_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    velo_calculate_phi_and_sort__dev_hit_permutation_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t,
    velo_search_by_triplet__dev_tracks_t,
    velo_search_by_triplet__dev_tracklets_t,
    velo_search_by_triplet__dev_tracks_to_follow_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_hit_used_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_rel_indices_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_hit_used_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>,
  std::tuple<
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    prefix_sum_offsets_velo_tracks__host_output_buffer_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_velo_track_hit_number_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t>,
  std::tuple<
    prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
    velo_copy_track_hit_number__dev_velo_track_hit_number_t,
    prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    velo_consolidate_tracks__dev_velo_track_hits_t>>;

constexpr auto sequence_algorithm_names = std::array {
  "initialize_event_lists",
  "host_scifi_banks",
  "host_ut_banks",
  "gec",
  "initialize_number_of_events",
  "velo_banks",
  "velo_calculate_number_of_candidates",
  "prefix_sum_offsets_velo_candidates",
  "velo_estimate_input_size",
  "prefix_sum_offsets_estimated_input_size",
  "velo_masked_clustering",
  "velo_calculate_phi_and_sort",
  "velo_search_by_triplet",
  "velo_three_hit_tracks_filter",
  "prefix_sum_offsets_number_of_three_hit_tracks_filtered",
  "prefix_sum_offsets_velo_tracks",
  "velo_copy_track_hit_number",
  "prefix_sum_offsets_velo_track_hit_number",
  "velo_consolidate_tracks"};

template<typename T>
void populate_sequence_argument_names(T& argument_manager)
{
  argument_manager.template set_name<initialize_event_lists__host_event_list_output_t>(
    "initialize_event_lists__host_event_list_output_t");
  argument_manager.template set_name<initialize_event_lists__dev_event_list_output_t>(
    "initialize_event_lists__dev_event_list_output_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_banks_t>("host_scifi_banks__host_raw_banks_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_offsets_t>("host_scifi_banks__host_raw_offsets_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_bank_version_t>(
    "host_scifi_banks__host_raw_bank_version_t");
  argument_manager.template set_name<host_ut_banks__host_raw_banks_t>("host_ut_banks__host_raw_banks_t");
  argument_manager.template set_name<host_ut_banks__host_raw_offsets_t>("host_ut_banks__host_raw_offsets_t");
  argument_manager.template set_name<host_ut_banks__host_raw_bank_version_t>("host_ut_banks__host_raw_bank_version_t");
  argument_manager.template set_name<gec__host_event_list_output_t>("gec__host_event_list_output_t");
  argument_manager.template set_name<gec__host_number_of_events_t>("gec__host_number_of_events_t");
  argument_manager.template set_name<gec__host_number_of_selected_events_t>("gec__host_number_of_selected_events_t");
  argument_manager.template set_name<gec__dev_number_of_events_t>("gec__dev_number_of_events_t");
  argument_manager.template set_name<gec__dev_event_list_output_t>("gec__dev_event_list_output_t");
  argument_manager.template set_name<initialize_number_of_events__host_number_of_events_t>(
    "initialize_number_of_events__host_number_of_events_t");
  argument_manager.template set_name<initialize_number_of_events__dev_number_of_events_t>(
    "initialize_number_of_events__dev_number_of_events_t");
  argument_manager.template set_name<velo_banks__dev_raw_banks_t>("velo_banks__dev_raw_banks_t");
  argument_manager.template set_name<velo_banks__dev_raw_offsets_t>("velo_banks__dev_raw_offsets_t");
  argument_manager.template set_name<velo_banks__host_raw_bank_version_t>("velo_banks__host_raw_bank_version_t");
  argument_manager.template set_name<velo_calculate_number_of_candidates__dev_number_of_candidates_t>(
    "velo_calculate_number_of_candidates__dev_number_of_candidates_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_candidates__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__host_output_buffer_t>(
    "prefix_sum_offsets_velo_candidates__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_candidates__dev_output_buffer_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_estimated_input_size_t>(
    "velo_estimate_input_size__dev_estimated_input_size_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_module_candidate_num_t>(
    "velo_estimate_input_size__dev_module_candidate_num_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_cluster_candidates_t>(
    "velo_estimate_input_size__dev_cluster_candidates_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t>(
    "prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__host_output_buffer_t>(
    "prefix_sum_offsets_estimated_input_size__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__dev_output_buffer_t>(
    "prefix_sum_offsets_estimated_input_size__dev_output_buffer_t");
  argument_manager.template set_name<velo_masked_clustering__dev_module_cluster_num_t>(
    "velo_masked_clustering__dev_module_cluster_num_t");
  argument_manager.template set_name<velo_masked_clustering__dev_velo_cluster_container_t>(
    "velo_masked_clustering__dev_velo_cluster_container_t");
  argument_manager.template set_name<velo_masked_clustering__dev_velo_clusters_t>(
    "velo_masked_clustering__dev_velo_clusters_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t>(
    "velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_hit_permutation_t>(
    "velo_calculate_phi_and_sort__dev_hit_permutation_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_hit_phi_t>(
    "velo_calculate_phi_and_sort__dev_hit_phi_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracks_t>("velo_search_by_triplet__dev_tracks_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracklets_t>(
    "velo_search_by_triplet__dev_tracklets_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracks_to_follow_t>(
    "velo_search_by_triplet__dev_tracks_to_follow_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_three_hit_tracks_t>(
    "velo_search_by_triplet__dev_three_hit_tracks_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_hit_used_t>("velo_search_by_triplet__dev_hit_used_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_atomics_velo_t>(
    "velo_search_by_triplet__dev_atomics_velo_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_rel_indices_t>(
    "velo_search_by_triplet__dev_rel_indices_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_number_of_velo_tracks_t>(
    "velo_search_by_triplet__dev_number_of_velo_tracks_t");
  argument_manager.template set_name<velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t>(
    "velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t");
  argument_manager.template set_name<velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>(
    "velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__dev_output_buffer_t");
  argument_manager.template set_name<velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t>(
    "velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t");
  argument_manager.template set_name<velo_copy_track_hit_number__dev_velo_track_hit_number_t>(
    "velo_copy_track_hit_number__dev_velo_track_hit_number_t");
  argument_manager.template set_name<velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t>(
    "velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t>(
    "prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<velo_consolidate_tracks__dev_accepted_velo_tracks_t>(
    "velo_consolidate_tracks__dev_accepted_velo_tracks_t");
  argument_manager.template set_name<velo_consolidate_tracks__dev_velo_track_hits_t>(
    "velo_consolidate_tracks__dev_velo_track_hits_t");
}
