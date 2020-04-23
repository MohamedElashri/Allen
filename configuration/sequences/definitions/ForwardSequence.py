from definitions.algorithms import *


def ForwardSequence(forward_decoding="v4"):
    algorithms = []

    dev_scifi_hits = None
    dev_scifi_hit_offsets = None

    if forward_decoding == "v4":
        scifi_calculate_cluster_count_v4 = scifi_calculate_cluster_count_v4_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_event_list_t = initialize_lists.dev_event_list_t)

        prefix_sum_scifi_hits = host_prefix_sum_t(
            "prefix_sum_scifi_hits",
            dev_input_buffer_t=scifi_calculate_cluster_count_v4.dev_scifi_hit_count_t)

        scifi_pre_decode_v4 = scifi_pre_decode_v4_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_event_list_t = initialize_lists.dev_event_list_t,
            host_accumulated_number_of_scifi_hits_t = prefix_sum_scifi_hits.host_total_sum_holder_t,
            dev_scifi_raw_input_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_t,
            dev_scifi_raw_input_offsets_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_offsets_t,
            dev_scifi_hit_offsets_t = prefix_sum_scifi_hits.dev_output_buffer_t)

        scifi_raw_bank_decoder_v4 = scifi_raw_bank_decoder_v4_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_scifi_raw_input_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_t,
            dev_scifi_raw_input_offsets_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_offsets_t,
            dev_scifi_hit_offsets_t = prefix_sum_scifi_hits.dev_output_buffer_t,
            dev_event_list_t = initialize_lists.dev_event_list_t)

        scifi_direct_decoder_v4 = scifi_direct_decoder_v4_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_scifi_raw_input_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_t,
            dev_scifi_raw_input_offsets_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_offsets_t,
            dev_scifi_hit_offsets_t = prefix_sum_scifi_hits.dev_output_buffer_t,
            dev_event_list_t = initialize_lists.dev_event_list_t)

        dev_scifi_hits = scifi_direct_decoder_v4.dev_scifi_hits_t
        dev_scifi_hit_offsets = prefix_sum_scifi_hits.dev_output_buffer_t

        algorithms += [scifi_calculate_cluster_count_v4, prefix_sum_scifi_hits, scifi_pre_decode_v4,
            scifi_raw_bank_decoder_v4, scifi_direct_decoder_v4]
    elif forward_decoding == "v6":
        scifi_calculate_cluster_count_v6 = scifi_calculate_cluster_count_v6_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_event_list_t = initialize_lists.dev_event_list_t)

        prefix_sum_scifi_hits = host_prefix_sum_t(
            "prefix_sum_scifi_hits",
            dev_input_buffer_t=scifi_calculate_cluster_count_v6.
            dev_scifi_hit_count_t())

        scifi_pre_decode_v6 = scifi_pre_decode_v6_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_event_list_t = initialize_lists.dev_event_list_t,
            host_accumulated_number_of_scifi_hits_t = prefix_sum_scifi_hits.host_total_sum_holder_t,
            dev_scifi_raw_input_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_t,
            dev_scifi_raw_input_offsets_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_offsets_t,
            dev_scifi_hit_offsets_t = prefix_sum_scifi_hits.dev_output_buffer_t)

        scifi_raw_bank_decoder_v6 = scifi_raw_bank_decoder_v6_t(
            host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
            dev_scifi_raw_input_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_t,
            dev_scifi_raw_input_offsets_t = scifi_calculate_cluster_count_v4.dev_scifi_raw_input_offsets_t,
            dev_scifi_hit_offsets_t = prefix_sum_scifi_hits.dev_output_buffer_t,
            dev_event_list_t = initialize_lists.dev_event_list_t)

        dev_scifi_hits = scifi_raw_bank_decoder_v6.dev_scifi_hits_t
        dev_scifi_hit_offsets = prefix_sum_scifi_hits.dev_output_buffer_t

        algorithms += [scifi_calculate_cluster_count_v6, prefix_sum_scifi_hits, scifi_pre_decode_v6,
            scifi_raw_bank_decoder_v6]

    lf_search_initial_windows = lf_search_initial_windows_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        dev_event_list_t = initialize_lists.dev_event_list_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_all_velo_tracks_t = velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t = prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        dev_velo_states_t = velo_consolidate_tracks.dev_velo_states_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_ut_x_t = ut_consolidate_tracks.dev_ut_x_t,
        dev_ut_tx_t = ut_consolidate_tracks.dev_ut_tx_t,
        dev_ut_z_t = ut_consolidate_tracks.dev_ut_z_t,
        dev_ut_qop_t = ut_consolidate_tracks.dev_ut_qop_t,
        dev_ut_track_velo_indices_t = ut_consolidate_tracks.dev_ut_track_velo_indices_t)

    lf_triplet_seeding = lf_triplet_seeding_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_all_velo_tracks_t = velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        dev_velo_states_t = velo_consolidate_tracks.dev_velo_states_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_ut_track_velo_indices_t = ut_consolidate_tracks.dev_ut_track_velo_indices_t,
        dev_ut_qop_t = ut_consolidate_tracks.dev_ut_qop_t,
        dev_scifi_lf_initial_windows_t = lf_search_initial_windows.dev_scifi_lf_initial_windows_t,
        dev_ut_states_t = lf_search_initial_windows.dev_ut_states_t,
        dev_scifi_lf_process_track_t = lf_search_initial_windows.dev_scifi_lf_process_track_t)

    lf_triplet_keep_best = lf_triplet_keep_best_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_lf_initial_windows_t = lf_search_initial_windows.dev_scifi_lf_initial_windows_t,
        dev_scifi_lf_process_track_t = lf_search_initial_windows.dev_scifi_lf_process_track_t,
        dev_scifi_lf_found_triplets_t = lf_triplet_seeding.dev_scifi_lf_found_triplets_t,
        dev_scifi_lf_number_of_found_triplets_t = lf_triplet_seeding.dev_scifi_lf_number_of_found_triplets_t)

    lf_calculate_parametrization = lf_calculate_parametrization_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_all_velo_tracks_t = velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t = prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        dev_velo_states_t = velo_consolidate_tracks.dev_velo_states_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_ut_track_velo_indices_t = ut_consolidate_tracks.dev_ut_track_velo_indices_t,
        dev_ut_qop_t = ut_consolidate_tracks.dev_ut_qop_t,
        dev_scifi_lf_tracks_t = lf_triplet_keep_best.dev_scifi_lf_tracks_t,
        dev_scifi_lf_atomics_t = lf_triplet_keep_best.dev_scifi_lf_atomics_t)

    lf_extend_tracks_x = lf_extend_tracks_x_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_lf_atomics_t = lf_triplet_keep_best.dev_scifi_lf_atomics_t,
        dev_scifi_lf_initial_windows_t = lf_search_initial_windows.dev_scifi_lf_initial_windows_t,
        dev_scifi_lf_parametrization_t = lf_calculate_parametrization.dev_scifi_lf_parametrization_t)

    lf_extend_tracks_uv = lf_extend_tracks_uv_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_lf_atomics_t = lf_triplet_keep_best.dev_scifi_lf_atomics_t,
        dev_ut_states_t = lf_search_initial_windows.dev_ut_states_t,
        dev_scifi_lf_initial_windows_t = lf_search_initial_windows.dev_scifi_lf_initial_windows_t,
        dev_scifi_lf_parametrization_t = lf_calculate_parametrization.dev_scifi_lf_parametrization_t)

    lf_quality_filter_length = lf_quality_filter_length_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_lf_atomics_t = lf_triplet_keep_best.dev_scifi_lf_atomics_t,
        dev_scifi_lf_parametrization_t = lf_calculate_parametrization.dev_scifi_lf_parametrization_t)
    
    lf_quality_filter = lf_quality_filter_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_ut_tracks_t = prefix_sum_ut_tracks.host_total_sum_holder_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_lf_length_filtered_atomics_t = lf_quality_filter_length.dev_scifi_lf_length_filtered_atomics_t,
        dev_scifi_lf_parametrization_length_filter_t = lf_quality_filter_length.dev_scifi_lf_parametrization_length_filter_t,
        dev_ut_states_t = lf_search_initial_windows.dev_ut_states_t,
        dev_velo_states_t = velo_consolidate_tracks.dev_velo_states_t,
        dev_offsets_all_velo_tracks_t = velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t = prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        dev_ut_track_velo_indices_t = ut_consolidate_tracks.dev_ut_track_velo_indices_t)

    prefix_sum_forward_tracks = host_prefix_sum_t(
        "prefix_sum_forward_tracks",
        dev_input_buffer_t=lf_quality_filter.dev_atomics_scifi_t())

    scifi_copy_track_hit_number = scifi_copy_track_hit_number_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_number_of_reconstructed_scifi_tracks_t = prefix_sum_forward_tracks.host_total_sum_holder_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_scifi_tracks_t = lf_quality_filter.dev_scifi_tracks_t,
        dev_offsets_forward_tracks_t = prefix_sum_forward_tracks.dev_output_buffer_t)

    prefix_sum_scifi_track_hit_number = host_prefix_sum_t(
        "prefix_sum_scifi_track_hit_number",
        host_total_sum_holder_t=
        "host_accumulated_number_of_hits_in_scifi_tracks_t",
        dev_input_buffer_t=scifi_copy_track_hit_number.
        dev_scifi_track_hit_number_t(),
        dev_output_buffer_t="dev_offsets_scifi_track_hit_number")

    scifi_consolidate_tracks = scifi_consolidate_tracks_t(
        host_number_of_selected_events_t = initialize_lists.host_number_of_selected_events_t,
        host_accumulated_number_of_hits_in_scifi_tracks_t = prefix_sum_scifi_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_scifi_tracks_t = prefix_sum_forward_tracks.host_total_sum_holder_t,
        dev_scifi_hits_t = dev_scifi_hits,
        dev_scifi_hit_offsets_t = dev_scifi_hit_offsets,
        dev_offsets_forward_tracks_t = prefix_sum_forward_tracks.dev_output_buffer_t,
        dev_offsets_scifi_track_hit_number = prefix_sum_scifi_track_hit_number.dev_output_buffer_t,
        dev_offsets_ut_tracks_t = prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t = prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        dev_scifi_tracks_t = lf_quality_filter.dev_scifi_tracks_t,
        dev_scifi_lf_parametrization_consolidate_t = lf_quality_filter.dev_scifi_lf_parametrization_consolidate_t)

    algorithms += [lf_search_initial_windows, lf_triplet_seeding, lf_triplet_keep_best, lf_calculate_parametrization,
        lf_extend_tracks_x, lf_extend_tracks_uv, lf_quality_filter_length, lf_quality_filter, prefix_sum_forward_tracks,
        scifi_copy_track_hit_number, prefix_sum_scifi_track_hit_number, scifi_consolidate_tracks]

    forward_sequence = Sequence(algorithms)
    return forward_sequence
