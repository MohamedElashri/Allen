###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *


def VeloSequence(doGEC=True):
    mep_layout = layout_provider_t(name="mep_layout")

    host_ut_banks = host_data_provider_t(name="host_ut_banks", bank_type="UT")

    host_scifi_banks = host_data_provider_t(
        name="host_scifi_banks", bank_type="FTCluster")

    initialize_lists = None
    if doGEC:
        initialize_lists = host_global_event_cut_t(
            name="initialize_lists",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())
    else:
        initialize_lists = host_init_event_list_t(
            name="initialize_lists",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())

    full_event_list = host_init_event_list_t(
        name="full_event_list",
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())

    velo_banks = data_provider_t(name="velo_banks", bank_type="VP")

    velo_calculate_number_of_candidates = velo_calculate_number_of_candidates_t(
        name="velo_calculate_number_of_candidates",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t())

    prefix_sum_offsets_velo_candidates = host_prefix_sum_t(
        name="prefix_sum_offsets_velo_candidates",
        dev_input_buffer_t=velo_calculate_number_of_candidates.
        dev_number_of_candidates_t())

    velo_estimate_input_size = velo_estimate_input_size_t(
        name="velo_estimate_input_size",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_cluster_candidates_t=prefix_sum_offsets_velo_candidates.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
        dev_output_buffer_t(),
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t())

    prefix_sum_offsets_estimated_input_size = host_prefix_sum_t(
        name="prefix_sum_offsets_estimated_input_size",
        dev_input_buffer_t=velo_estimate_input_size.
        dev_estimated_input_size_t())

    velo_masked_clustering = velo_masked_clustering_t(
        name="velo_masked_clustering",
        host_total_number_of_velo_clusters_t=
        prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t(),
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
        dev_module_candidate_num_t=velo_estimate_input_size.
        dev_module_candidate_num_t(),
        dev_cluster_candidates_t=velo_estimate_input_size.
        dev_cluster_candidates_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
        dev_output_buffer_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    velo_calculate_phi_and_sort = velo_calculate_phi_and_sort_t(
        name="velo_calculate_phi_and_sort",
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_total_number_of_velo_clusters_t=
        prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t(),
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
        dev_module_cluster_num_t=velo_masked_clustering.
        dev_module_cluster_num_t(),
        dev_velo_cluster_container_t=velo_masked_clustering.
        dev_velo_cluster_container_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    velo_search_by_triplet = velo_search_by_triplet_t(
        name="velo_search_by_triplet",
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_total_number_of_velo_clusters_t=
        prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t(),
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t(),
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
        dev_module_cluster_num_t=velo_masked_clustering.
        dev_module_cluster_num_t(),
        dev_hit_phi_t=velo_calculate_phi_and_sort.dev_hit_phi_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    prefix_sum_offsets_velo_tracks = host_prefix_sum_t(
        name="prefix_sum_offsets_velo_tracks",
        dev_input_buffer_t=velo_search_by_triplet.
        dev_number_of_velo_tracks_t())

    velo_three_hit_tracks_filter = velo_three_hit_tracks_filter_t(
        name="velo_three_hit_tracks_filter",
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t(),
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
        dev_atomics_velo_t=velo_search_by_triplet.dev_atomics_velo_t(),
        dev_hit_used_t=velo_search_by_triplet.dev_hit_used_t(),
        dev_three_hit_tracks_input_t=velo_search_by_triplet.
        dev_three_hit_tracks_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    prefix_sum_offsets_number_of_three_hit_tracks_filtered = host_prefix_sum_t(
        name="prefix_sum_offsets_number_of_three_hit_tracks_filtered",
        dev_input_buffer_t=velo_three_hit_tracks_filter.
        dev_number_of_three_hit_tracks_output_t())

    velo_copy_track_hit_number = velo_copy_track_hit_number_t(
        name="velo_copy_track_hit_number",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_velo_tracks_at_least_four_hits_t=
        prefix_sum_offsets_velo_tracks.host_total_sum_holder_t(),
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t(),
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t(),
        dev_offsets_velo_tracks_t=prefix_sum_offsets_velo_tracks.
        dev_output_buffer_t(),
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t())

    prefix_sum_offsets_velo_track_hit_number = host_prefix_sum_t(
        name="prefix_sum_offsets_velo_track_hit_number",
        dev_input_buffer_t=velo_copy_track_hit_number.
        dev_velo_track_hit_number_t())

    velo_consolidate_tracks = velo_consolidate_tracks_t(
        name="velo_consolidate_tracks",
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        host_accumulated_number_of_hits_in_velo_tracks_t=
        prefix_sum_offsets_velo_track_hit_number.host_total_sum_holder_t(),
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t(),
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
        dev_three_hit_tracks_output_t=velo_three_hit_tracks_filter.
        dev_three_hit_tracks_output_t(),
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    velo_kalman_filter = velo_kalman_filter_t(
        name="velo_kalman_filter",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_velo_track_hits_t=velo_consolidate_tracks.dev_velo_track_hits_t())

    velo_kalman_filter = velo_kalman_filter_t(
        name="velo_kalman_filter",
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_velo_track_hits_t=velo_consolidate_tracks.dev_velo_track_hits_t())

    velo_sequence = Sequence(
        mep_layout, host_ut_banks, host_scifi_banks, initialize_lists,
        full_event_list, velo_banks, velo_calculate_number_of_candidates,
        prefix_sum_offsets_velo_candidates, velo_estimate_input_size,
        prefix_sum_offsets_estimated_input_size, velo_masked_clustering,
        velo_calculate_phi_and_sort, velo_search_by_triplet,
        prefix_sum_offsets_velo_tracks, velo_three_hit_tracks_filter,
        prefix_sum_offsets_number_of_three_hit_tracks_filtered,
        velo_copy_track_hit_number, prefix_sum_offsets_velo_track_hit_number,
        velo_consolidate_tracks, velo_kalman_filter)

    return velo_sequence
