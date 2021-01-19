/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <tuple>
#include "ConfiguredInputAggregates.h"
#include "../../stream/gear/include/ArgumentManager.cuh"
#include "../../host/data_provider/include/LayoutProvider.h"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/global_event_cut/include/HostGlobalEventCut.h"
#include "../../host/init_event_list/include/HostInitEventList.h"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/mask_clustering/include/EstimateInputSize.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/mask_clustering/include/MaskedVeloClustering.cuh"
#include "../../device/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"
#include "../../device/velo/search_by_triplet/include/SearchByTriplet.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"
#include "../../device/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"

struct mep_layout__host_mep_layout_t : layout_provider::Parameters::host_mep_layout_t {
  using type = layout_provider::Parameters::host_mep_layout_t::type;
};
struct mep_layout__dev_mep_layout_t : layout_provider::Parameters::dev_mep_layout_t {
  using type = layout_provider::Parameters::dev_mep_layout_t::type;
};
struct host_ut_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                         host_global_event_cut::Parameters::host_ut_raw_banks_t,
                                         host_init_event_list::Parameters::host_ut_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
};
struct host_ut_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                           host_global_event_cut::Parameters::host_ut_raw_offsets_t,
                                           host_init_event_list::Parameters::host_ut_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
};
struct host_scifi_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                            host_global_event_cut::Parameters::host_scifi_raw_banks_t,
                                            host_init_event_list::Parameters::host_scifi_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
};
struct host_scifi_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                              host_global_event_cut::Parameters::host_scifi_raw_offsets_t,
                                              host_init_event_list::Parameters::host_scifi_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
};
struct initialize_lists__host_event_list_t : host_global_event_cut::Parameters::host_event_list_t {
  using type = host_global_event_cut::Parameters::host_event_list_t::type;
};
struct initialize_lists__host_number_of_events_t
  : host_global_event_cut::Parameters::host_number_of_events_t,
    velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
    velo_estimate_input_size::Parameters::host_number_of_events_t,
    velo_masked_clustering::Parameters::host_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
    velo_search_by_triplet::Parameters::host_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
    velo_copy_track_hit_number::Parameters::host_number_of_events_t,
    velo_consolidate_tracks::Parameters::host_number_of_events_t,
    velo_kalman_filter::Parameters::host_number_of_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_events_t::type;
};
struct initialize_lists__host_number_of_selected_events_t
  : host_global_event_cut::Parameters::host_number_of_selected_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_selected_events_t::type;
};
struct initialize_lists__dev_number_of_events_t : host_global_event_cut::Parameters::dev_number_of_events_t,
                                                  velo_masked_clustering::Parameters::dev_number_of_events_t,
                                                  velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
                                                  velo_search_by_triplet::Parameters::dev_number_of_events_t,
                                                  velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
                                                  velo_consolidate_tracks::Parameters::dev_number_of_events_t,
                                                  velo_kalman_filter::Parameters::dev_number_of_events_t {
  using type = host_global_event_cut::Parameters::dev_number_of_events_t::type;
};
struct initialize_lists__dev_event_list_t : host_global_event_cut::Parameters::dev_event_list_t,
                                            velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
                                            velo_estimate_input_size::Parameters::dev_event_list_t,
                                            velo_masked_clustering::Parameters::dev_event_list_t,
                                            velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
                                            velo_search_by_triplet::Parameters::dev_event_list_t,
                                            velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
                                            velo_consolidate_tracks::Parameters::dev_event_list_t,
                                            velo_kalman_filter::Parameters::dev_event_list_t {
  using type = host_global_event_cut::Parameters::dev_event_list_t::type;
};
struct full_event_list__host_number_of_events_t : host_init_event_list::Parameters::host_number_of_events_t {
  using type = host_init_event_list::Parameters::host_number_of_events_t::type;
};
struct full_event_list__host_event_list_t : host_init_event_list::Parameters::host_event_list_t {
  using type = host_init_event_list::Parameters::host_event_list_t::type;
};
struct full_event_list__dev_number_of_events_t : host_init_event_list::Parameters::dev_number_of_events_t {
  using type = host_init_event_list::Parameters::dev_number_of_events_t::type;
};
struct full_event_list__dev_event_list_t : host_init_event_list::Parameters::dev_event_list_t {
  using type = host_init_event_list::Parameters::dev_event_list_t::type;
};
struct velo_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
                                     velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
                                     velo_masked_clustering::Parameters::dev_velo_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
};
struct velo_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
};
struct velo_calculate_number_of_candidates__dev_number_of_candidates_t
  : velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::type;
};
struct prefix_sum_offsets_velo_candidates__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_offsets_velo_candidates__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_offsets_velo_candidates__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
    velo_masked_clustering::Parameters::dev_candidates_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_estimate_input_size__dev_estimated_input_size_t
  : velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::type;
};
struct velo_estimate_input_size__dev_module_candidate_num_t
  : velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
    velo_masked_clustering::Parameters::dev_module_candidate_num_t {
  using type = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::type;
};
struct velo_estimate_input_size__dev_cluster_candidates_t
  : velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
    velo_masked_clustering::Parameters::dev_cluster_candidates_t {
  using type = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::type;
};
struct prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
    velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
    velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_offsets_estimated_input_size__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_offsets_estimated_input_size__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
    velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
    velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
    velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
    velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_masked_clustering__dev_module_cluster_num_t
  : velo_masked_clustering::Parameters::dev_module_cluster_num_t,
    velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
    velo_search_by_triplet::Parameters::dev_module_cluster_num_t {
  using type = velo_masked_clustering::Parameters::dev_module_cluster_num_t::type;
};
struct velo_masked_clustering__dev_velo_cluster_container_t
  : velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
    velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t {
  using type = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::type;
};
struct velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t
  : velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
    velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
    velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
    velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::type;
};
struct velo_calculate_phi_and_sort__dev_hit_permutation_t
  : velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::type;
};
struct velo_calculate_phi_and_sort__dev_hit_phi_t : velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
                                                    velo_search_by_triplet::Parameters::dev_hit_phi_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::type;
};
struct velo_search_by_triplet__dev_tracks_t : velo_search_by_triplet::Parameters::dev_tracks_t,
                                              velo_copy_track_hit_number::Parameters::dev_tracks_t,
                                              velo_consolidate_tracks::Parameters::dev_tracks_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_t::type;
};
struct velo_search_by_triplet__dev_tracklets_t : velo_search_by_triplet::Parameters::dev_tracklets_t {
  using type = velo_search_by_triplet::Parameters::dev_tracklets_t::type;
};
struct velo_search_by_triplet__dev_tracks_to_follow_t : velo_search_by_triplet::Parameters::dev_tracks_to_follow_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::type;
};
struct velo_search_by_triplet__dev_three_hit_tracks_t
  : velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
    velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t {
  using type = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::type;
};
struct velo_search_by_triplet__dev_hit_used_t : velo_search_by_triplet::Parameters::dev_hit_used_t,
                                                velo_three_hit_tracks_filter::Parameters::dev_hit_used_t {
  using type = velo_search_by_triplet::Parameters::dev_hit_used_t::type;
};
struct velo_search_by_triplet__dev_atomics_velo_t : velo_search_by_triplet::Parameters::dev_atomics_velo_t,
                                                    velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t {
  using type = velo_search_by_triplet::Parameters::dev_atomics_velo_t::type;
};
struct velo_search_by_triplet__dev_rel_indices_t : velo_search_by_triplet::Parameters::dev_rel_indices_t {
  using type = velo_search_by_triplet::Parameters::dev_rel_indices_t::type;
};
struct velo_search_by_triplet__dev_number_of_velo_tracks_t
  : velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::type;
};
struct prefix_sum_offsets_velo_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_offsets_velo_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_offsets_velo_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
    velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::type;
};
struct velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::type;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_kalman_filter::Parameters::host_number_of_reconstructed_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::type;
};
struct velo_copy_track_hit_number__dev_velo_track_hit_number_t
  : velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::type;
};
struct velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
    velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    velo_kalman_filter::Parameters::dev_offsets_all_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::type;
};
struct prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_kalman_filter::Parameters::dev_offsets_velo_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_consolidate_tracks__dev_accepted_velo_tracks_t
  : velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t {
  using type = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::type;
};
struct velo_consolidate_tracks__dev_velo_track_hits_t : velo_consolidate_tracks::Parameters::dev_velo_track_hits_t,
                                                        velo_kalman_filter::Parameters::dev_velo_track_hits_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::type;
};
struct velo_kalman_filter__dev_velo_kalman_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t::type;
};
struct velo_kalman_filter__dev_velo_kalman_endvelo_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t::type;
};
struct velo_kalman_filter__dev_velo_lmsfit_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t::type;
};

