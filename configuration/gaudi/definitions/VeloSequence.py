###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from PyConf.components import Algorithm
from algorithms import *


def initialize_lists(doGEC=True, **kwargs):
    host_ut_banks = Algorithm(
        host_data_provider_t, name="host_ut_banks", bank_type="UT")

    host_scifi_banks = Algorithm(
        host_data_provider_t, name="host_scifi_banks", bank_type="FTCluster")

    initialize_lists = None
    if doGEC:
        initialize_lists = Algorithm(
            host_global_event_cut_t,
            name="global_event_cut",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t)
    else:
        initialize_lists = Algorithm(
            host_init_event_list_t,
            name="initialize_lists",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t)

    return {
        "host_number_of_selected_events":
        initialize_lists.host_number_of_selected_events_t,
        "dev_event_list":
        initialize_lists.dev_event_list_t
    }


def decode_velo(**kwargs):
    initalized_lists = initialize_lists(**kwargs)
    host_number_of_selected_events = initalized_lists[
        "host_number_of_selected_events"]
    dev_event_list = initalized_lists["dev_event_list"]

    velo_banks = Algorithm(data_provider_t, name="velo_banks", bank_type="VP")

    velo_calculate_number_of_candidates = Algorithm(
        velo_calculate_number_of_candidates_t,
        name="velo_calculate_number_of_candidates",
        host_number_of_selected_events_t=host_number_of_selected_events,
        dev_event_list_t=dev_event_list,
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t)

    prefix_sum_offsets_velo_candidates = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_velo_candidates",
        dev_input_buffer_t=velo_calculate_number_of_candidates.
        dev_number_of_candidates_t)

    velo_estimate_input_size = Algorithm(
        velo_estimate_input_size_t,
        name="velo_estimate_input_size",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_number_of_cluster_candidates_t=prefix_sum_offsets_velo_candidates.
        host_total_sum_holder_t,
        dev_event_list_t=dev_event_list,
        dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
        dev_output_buffer_t,
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t)

    prefix_sum_offsets_estimated_input_size = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_estimated_input_size",
        dev_input_buffer_t=velo_estimate_input_size.dev_estimated_input_size_t)

    velo_masked_clustering = Algorithm(
        velo_masked_clustering_t,
        name="velo_masked_clustering",
        host_total_number_of_velo_clusters_t=
        prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
        host_number_of_selected_events_t=host_number_of_selected_events,
        dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
        dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
        dev_offsets_estimated_input_size_t=
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
        dev_module_candidate_num_t=velo_estimate_input_size.
        dev_module_candidate_num_t,
        dev_cluster_candidates_t=velo_estimate_input_size.
        dev_cluster_candidates_t,
        dev_event_list_t=dev_event_list,
        dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
        dev_output_buffer_t)

    return {
        "dev_velo_cluster_container":
        velo_masked_clustering.dev_velo_cluster_container_t,
        "dev_module_cluster_num":
        velo_masked_clustering.dev_module_cluster_num_t,
        "dev_offsets_estimated_input_size":
        prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
        "host_total_number_of_velo_clusters":
        prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t
    }


def make_velo_tracks(**kwargs):
    initalized_lists = initialize_lists(**kwargs)
    host_number_of_selected_events = initalized_lists[
        "host_number_of_selected_events"]
    dev_event_list = initalized_lists["dev_event_list"]

    decoded_velo = decode_velo(**kwargs)
    dev_velo_cluster_container = decoded_velo["dev_velo_cluster_container"]
    dev_module_cluster_num = decoded_velo["dev_module_cluster_num"]
    dev_offsets_estimated_input_size = decoded_velo[
        "dev_offsets_estimated_input_size"]
    host_total_number_of_velo_clusters = decoded_velo[
        "host_total_number_of_velo_clusters"]

    velo_calculate_phi_and_sort = Algorithm(
        velo_calculate_phi_and_sort_t,
        name="velo_calculate_phi_and_sort",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_module_cluster_num_t=dev_module_cluster_num,
        dev_velo_cluster_container_t=dev_velo_cluster_container)

    velo_search_by_triplet = Algorithm(
        velo_search_by_triplet_t,
        name="velo_search_by_triplet",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_module_cluster_num_t=dev_module_cluster_num,
        dev_hit_phi_t=velo_calculate_phi_and_sort.dev_hit_phi_t)

    prefix_sum_offsets_velo_tracks = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_velo_tracks",
        dev_input_buffer_t=velo_search_by_triplet.dev_number_of_velo_tracks_t)

    velo_three_hit_tracks_filter = Algorithm(
        velo_three_hit_tracks_filter_t,
        name="velo_three_hit_tracks_filter",
        host_number_of_selected_events_t=host_number_of_selected_events,
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_atomics_velo_t=velo_search_by_triplet.dev_atomics_velo_t,
        dev_hit_used_t=velo_search_by_triplet.dev_hit_used_t,
        dev_three_hit_tracks_input_t=velo_search_by_triplet.
        dev_three_hit_tracks_t)

    prefix_sum_offsets_number_of_three_hit_tracks_filtered = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_number_of_three_hit_tracks_filtered",
        dev_input_buffer_t=velo_three_hit_tracks_filter.
        dev_number_of_three_hit_tracks_output_t)

    velo_copy_track_hit_number = Algorithm(
        velo_copy_track_hit_number_t,
        name="velo_copy_track_hit_number",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_number_of_velo_tracks_at_least_four_hits_t=
        prefix_sum_offsets_velo_tracks.host_total_sum_holder_t,
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t,
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t,
        dev_offsets_velo_tracks_t=prefix_sum_offsets_velo_tracks.
        dev_output_buffer_t,
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t)

    prefix_sum_offsets_velo_track_hit_number = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_velo_track_hit_number",
        dev_input_buffer_t=velo_copy_track_hit_number.
        dev_velo_track_hit_number_t)

    velo_consolidate_tracks = Algorithm(
        velo_consolidate_tracks_t,
        name="velo_consolidate_tracks",
        host_accumulated_number_of_hits_in_velo_tracks_t=
        prefix_sum_offsets_velo_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t,
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t,
        host_number_of_selected_events_t=host_number_of_selected_events,
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t,
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t,
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        dev_sorted_velo_cluster_container_t=velo_calculate_phi_and_sort.
        dev_sorted_velo_cluster_container_t,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=velo_three_hit_tracks_filter.
        dev_three_hit_tracks_output_t,
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t)

    return {
        "host_number_of_reconstructed_velo_tracks":
        velo_copy_track_hit_number.host_number_of_reconstructed_velo_tracks_t,
        "dev_velo_track_hits":
        velo_consolidate_tracks.dev_velo_track_hits_t,
        "dev_velo_states":
        velo_consolidate_tracks.dev_velo_states_t,
        "dev_offsets_all_velo_tracks":
        velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        "dev_offsets_velo_track_hit_number":
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        "dev_accepted_velo_tracks":
        velo_consolidate_tracks.dev_accepted_velo_tracks_t
    }
