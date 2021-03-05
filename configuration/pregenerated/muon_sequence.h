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
#include "../../device/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_histo.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_peak.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_cleanup.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/UTDecoding/include/UTPreDecode.cuh"
#include "../../device/UT/UTDecoding/include/UTFindPermutation.cuh"
#include "../../device/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"
#include "../../device/UT/compassUT/include/UTSelectVeloTracks.cuh"
#include "../../device/UT/compassUT/include/SearchWindows.cuh"
#include "../../device/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"
#include "../../device/UT/compassUT/include/CompassUT.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/consolidate/include/UTCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/consolidate/include/ConsolidateUT.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/SciFi/preprocessing/include/SciFiCalculateClusterCountV4.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/preprocessing/include/SciFiPreDecodeV4.cuh"
#include "../../device/SciFi/preprocessing/include/SciFiRawBankDecoderV4.cuh"
#include "../../device/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"
#include "../../device/SciFi/looking_forward/include/LFTripletSeeding.cuh"
#include "../../device/SciFi/looking_forward/include/LFCreateTracks.cuh"
#include "../../device/SciFi/looking_forward/include/LFQualityFilterLength.cuh"
#include "../../device/SciFi/looking_forward/include/LFQualityFilter.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/consolidate/include/ConsolidateSciFi.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/muon/decoding/include/MuonCalculateSRQSize.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/muon/decoding/include/MuonPopulateTileAndTDC.cuh"
#include "../../device/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/muon/decoding/include/MuonPopulateHits.cuh"
#include "../../device/muon/is_muon/include/IsMuon.cuh"

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
    velo_kalman_filter::Parameters::host_number_of_events_t,
    pv_beamline_extrapolate::Parameters::host_number_of_events_t,
    pv_beamline_histo::Parameters::host_number_of_events_t,
    pv_beamline_peak::Parameters::host_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_events_t,
    pv_beamline_cleanup::Parameters::host_number_of_events_t,
    ut_calculate_number_of_hits::Parameters::host_number_of_events_t,
    ut_pre_decode::Parameters::host_number_of_events_t,
    ut_find_permutation::Parameters::host_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::host_number_of_events_t,
    ut_select_velo_tracks::Parameters::host_number_of_events_t,
    ut_search_windows::Parameters::host_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_events_t,
    compass_ut::Parameters::host_number_of_events_t,
    ut_copy_track_hit_number::Parameters::host_number_of_events_t,
    ut_consolidate_tracks::Parameters::host_number_of_events_t,
    scifi_calculate_cluster_count_v4::Parameters::host_number_of_events_t,
    scifi_pre_decode_v4::Parameters::host_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::host_number_of_events_t,
    lf_search_initial_windows::Parameters::host_number_of_events_t,
    lf_triplet_seeding::Parameters::host_number_of_events_t,
    lf_create_tracks::Parameters::host_number_of_events_t,
    lf_quality_filter_length::Parameters::host_number_of_events_t,
    lf_quality_filter::Parameters::host_number_of_events_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_events_t,
    scifi_consolidate_tracks::Parameters::host_number_of_events_t,
    muon_calculate_srq_size::Parameters::host_number_of_events_t,
    muon_populate_tile_and_tdc::Parameters::host_number_of_events_t,
    muon_add_coords_crossing_maps::Parameters::host_number_of_events_t,
    muon_populate_hits::Parameters::host_number_of_events_t,
    is_muon::Parameters::host_number_of_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_events_t::type;
};
struct initialize_lists__host_number_of_selected_events_t
  : host_global_event_cut::Parameters::host_number_of_selected_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_selected_events_t::type;
};
struct initialize_lists__dev_number_of_events_t
  : host_global_event_cut::Parameters::dev_number_of_events_t,
    velo_masked_clustering::Parameters::dev_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
    velo_search_by_triplet::Parameters::dev_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
    velo_consolidate_tracks::Parameters::dev_number_of_events_t,
    velo_kalman_filter::Parameters::dev_number_of_events_t,
    pv_beamline_extrapolate::Parameters::dev_number_of_events_t,
    pv_beamline_histo::Parameters::dev_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::dev_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::dev_number_of_events_t,
    ut_pre_decode::Parameters::dev_number_of_events_t,
    ut_find_permutation::Parameters::dev_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks::Parameters::dev_number_of_events_t,
    ut_search_windows::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_number_of_events_t,
    compass_ut::Parameters::dev_number_of_events_t,
    ut_consolidate_tracks::Parameters::dev_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::dev_number_of_events_t,
    lf_search_initial_windows::Parameters::dev_number_of_events_t,
    lf_triplet_seeding::Parameters::dev_number_of_events_t,
    lf_create_tracks::Parameters::dev_number_of_events_t,
    lf_quality_filter_length::Parameters::dev_number_of_events_t,
    lf_quality_filter::Parameters::dev_number_of_events_t,
    scifi_consolidate_tracks::Parameters::dev_number_of_events_t,
    muon_populate_hits::Parameters::dev_number_of_events_t,
    is_muon::Parameters::dev_number_of_events_t {
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
                                            velo_kalman_filter::Parameters::dev_event_list_t,
                                            pv_beamline_extrapolate::Parameters::dev_event_list_t,
                                            pv_beamline_histo::Parameters::dev_event_list_t,
                                            pv_beamline_peak::Parameters::dev_event_list_t,
                                            pv_beamline_calculate_denom::Parameters::dev_event_list_t,
                                            pv_beamline_multi_fitter::Parameters::dev_event_list_t,
                                            pv_beamline_cleanup::Parameters::dev_event_list_t,
                                            ut_calculate_number_of_hits::Parameters::dev_event_list_t,
                                            ut_pre_decode::Parameters::dev_event_list_t,
                                            ut_find_permutation::Parameters::dev_event_list_t,
                                            ut_decode_raw_banks_in_order::Parameters::dev_event_list_t,
                                            ut_select_velo_tracks::Parameters::dev_event_list_t,
                                            ut_search_windows::Parameters::dev_event_list_t,
                                            ut_select_velo_tracks_with_windows::Parameters::dev_event_list_t,
                                            compass_ut::Parameters::dev_event_list_t,
                                            ut_consolidate_tracks::Parameters::dev_event_list_t,
                                            scifi_calculate_cluster_count_v4::Parameters::dev_event_list_t,
                                            scifi_pre_decode_v4::Parameters::dev_event_list_t,
                                            scifi_raw_bank_decoder_v4::Parameters::dev_event_list_t,
                                            lf_search_initial_windows::Parameters::dev_event_list_t,
                                            lf_triplet_seeding::Parameters::dev_event_list_t,
                                            lf_create_tracks::Parameters::dev_event_list_t,
                                            lf_quality_filter_length::Parameters::dev_event_list_t,
                                            lf_quality_filter::Parameters::dev_event_list_t,
                                            scifi_consolidate_tracks::Parameters::dev_event_list_t,
                                            muon_calculate_srq_size::Parameters::dev_event_list_t,
                                            muon_populate_tile_and_tdc::Parameters::dev_event_list_t,
                                            muon_add_coords_crossing_maps::Parameters::dev_event_list_t,
                                            muon_populate_hits::Parameters::dev_event_list_t,
                                            is_muon::Parameters::dev_event_list_t {
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
    velo_kalman_filter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_search_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_reconstructed_velo_tracks_t {
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
    velo_kalman_filter::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_histo::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    ut_search_windows::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_all_velo_tracks_t,
    compass_ut::Parameters::dev_offsets_all_velo_tracks_t,
    lf_search_initial_windows::Parameters::dev_offsets_all_velo_tracks_t,
    lf_triplet_seeding::Parameters::dev_offsets_all_velo_tracks_t,
    lf_create_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t {
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
    velo_kalman_filter::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_histo::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_search_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    compass_ut::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_search_initial_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_create_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct velo_consolidate_tracks__dev_accepted_velo_tracks_t
  : velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_accepted_velo_tracks_t {
  using type = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::type;
};
struct velo_consolidate_tracks__dev_velo_track_hits_t : velo_consolidate_tracks::Parameters::dev_velo_track_hits_t,
                                                        velo_kalman_filter::Parameters::dev_velo_track_hits_t,
                                                        ut_select_velo_tracks::Parameters::dev_velo_track_hits_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::type;
};
struct velo_kalman_filter__dev_velo_kalman_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t,
    pv_beamline_extrapolate::Parameters::dev_velo_kalman_beamline_states_t,
    ut_select_velo_tracks::Parameters::dev_velo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t::type;
};
struct velo_kalman_filter__dev_velo_kalman_endvelo_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t,
    ut_search_windows::Parameters::dev_velo_states_t,
    lf_search_initial_windows::Parameters::dev_velo_states_t,
    lf_triplet_seeding::Parameters::dev_velo_states_t,
    lf_create_tracks::Parameters::dev_velo_states_t,
    scifi_consolidate_tracks::Parameters::dev_velo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t::type;
};
struct velo_kalman_filter__dev_velo_lmsfit_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t,
    compass_ut::Parameters::dev_velo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t::type;
};
struct pv_beamline_extrapolate__dev_pvtracks_t : pv_beamline_extrapolate::Parameters::dev_pvtracks_t,
                                                 pv_beamline_histo::Parameters::dev_pvtracks_t,
                                                 pv_beamline_calculate_denom::Parameters::dev_pvtracks_t,
                                                 pv_beamline_multi_fitter::Parameters::dev_pvtracks_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtracks_t::type;
};
struct pv_beamline_extrapolate__dev_pvtrack_z_t : pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_pvtrack_z_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t::type;
};
struct pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t
  : pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t::type;
};
struct pv_beamline_histo__dev_zhisto_t : pv_beamline_histo::Parameters::dev_zhisto_t,
                                         pv_beamline_peak::Parameters::dev_zhisto_t {
  using type = pv_beamline_histo::Parameters::dev_zhisto_t::type;
};
struct pv_beamline_peak__dev_zpeaks_t : pv_beamline_peak::Parameters::dev_zpeaks_t,
                                        pv_beamline_calculate_denom::Parameters::dev_zpeaks_t,
                                        pv_beamline_multi_fitter::Parameters::dev_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_zpeaks_t::type;
};
struct pv_beamline_peak__dev_number_of_zpeaks_t : pv_beamline_peak::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_calculate_denom::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_number_of_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_number_of_zpeaks_t::type;
};
struct pv_beamline_calculate_denom__dev_pvtracks_denom_t
  : pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t,
    pv_beamline_multi_fitter::Parameters::dev_pvtracks_denom_t {
  using type = pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t::type;
};
struct pv_beamline_multi_fitter__dev_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t::type;
};
struct pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_number_of_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t::type;
};
struct pv_beamline_cleanup__dev_multi_final_vertices_t : pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t::type;
};
struct pv_beamline_cleanup__dev_number_of_multi_final_vertices_t
  : pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t::type;
};
struct ut_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                   ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_t,
                                   ut_pre_decode::Parameters::dev_ut_raw_input_t,
                                   ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
};
struct ut_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                     ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_pre_decode::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
};
struct ut_calculate_number_of_hits__dev_ut_hit_sizes_t : ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t,
                                                         host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t::type;
};
struct prefix_sum_ut_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_pre_decode::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_find_permutation::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_decode_raw_banks_in_order::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_ut_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_ut_hits__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_ut_hits__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                 ut_pre_decode::Parameters::dev_ut_hit_offsets_t,
                                                 ut_find_permutation::Parameters::dev_ut_hit_offsets_t,
                                                 ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_offsets_t,
                                                 ut_search_windows::Parameters::dev_ut_hit_offsets_t,
                                                 compass_ut::Parameters::dev_ut_hit_offsets_t,
                                                 ut_consolidate_tracks::Parameters::dev_ut_hit_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct ut_pre_decode__dev_ut_pre_decoded_hits_t : ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_find_permutation::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_decode_raw_banks_in_order::Parameters::dev_ut_pre_decoded_hits_t {
  using type = ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t::type;
};
struct ut_pre_decode__dev_ut_hit_count_t : ut_pre_decode::Parameters::dev_ut_hit_count_t {
  using type = ut_pre_decode::Parameters::dev_ut_hit_count_t::type;
};
struct ut_find_permutation__dev_ut_hit_permutations_t
  : ut_find_permutation::Parameters::dev_ut_hit_permutations_t,
    ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_permutations_t {
  using type = ut_find_permutation::Parameters::dev_ut_hit_permutations_t::type;
};
struct ut_decode_raw_banks_in_order__dev_ut_hits_t : ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t,
                                                     ut_search_windows::Parameters::dev_ut_hits_t,
                                                     compass_ut::Parameters::dev_ut_hits_t,
                                                     ut_consolidate_tracks::Parameters::dev_ut_hits_t {
  using type = ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t::type;
};
struct ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t::type;
};
struct ut_select_velo_tracks__dev_ut_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t::type;
};
struct ut_search_windows__dev_ut_windows_layers_t
  : ut_search_windows::Parameters::dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_windows_layers_t,
    compass_ut::Parameters::dev_ut_windows_layers_t {
  using type = ut_search_windows::Parameters::dev_ut_windows_layers_t::type;
};
struct ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t {
  using type =
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t::type;
};
struct ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_selected_velo_tracks_with_windows_t {
  using type = ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t::type;
};
struct compass_ut__dev_ut_tracks_t : compass_ut::Parameters::dev_ut_tracks_t,
                                     ut_copy_track_hit_number::Parameters::dev_ut_tracks_t,
                                     ut_consolidate_tracks::Parameters::dev_ut_tracks_t {
  using type = compass_ut::Parameters::dev_ut_tracks_t::type;
};
struct compass_ut__dev_atomics_ut_t : compass_ut::Parameters::dev_atomics_ut_t,
                                      host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = compass_ut::Parameters::dev_atomics_ut_t::type;
};
struct prefix_sum_ut_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_copy_track_hit_number::Parameters::host_number_of_reconstructed_ut_tracks_t,
    ut_consolidate_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_search_initial_windows::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_triplet_seeding::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_create_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_quality_filter_length::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_quality_filter::Parameters::host_number_of_reconstructed_ut_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_ut_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_ut_tracks__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                   ut_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
                                                   ut_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_search_initial_windows::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_triplet_seeding::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_create_tracks::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_quality_filter_length::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_quality_filter::Parameters::dev_offsets_ut_tracks_t,
                                                   scifi_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
                                                   scifi_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct ut_copy_track_hit_number__dev_ut_track_hit_number_t
  : ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t::type;
};
struct prefix_sum_ut_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_ut_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_ut_track_hit_number__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_ut_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    ut_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_search_initial_windows::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_triplet_seeding::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_create_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_quality_filter_length::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_quality_filter::Parameters::dev_offsets_ut_track_hit_number_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct ut_consolidate_tracks__dev_ut_track_hits_t : ut_consolidate_tracks::Parameters::dev_ut_track_hits_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_hits_t::type;
};
struct ut_consolidate_tracks__dev_ut_qop_t : ut_consolidate_tracks::Parameters::dev_ut_qop_t,
                                             lf_search_initial_windows::Parameters::dev_ut_qop_t,
                                             lf_triplet_seeding::Parameters::dev_ut_qop_t,
                                             lf_create_tracks::Parameters::dev_ut_qop_t,
                                             scifi_consolidate_tracks::Parameters::dev_ut_qop_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_qop_t::type;
};
struct ut_consolidate_tracks__dev_ut_x_t : ut_consolidate_tracks::Parameters::dev_ut_x_t,
                                           lf_search_initial_windows::Parameters::dev_ut_x_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_x_t::type;
};
struct ut_consolidate_tracks__dev_ut_tx_t : ut_consolidate_tracks::Parameters::dev_ut_tx_t,
                                            lf_search_initial_windows::Parameters::dev_ut_tx_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_tx_t::type;
};
struct ut_consolidate_tracks__dev_ut_z_t : ut_consolidate_tracks::Parameters::dev_ut_z_t,
                                           lf_search_initial_windows::Parameters::dev_ut_z_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_z_t::type;
};
struct ut_consolidate_tracks__dev_ut_track_velo_indices_t
  : ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
    lf_search_initial_windows::Parameters::dev_ut_track_velo_indices_t,
    lf_triplet_seeding::Parameters::dev_ut_track_velo_indices_t,
    lf_create_tracks::Parameters::dev_ut_track_velo_indices_t,
    scifi_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t::type;
};
struct scifi_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                      scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
};
struct scifi_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                        scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
};
struct scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t
  : scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t::type;
};
struct prefix_sum_scifi_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_pre_decode_v4::Parameters::host_accumulated_number_of_scifi_hits_t,
    scifi_raw_bank_decoder_v4::Parameters::host_accumulated_number_of_scifi_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_scifi_hits__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_scifi_hits__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                    scifi_pre_decode_v4::Parameters::dev_scifi_hit_offsets_t,
                                                    scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_search_initial_windows::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_triplet_seeding::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_create_tracks::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_quality_filter::Parameters::dev_scifi_hit_offsets_t,
                                                    scifi_consolidate_tracks::Parameters::dev_scifi_hit_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct scifi_pre_decode_v4_t__dev_cluster_references_t
  : scifi_pre_decode_v4::Parameters::dev_cluster_references_t,
    scifi_raw_bank_decoder_v4::Parameters::dev_cluster_references_t {
  using type = scifi_pre_decode_v4::Parameters::dev_cluster_references_t::type;
};
struct scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t : scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t,
                                                       lf_search_initial_windows::Parameters::dev_scifi_hits_t,
                                                       lf_triplet_seeding::Parameters::dev_scifi_hits_t,
                                                       lf_create_tracks::Parameters::dev_scifi_hits_t,
                                                       lf_quality_filter::Parameters::dev_scifi_hits_t,
                                                       scifi_consolidate_tracks::Parameters::dev_scifi_hits_t {
  using type = scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t::type;
};
struct lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_initial_windows_t,
    lf_create_tracks::Parameters::dev_scifi_lf_initial_windows_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t::type;
};
struct lf_search_initial_windows_t__dev_ut_states_t : lf_search_initial_windows::Parameters::dev_ut_states_t,
                                                      lf_triplet_seeding::Parameters::dev_ut_states_t,
                                                      lf_create_tracks::Parameters::dev_ut_states_t,
                                                      lf_quality_filter::Parameters::dev_ut_states_t {
  using type = lf_search_initial_windows::Parameters::dev_ut_states_t::type;
};
struct lf_search_initial_windows_t__dev_scifi_lf_process_track_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_process_track_t,
    lf_create_tracks::Parameters::dev_scifi_lf_process_track_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t::type;
};
struct lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t::type;
};
struct lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_number_of_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t::type;
};
struct lf_create_tracks_t__dev_scifi_lf_tracks_t : lf_create_tracks::Parameters::dev_scifi_lf_tracks_t,
                                                   lf_quality_filter_length::Parameters::dev_scifi_lf_tracks_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_tracks_t::type;
};
struct lf_create_tracks_t__dev_scifi_lf_atomics_t : lf_create_tracks::Parameters::dev_scifi_lf_atomics_t,
                                                    lf_quality_filter_length::Parameters::dev_scifi_lf_atomics_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_atomics_t::type;
};
struct lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t
  : lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t::type;
};
struct lf_create_tracks_t__dev_scifi_lf_parametrization_t
  : lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t,
    lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t::type;
};
struct lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_tracks_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t::type;
};
struct lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_atomics_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t::type;
};
struct lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t,
    lf_quality_filter::Parameters::dev_scifi_lf_parametrization_length_filter_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t::type;
};
struct lf_quality_filter_t__dev_lf_quality_of_tracks_t : lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t {
  using type = lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t::type;
};
struct lf_quality_filter_t__dev_atomics_scifi_t : lf_quality_filter::Parameters::dev_atomics_scifi_t,
                                                  host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = lf_quality_filter::Parameters::dev_atomics_scifi_t::type;
};
struct lf_quality_filter_t__dev_scifi_tracks_t : lf_quality_filter::Parameters::dev_scifi_tracks_t,
                                                 scifi_copy_track_hit_number::Parameters::dev_scifi_tracks_t,
                                                 scifi_consolidate_tracks::Parameters::dev_scifi_tracks_t {
  using type = lf_quality_filter::Parameters::dev_scifi_tracks_t::type;
};
struct lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t
  : lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t::type;
};
struct lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t
  : lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks::Parameters::dev_scifi_lf_parametrization_consolidate_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t::type;
};
struct prefix_sum_forward_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    scifi_consolidate_tracks::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    is_muon::Parameters::host_number_of_reconstructed_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_forward_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_forward_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_copy_track_hit_number::Parameters::dev_offsets_forward_tracks_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_forward_tracks_t,
    is_muon::Parameters::dev_offsets_forward_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t
  : scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t::type;
};
struct prefix_sum_scifi_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct prefix_sum_scifi_track_hit_number__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct prefix_sum_scifi_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_scifi_track_hit_number_t,
    is_muon::Parameters::dev_offsets_scifi_track_hit_number {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct scifi_consolidate_tracks_t__dev_scifi_track_hits_t
  : scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t::type;
};
struct scifi_consolidate_tracks_t__dev_scifi_qop_t : scifi_consolidate_tracks::Parameters::dev_scifi_qop_t,
                                                     is_muon::Parameters::dev_scifi_qop_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_qop_t::type;
};
struct scifi_consolidate_tracks_t__dev_scifi_states_t : scifi_consolidate_tracks::Parameters::dev_scifi_states_t,
                                                        is_muon::Parameters::dev_scifi_states_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_states_t::type;
};
struct scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t
  : scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t,
    is_muon::Parameters::dev_scifi_track_ut_indices_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t::type;
};
struct muon_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     muon_calculate_srq_size::Parameters::dev_muon_raw_t,
                                     muon_populate_tile_and_tdc::Parameters::dev_muon_raw_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
};
struct muon_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       muon_calculate_srq_size::Parameters::dev_muon_raw_offsets_t,
                                       muon_populate_tile_and_tdc::Parameters::dev_muon_raw_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
};
struct muon_calculate_srq_size_t__dev_muon_raw_to_hits_t
  : muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_tile_and_tdc::Parameters::dev_muon_raw_to_hits_t,
    muon_add_coords_crossing_maps::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_hits::Parameters::dev_muon_raw_to_hits_t {
  using type = muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t::type;
};
struct muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t
  : muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t::type;
};
struct muon_srq_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_tile_and_tdc::Parameters::host_muon_total_number_of_tiles_t,
    muon_add_coords_crossing_maps::Parameters::host_muon_total_number_of_tiles_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct muon_srq_prefix_sum__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct muon_srq_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_tile_and_tdc::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_populate_hits::Parameters::dev_storage_station_region_quarter_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct muon_populate_tile_and_tdc_t__dev_storage_tile_id_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_tile_id_t,
    muon_populate_hits::Parameters::dev_storage_tile_id_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t::type;
};
struct muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t,
    muon_populate_hits::Parameters::dev_storage_tdc_value_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t::type;
};
struct muon_populate_tile_and_tdc_t__dev_atomics_muon_t : muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t::type;
};
struct muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t
  : muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t::type;
};
struct muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t,
    muon_populate_hits::Parameters::dev_muon_compact_hit_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t::type;
};
struct muon_add_coords_crossing_maps_t__dev_muon_tile_used_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t::type;
};
struct muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t
  : muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t::type;
};
struct muon_station_ocurrence_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_hits::Parameters::host_muon_total_number_of_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
};
struct muon_station_ocurrence_prefix_sum__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
};
struct muon_station_ocurrence_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_hits::Parameters::dev_station_ocurrences_offset_t,
    is_muon::Parameters::dev_station_ocurrences_offset_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
};
struct muon_populate_hits_t__dev_permutation_station_t : muon_populate_hits::Parameters::dev_permutation_station_t {
  using type = muon_populate_hits::Parameters::dev_permutation_station_t::type;
};
struct muon_populate_hits_t__dev_muon_hits_t : muon_populate_hits::Parameters::dev_muon_hits_t,
                                               is_muon::Parameters::dev_muon_hits_t {
  using type = muon_populate_hits::Parameters::dev_muon_hits_t::type;
};
struct is_muon_t__dev_muon_track_occupancies_t : is_muon::Parameters::dev_muon_track_occupancies_t {
  using type = is_muon::Parameters::dev_muon_track_occupancies_t::type;
};
struct is_muon_t__dev_is_muon_t : is_muon::Parameters::dev_is_muon_t {
  using type = is_muon::Parameters::dev_is_muon_t::type;
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
  velo_kalman_filter__dev_velo_lmsfit_beamline_states_t,
  pv_beamline_extrapolate__dev_pvtracks_t,
  pv_beamline_extrapolate__dev_pvtrack_z_t,
  pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t,
  pv_beamline_histo__dev_zhisto_t,
  pv_beamline_peak__dev_zpeaks_t,
  pv_beamline_peak__dev_number_of_zpeaks_t,
  pv_beamline_calculate_denom__dev_pvtracks_denom_t,
  pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
  pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
  pv_beamline_cleanup__dev_multi_final_vertices_t,
  pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
  ut_banks__dev_raw_banks_t,
  ut_banks__dev_raw_offsets_t,
  ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
  prefix_sum_ut_hits__host_total_sum_holder_t,
  prefix_sum_ut_hits__host_output_buffer_t,
  prefix_sum_ut_hits__dev_output_buffer_t,
  ut_pre_decode__dev_ut_pre_decoded_hits_t,
  ut_pre_decode__dev_ut_hit_count_t,
  ut_find_permutation__dev_ut_hit_permutations_t,
  ut_decode_raw_banks_in_order__dev_ut_hits_t,
  ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
  ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
  ut_search_windows__dev_ut_windows_layers_t,
  ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
  ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
  compass_ut__dev_ut_tracks_t,
  compass_ut__dev_atomics_ut_t,
  prefix_sum_ut_tracks__host_total_sum_holder_t,
  prefix_sum_ut_tracks__host_output_buffer_t,
  prefix_sum_ut_tracks__dev_output_buffer_t,
  ut_copy_track_hit_number__dev_ut_track_hit_number_t,
  prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
  prefix_sum_ut_track_hit_number__host_output_buffer_t,
  prefix_sum_ut_track_hit_number__dev_output_buffer_t,
  ut_consolidate_tracks__dev_ut_track_hits_t,
  ut_consolidate_tracks__dev_ut_qop_t,
  ut_consolidate_tracks__dev_ut_x_t,
  ut_consolidate_tracks__dev_ut_tx_t,
  ut_consolidate_tracks__dev_ut_z_t,
  ut_consolidate_tracks__dev_ut_track_velo_indices_t,
  scifi_banks__dev_raw_banks_t,
  scifi_banks__dev_raw_offsets_t,
  scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t,
  prefix_sum_scifi_hits__host_total_sum_holder_t,
  prefix_sum_scifi_hits__host_output_buffer_t,
  prefix_sum_scifi_hits__dev_output_buffer_t,
  scifi_pre_decode_v4_t__dev_cluster_references_t,
  scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
  lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
  lf_search_initial_windows_t__dev_ut_states_t,
  lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
  lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
  lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t,
  lf_create_tracks_t__dev_scifi_lf_tracks_t,
  lf_create_tracks_t__dev_scifi_lf_atomics_t,
  lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t,
  lf_create_tracks_t__dev_scifi_lf_parametrization_t,
  lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
  lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
  lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t,
  lf_quality_filter_t__dev_lf_quality_of_tracks_t,
  lf_quality_filter_t__dev_atomics_scifi_t,
  lf_quality_filter_t__dev_scifi_tracks_t,
  lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t,
  lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t,
  prefix_sum_forward_tracks__host_total_sum_holder_t,
  prefix_sum_forward_tracks__host_output_buffer_t,
  prefix_sum_forward_tracks__dev_output_buffer_t,
  scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t,
  prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
  prefix_sum_scifi_track_hit_number__host_output_buffer_t,
  prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
  scifi_consolidate_tracks_t__dev_scifi_track_hits_t,
  scifi_consolidate_tracks_t__dev_scifi_qop_t,
  scifi_consolidate_tracks_t__dev_scifi_states_t,
  scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
  muon_banks__dev_raw_banks_t,
  muon_banks__dev_raw_offsets_t,
  muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
  muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t,
  muon_srq_prefix_sum__host_total_sum_holder_t,
  muon_srq_prefix_sum__host_output_buffer_t,
  muon_srq_prefix_sum__dev_output_buffer_t,
  muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
  muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
  muon_populate_tile_and_tdc_t__dev_atomics_muon_t,
  muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t,
  muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
  muon_add_coords_crossing_maps_t__dev_muon_tile_used_t,
  muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t,
  muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
  muon_station_ocurrence_prefix_sum__host_output_buffer_t,
  muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
  muon_populate_hits_t__dev_permutation_station_t,
  muon_populate_hits_t__dev_muon_hits_t,
  is_muon_t__dev_muon_track_occupancies_t,
  is_muon_t__dev_is_muon_t>;

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
  velo_kalman_filter::velo_kalman_filter_t,
  pv_beamline_extrapolate::pv_beamline_extrapolate_t,
  pv_beamline_histo::pv_beamline_histo_t,
  pv_beamline_peak::pv_beamline_peak_t,
  pv_beamline_calculate_denom::pv_beamline_calculate_denom_t,
  pv_beamline_multi_fitter::pv_beamline_multi_fitter_t,
  pv_beamline_cleanup::pv_beamline_cleanup_t,
  data_provider::data_provider_t,
  ut_calculate_number_of_hits::ut_calculate_number_of_hits_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_pre_decode::ut_pre_decode_t,
  ut_find_permutation::ut_find_permutation_t,
  ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_t,
  ut_select_velo_tracks::ut_select_velo_tracks_t,
  ut_search_windows::ut_search_windows_t,
  ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows_t,
  compass_ut::compass_ut_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_copy_track_hit_number::ut_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_consolidate_tracks::ut_consolidate_tracks_t,
  data_provider::data_provider_t,
  scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_pre_decode_v4::scifi_pre_decode_v4_t,
  scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_t,
  lf_search_initial_windows::lf_search_initial_windows_t,
  lf_triplet_seeding::lf_triplet_seeding_t,
  lf_create_tracks::lf_create_tracks_t,
  lf_quality_filter_length::lf_quality_filter_length_t,
  lf_quality_filter::lf_quality_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_copy_track_hit_number::scifi_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_consolidate_tracks::scifi_consolidate_tracks_t,
  data_provider::data_provider_t,
  muon_calculate_srq_size::muon_calculate_srq_size_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t,
  muon_add_coords_crossing_maps::muon_add_coords_crossing_maps_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_hits::muon_populate_hits_t,
  is_muon::is_muon_t>;

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
    velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_extrapolate__dev_pvtrack_z_t,
    pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_histo__dev_zhisto_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    pv_beamline_histo__dev_zhisto_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t,
    pv_beamline_calculate_denom__dev_pvtracks_denom_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_calculate_denom__dev_pvtracks_denom_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t,
    pv_beamline_extrapolate__dev_pvtrack_z_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t>,
  std::tuple<ut_banks__dev_raw_banks_t, ut_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
    prefix_sum_ut_hits__host_output_buffer_t,
    prefix_sum_ut_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_pre_decode__dev_ut_hit_count_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    initialize_lists__dev_event_list_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    ut_search_windows__dev_ut_windows_layers_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    ut_search_windows__dev_ut_windows_layers_t,
    initialize_lists__dev_event_list_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_lmsfit_beamline_states_t,
    ut_search_windows__dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
    initialize_lists__dev_event_list_t,
    compass_ut__dev_ut_tracks_t,
    compass_ut__dev_atomics_ut_t>,
  std::tuple<
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_atomics_ut_t,
    prefix_sum_ut_tracks__host_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_ut_tracks_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t>,
  std::tuple<
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t,
    prefix_sum_ut_track_hit_number__host_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    compass_ut__dev_ut_tracks_t,
    initialize_lists__dev_event_list_t,
    ut_consolidate_tracks__dev_ut_track_hits_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t>,
  std::tuple<scifi_banks__dev_raw_banks_t, scifi_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t>,
  std::tuple<
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t,
    prefix_sum_scifi_hits__host_output_buffer_t,
    prefix_sum_scifi_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode_v4_t__dev_cluster_references_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode_v4_t__dev_cluster_references_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
    lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
    lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_create_tracks_t__dev_scifi_lf_tracks_t,
    lf_create_tracks_t__dev_scifi_lf_atomics_t,
    lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t,
    lf_create_tracks_t__dev_scifi_lf_parametrization_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_create_tracks_t__dev_scifi_lf_tracks_t,
    lf_create_tracks_t__dev_scifi_lf_atomics_t,
    lf_create_tracks_t__dev_scifi_lf_parametrization_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_quality_filter_t__dev_lf_quality_of_tracks_t,
    lf_quality_filter_t__dev_atomics_scifi_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t,
    lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t>,
  std::tuple<
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    lf_quality_filter_t__dev_atomics_scifi_t,
    prefix_sum_forward_tracks__host_output_buffer_t,
    prefix_sum_forward_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t>,
  std::tuple<
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t,
    prefix_sum_scifi_track_hit_number__host_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks_t__dev_scifi_track_hits_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t>,
  std::tuple<muon_banks__dev_raw_banks_t, muon_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t>,
  std::tuple<
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t,
    muon_srq_prefix_sum__host_output_buffer_t,
    muon_srq_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
    muon_populate_tile_and_tdc_t__dev_atomics_muon_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    initialize_lists__dev_event_list_t,
    muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t,
    muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
    muon_add_coords_crossing_maps_t__dev_muon_tile_used_t,
    muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t>,
  std::tuple<
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t,
    muon_station_ocurrence_prefix_sum__host_output_buffer_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_hits_t__dev_permutation_station_t,
    muon_populate_hits_t__dev_muon_hits_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_populate_hits_t__dev_muon_hits_t,
    is_muon_t__dev_muon_track_occupancies_t,
    is_muon_t__dev_is_muon_t>>;

constexpr auto sequence_algorithm_names = std::array {"mep_layout",
                                                      "host_ut_banks",
                                                      "host_scifi_banks",
                                                      "initialize_lists",
                                                      "full_event_list",
                                                      "velo_banks",
                                                      "velo_calculate_number_of_candidates",
                                                      "prefix_sum_offsets_velo_candidates",
                                                      "velo_estimate_input_size",
                                                      "prefix_sum_offsets_estimated_input_size",
                                                      "velo_masked_clustering",
                                                      "velo_calculate_phi_and_sort",
                                                      "velo_search_by_triplet",
                                                      "prefix_sum_offsets_velo_tracks",
                                                      "velo_three_hit_tracks_filter",
                                                      "prefix_sum_offsets_number_of_three_hit_tracks_filtered",
                                                      "velo_copy_track_hit_number",
                                                      "prefix_sum_offsets_velo_track_hit_number",
                                                      "velo_consolidate_tracks",
                                                      "velo_kalman_filter",
                                                      "pv_beamline_extrapolate",
                                                      "pv_beamline_histo",
                                                      "pv_beamline_peak",
                                                      "pv_beamline_calculate_denom",
                                                      "pv_beamline_multi_fitter",
                                                      "pv_beamline_cleanup",
                                                      "ut_banks",
                                                      "ut_calculate_number_of_hits",
                                                      "prefix_sum_ut_hits",
                                                      "ut_pre_decode",
                                                      "ut_find_permutation",
                                                      "ut_decode_raw_banks_in_order",
                                                      "ut_select_velo_tracks",
                                                      "ut_search_windows",
                                                      "ut_select_velo_tracks_with_windows",
                                                      "compass_ut",
                                                      "prefix_sum_ut_tracks",
                                                      "ut_copy_track_hit_number",
                                                      "prefix_sum_ut_track_hit_number",
                                                      "ut_consolidate_tracks",
                                                      "scifi_banks",
                                                      "scifi_calculate_cluster_count_v4_t",
                                                      "prefix_sum_scifi_hits",
                                                      "scifi_pre_decode_v4_t",
                                                      "scifi_raw_bank_decoder_v4_t",
                                                      "lf_search_initial_windows_t",
                                                      "lf_triplet_seeding_t",
                                                      "lf_create_tracks_t",
                                                      "lf_quality_filter_length_t",
                                                      "lf_quality_filter_t",
                                                      "prefix_sum_forward_tracks",
                                                      "scifi_copy_track_hit_number_t",
                                                      "prefix_sum_scifi_track_hit_number",
                                                      "scifi_consolidate_tracks_t",
                                                      "muon_banks",
                                                      "muon_calculate_srq_size_t",
                                                      "muon_srq_prefix_sum",
                                                      "muon_populate_tile_and_tdc_t",
                                                      "muon_add_coords_crossing_maps_t",
                                                      "muon_station_ocurrence_prefix_sum",
                                                      "muon_populate_hits_t",
                                                      "is_muon_t"};

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
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtracks_t>(
    "pv_beamline_extrapolate__dev_pvtracks_t");
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtrack_z_t>(
    "pv_beamline_extrapolate__dev_pvtrack_z_t");
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t>(
    "pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t");
  argument_manager.template set_name<pv_beamline_histo__dev_zhisto_t>("pv_beamline_histo__dev_zhisto_t");
  argument_manager.template set_name<pv_beamline_peak__dev_zpeaks_t>("pv_beamline_peak__dev_zpeaks_t");
  argument_manager.template set_name<pv_beamline_peak__dev_number_of_zpeaks_t>(
    "pv_beamline_peak__dev_number_of_zpeaks_t");
  argument_manager.template set_name<pv_beamline_calculate_denom__dev_pvtracks_denom_t>(
    "pv_beamline_calculate_denom__dev_pvtracks_denom_t");
  argument_manager.template set_name<pv_beamline_multi_fitter__dev_multi_fit_vertices_t>(
    "pv_beamline_multi_fitter__dev_multi_fit_vertices_t");
  argument_manager.template set_name<pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t>(
    "pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t");
  argument_manager.template set_name<pv_beamline_cleanup__dev_multi_final_vertices_t>(
    "pv_beamline_cleanup__dev_multi_final_vertices_t");
  argument_manager.template set_name<pv_beamline_cleanup__dev_number_of_multi_final_vertices_t>(
    "pv_beamline_cleanup__dev_number_of_multi_final_vertices_t");
  argument_manager.template set_name<ut_banks__dev_raw_banks_t>("ut_banks__dev_raw_banks_t");
  argument_manager.template set_name<ut_banks__dev_raw_offsets_t>("ut_banks__dev_raw_offsets_t");
  argument_manager.template set_name<ut_calculate_number_of_hits__dev_ut_hit_sizes_t>(
    "ut_calculate_number_of_hits__dev_ut_hit_sizes_t");
  argument_manager.template set_name<prefix_sum_ut_hits__host_total_sum_holder_t>(
    "prefix_sum_ut_hits__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_hits__host_output_buffer_t>(
    "prefix_sum_ut_hits__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_hits__dev_output_buffer_t>(
    "prefix_sum_ut_hits__dev_output_buffer_t");
  argument_manager.template set_name<ut_pre_decode__dev_ut_pre_decoded_hits_t>(
    "ut_pre_decode__dev_ut_pre_decoded_hits_t");
  argument_manager.template set_name<ut_pre_decode__dev_ut_hit_count_t>("ut_pre_decode__dev_ut_hit_count_t");
  argument_manager.template set_name<ut_find_permutation__dev_ut_hit_permutations_t>(
    "ut_find_permutation__dev_ut_hit_permutations_t");
  argument_manager.template set_name<ut_decode_raw_banks_in_order__dev_ut_hits_t>(
    "ut_decode_raw_banks_in_order__dev_ut_hits_t");
  argument_manager.template set_name<ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t>(
    "ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t");
  argument_manager.template set_name<ut_select_velo_tracks__dev_ut_selected_velo_tracks_t>(
    "ut_select_velo_tracks__dev_ut_selected_velo_tracks_t");
  argument_manager.template set_name<ut_search_windows__dev_ut_windows_layers_t>(
    "ut_search_windows__dev_ut_windows_layers_t");
  argument_manager
    .template set_name<ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t>(
      "ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t");
  argument_manager.template set_name<ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t>(
    "ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t");
  argument_manager.template set_name<compass_ut__dev_ut_tracks_t>("compass_ut__dev_ut_tracks_t");
  argument_manager.template set_name<compass_ut__dev_atomics_ut_t>("compass_ut__dev_atomics_ut_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__host_total_sum_holder_t>(
    "prefix_sum_ut_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__host_output_buffer_t>(
    "prefix_sum_ut_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__dev_output_buffer_t>(
    "prefix_sum_ut_tracks__dev_output_buffer_t");
  argument_manager.template set_name<ut_copy_track_hit_number__dev_ut_track_hit_number_t>(
    "ut_copy_track_hit_number__dev_ut_track_hit_number_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_ut_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__host_output_buffer_t>(
    "prefix_sum_ut_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_ut_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_track_hits_t>(
    "ut_consolidate_tracks__dev_ut_track_hits_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_qop_t>("ut_consolidate_tracks__dev_ut_qop_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_x_t>("ut_consolidate_tracks__dev_ut_x_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_tx_t>("ut_consolidate_tracks__dev_ut_tx_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_z_t>("ut_consolidate_tracks__dev_ut_z_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_track_velo_indices_t>(
    "ut_consolidate_tracks__dev_ut_track_velo_indices_t");
  argument_manager.template set_name<scifi_banks__dev_raw_banks_t>("scifi_banks__dev_raw_banks_t");
  argument_manager.template set_name<scifi_banks__dev_raw_offsets_t>("scifi_banks__dev_raw_offsets_t");
  argument_manager.template set_name<scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t>(
    "scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__host_total_sum_holder_t>(
    "prefix_sum_scifi_hits__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__host_output_buffer_t>(
    "prefix_sum_scifi_hits__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__dev_output_buffer_t>(
    "prefix_sum_scifi_hits__dev_output_buffer_t");
  argument_manager.template set_name<scifi_pre_decode_v4_t__dev_cluster_references_t>(
    "scifi_pre_decode_v4_t__dev_cluster_references_t");
  argument_manager.template set_name<scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t>(
    "scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t");
  argument_manager.template set_name<lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t>(
    "lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t");
  argument_manager.template set_name<lf_search_initial_windows_t__dev_ut_states_t>(
    "lf_search_initial_windows_t__dev_ut_states_t");
  argument_manager.template set_name<lf_search_initial_windows_t__dev_scifi_lf_process_track_t>(
    "lf_search_initial_windows_t__dev_scifi_lf_process_track_t");
  argument_manager.template set_name<lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t>(
    "lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t");
  argument_manager.template set_name<lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t>(
    "lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t");
  argument_manager.template set_name<lf_create_tracks_t__dev_scifi_lf_tracks_t>(
    "lf_create_tracks_t__dev_scifi_lf_tracks_t");
  argument_manager.template set_name<lf_create_tracks_t__dev_scifi_lf_atomics_t>(
    "lf_create_tracks_t__dev_scifi_lf_atomics_t");
  argument_manager.template set_name<lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t>(
    "lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t");
  argument_manager.template set_name<lf_create_tracks_t__dev_scifi_lf_parametrization_t>(
    "lf_create_tracks_t__dev_scifi_lf_parametrization_t");
  argument_manager.template set_name<lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t>(
    "lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t");
  argument_manager.template set_name<lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t>(
    "lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t");
  argument_manager.template set_name<lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t>(
    "lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t");
  argument_manager.template set_name<lf_quality_filter_t__dev_lf_quality_of_tracks_t>(
    "lf_quality_filter_t__dev_lf_quality_of_tracks_t");
  argument_manager.template set_name<lf_quality_filter_t__dev_atomics_scifi_t>(
    "lf_quality_filter_t__dev_atomics_scifi_t");
  argument_manager.template set_name<lf_quality_filter_t__dev_scifi_tracks_t>(
    "lf_quality_filter_t__dev_scifi_tracks_t");
  argument_manager.template set_name<lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t>(
    "lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t");
  argument_manager.template set_name<lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t>(
    "lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__host_total_sum_holder_t>(
    "prefix_sum_forward_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__host_output_buffer_t>(
    "prefix_sum_forward_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__dev_output_buffer_t>(
    "prefix_sum_forward_tracks__dev_output_buffer_t");
  argument_manager.template set_name<scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t>(
    "scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_scifi_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__host_output_buffer_t>(
    "prefix_sum_scifi_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_scifi_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<scifi_consolidate_tracks_t__dev_scifi_track_hits_t>(
    "scifi_consolidate_tracks_t__dev_scifi_track_hits_t");
  argument_manager.template set_name<scifi_consolidate_tracks_t__dev_scifi_qop_t>(
    "scifi_consolidate_tracks_t__dev_scifi_qop_t");
  argument_manager.template set_name<scifi_consolidate_tracks_t__dev_scifi_states_t>(
    "scifi_consolidate_tracks_t__dev_scifi_states_t");
  argument_manager.template set_name<scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t>(
    "scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t");
  argument_manager.template set_name<muon_banks__dev_raw_banks_t>("muon_banks__dev_raw_banks_t");
  argument_manager.template set_name<muon_banks__dev_raw_offsets_t>("muon_banks__dev_raw_offsets_t");
  argument_manager.template set_name<muon_calculate_srq_size_t__dev_muon_raw_to_hits_t>(
    "muon_calculate_srq_size_t__dev_muon_raw_to_hits_t");
  argument_manager.template set_name<muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t>(
    "muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t");
  argument_manager.template set_name<muon_srq_prefix_sum__host_total_sum_holder_t>(
    "muon_srq_prefix_sum__host_total_sum_holder_t");
  argument_manager.template set_name<muon_srq_prefix_sum__host_output_buffer_t>(
    "muon_srq_prefix_sum__host_output_buffer_t");
  argument_manager.template set_name<muon_srq_prefix_sum__dev_output_buffer_t>(
    "muon_srq_prefix_sum__dev_output_buffer_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc_t__dev_storage_tile_id_t>(
    "muon_populate_tile_and_tdc_t__dev_storage_tile_id_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t>(
    "muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc_t__dev_atomics_muon_t>(
    "muon_populate_tile_and_tdc_t__dev_atomics_muon_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t>(
    "muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t>(
    "muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps_t__dev_muon_tile_used_t>(
    "muon_add_coords_crossing_maps_t__dev_muon_tile_used_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t>(
    "muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__host_total_sum_holder_t>(
    "muon_station_ocurrence_prefix_sum__host_total_sum_holder_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__host_output_buffer_t>(
    "muon_station_ocurrence_prefix_sum__host_output_buffer_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__dev_output_buffer_t>(
    "muon_station_ocurrence_prefix_sum__dev_output_buffer_t");
  argument_manager.template set_name<muon_populate_hits_t__dev_permutation_station_t>(
    "muon_populate_hits_t__dev_permutation_station_t");
  argument_manager.template set_name<muon_populate_hits_t__dev_muon_hits_t>("muon_populate_hits_t__dev_muon_hits_t");
  argument_manager.template set_name<is_muon_t__dev_muon_track_occupancies_t>(
    "is_muon_t__dev_muon_track_occupancies_t");
  argument_manager.template set_name<is_muon_t__dev_is_muon_t>("is_muon_t__dev_is_muon_t");
}