using configured_arguments_t = std::tuple<
  mep_layout__host_mep_layout_t,
  mep_layout__dev_mep_layout_t,
  host_ut_banks__host_raw_banks_t,
  host_ut_banks__host_raw_offsets_t,
  host_scifi_banks__host_raw_banks_t,
  host_scifi_banks__host_raw_offsets_t,
  initialize_lists__host_event_list_t,
  initialize_lists__host_number_of_events_t,
  initialize_lists__host_number_of_selected_events_t,
  initialize_lists__dev_number_of_events_t,
  initialize_lists__dev_event_list_t,
  full_event_list__host_number_of_events_t,
  full_event_list__host_event_list_t,
  full_event_list__dev_number_of_events_t,
  full_event_list__dev_event_list_t,
  velo_banks__dev_raw_banks_t,
  velo_banks__dev_raw_offsets_t,
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
  prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
  prefix_sum_offsets_velo_tracks__host_output_buffer_t,
  prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
  velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
  velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
  velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
  velo_copy_track_hit_number__dev_velo_track_hit_number_t,
  velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
  prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
  prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
  prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
  velo_consolidate_tracks__dev_accepted_velo_tracks_t,
  velo_consolidate_tracks__dev_velo_track_hits_t,
  velo_kalman_filter__dev_velo_kalman_beamline_states_t,
  velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
  velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>;

using configured_sequence_t = std::tuple<
  layout_provider::layout_provider_t,
  host_data_provider::host_data_provider_t,
  host_data_provider::host_data_provider_t,
  host_global_event_cut::host_global_event_cut_t,
  host_init_event_list::host_init_event_list_t,
  data_provider::data_provider_t,
  velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_estimate_input_size::velo_estimate_input_size_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_masked_clustering::velo_masked_clustering_t,
  velo_calculate_phi_and_sort::velo_calculate_phi_and_sort_t,
  velo_search_by_triplet::velo_search_by_triplet_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_copy_track_hit_number::velo_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_consolidate_tracks::velo_consolidate_tracks_t,
  velo_kalman_filter::velo_kalman_filter_t>;

using configured_sequence_arguments_t = std::tuple<
  std::tuple<mep_layout__host_mep_layout_t, mep_layout__dev_mep_layout_t>,
  std::tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t>,
  std::tuple<host_scifi_banks__host_raw_banks_t, host_scifi_banks__host_raw_offsets_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    initialize_lists__host_event_list_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__host_number_of_selected_events_t,
    initialize_lists__dev_number_of_events_t,
    initialize_lists__dev_event_list_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    full_event_list__host_number_of_events_t,
    full_event_list__host_event_list_t,
    full_event_list__dev_number_of_events_t,
    full_event_list__dev_event_list_t>,
  std::tuple<velo_banks__dev_raw_banks_t, velo_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t>,
  std::tuple<
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t,
    prefix_sum_offsets_velo_candidates__host_output_buffer_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
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
    initialize_lists__host_number_of_events_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    initialize_lists__dev_number_of_events_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    initialize_lists__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    velo_calculate_phi_and_sort__dev_hit_permutation_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
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
    velo_search_by_triplet__dev_number_of_velo_tracks_t>,
  std::tuple<
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    prefix_sum_offsets_velo_tracks__host_output_buffer_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_hit_used_t,
    initialize_lists__dev_number_of_events_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>,
  std::tuple<
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
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
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    initialize_lists__dev_number_of_events_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    velo_consolidate_tracks__dev_velo_track_hits_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>>;

void inline populate_sequence_algorithm_names(configured_sequence_t& sequence)
{
  std::get<0>(sequence).set_name("mep_layout");
  std::get<1>(sequence).set_name("host_ut_banks");
  std::get<2>(sequence).set_name("host_scifi_banks");
  std::get<3>(sequence).set_name("initialize_lists");
  std::get<4>(sequence).set_name("full_event_list");
  std::get<5>(sequence).set_name("velo_banks");
  std::get<6>(sequence).set_name("velo_calculate_number_of_candidates");
  std::get<7>(sequence).set_name("prefix_sum_offsets_velo_candidates");
  std::get<8>(sequence).set_name("velo_estimate_input_size");
  std::get<9>(sequence).set_name("prefix_sum_offsets_estimated_input_size");
  std::get<10>(sequence).set_name("velo_masked_clustering");
  std::get<11>(sequence).set_name("velo_calculate_phi_and_sort");
  std::get<12>(sequence).set_name("velo_search_by_triplet");
  std::get<13>(sequence).set_name("prefix_sum_offsets_velo_tracks");
  std::get<14>(sequence).set_name("velo_three_hit_tracks_filter");
  std::get<15>(sequence).set_name("prefix_sum_offsets_number_of_three_hit_tracks_filtered");
  std::get<16>(sequence).set_name("velo_copy_track_hit_number");
  std::get<17>(sequence).set_name("prefix_sum_offsets_velo_track_hit_number");
  std::get<18>(sequence).set_name("velo_consolidate_tracks");
  std::get<19>(sequence).set_name("velo_kalman_filter");
}

template<typename T>
void populate_sequence_argument_names(T& argument_manager)
{
  argument_manager.template set_name<mep_layout__host_mep_layout_t>("mep_layout__host_mep_layout_t");
  argument_manager.template set_name<mep_layout__dev_mep_layout_t>("mep_layout__dev_mep_layout_t");
  argument_manager.template set_name<host_ut_banks__host_raw_banks_t>("host_ut_banks__host_raw_banks_t");
  argument_manager.template set_name<host_ut_banks__host_raw_offsets_t>("host_ut_banks__host_raw_offsets_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_banks_t>("host_scifi_banks__host_raw_banks_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_offsets_t>("host_scifi_banks__host_raw_offsets_t");
  argument_manager.template set_name<initialize_lists__host_event_list_t>("initialize_lists__host_event_list_t");
  argument_manager.template set_name<initialize_lists__host_number_of_events_t>(
    "initialize_lists__host_number_of_events_t");
  argument_manager.template set_name<initialize_lists__host_number_of_selected_events_t>(
    "initialize_lists__host_number_of_selected_events_t");
  argument_manager.template set_name<initialize_lists__dev_number_of_events_t>(
    "initialize_lists__dev_number_of_events_t");
  argument_manager.template set_name<initialize_lists__dev_event_list_t>("initialize_lists__dev_event_list_t");
  argument_manager.template set_name<full_event_list__host_number_of_events_t>(
    "full_event_list__host_number_of_events_t");
  argument_manager.template set_name<full_event_list__host_event_list_t>("full_event_list__host_event_list_t");
  argument_manager.template set_name<full_event_list__dev_number_of_events_t>(
    "full_event_list__dev_number_of_events_t");
  argument_manager.template set_name<full_event_list__dev_event_list_t>("full_event_list__dev_event_list_t");
  argument_manager.template set_name<velo_banks__dev_raw_banks_t>("velo_banks__dev_raw_banks_t");
  argument_manager.template set_name<velo_banks__dev_raw_offsets_t>("velo_banks__dev_raw_offsets_t");
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
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__dev_output_buffer_t");
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
  argument_manager.template set_name<velo_kalman_filter__dev_velo_kalman_beamline_states_t>(
    "velo_kalman_filter__dev_velo_kalman_beamline_states_t");
  argument_manager.template set_name<velo_kalman_filter__dev_velo_kalman_endvelo_states_t>(
    "velo_kalman_filter__dev_velo_kalman_endvelo_states_t");
  argument_manager.template set_name<velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>(
    "velo_kalman_filter__dev_velo_lmsfit_beamline_states_t");
}
