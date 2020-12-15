###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from PyConf.components import Algorithm
from algorithms import *
from VeloSequence import initialize_lists, make_velo_tracks
from UTSequence import make_ut_tracks


def make_forward_tracks(forward_decoding="v4", **kwargs):

    initalized_lists = initialize_lists(**kwargs)
    host_number_of_events = initalized_lists["host_number_of_events"]
    dev_event_list = initalized_lists["dev_event_list"]

    velo_tracks = make_velo_tracks(**kwargs)
    host_number_of_reconstructed_velo_tracks = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_velo_states = velo_tracks["dev_velo_states"]
    dev_offsets_all_velo_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    dev_accepted_velo_tracks = velo_tracks["dev_accepted_velo_tracks"]

    ut_tracks = make_ut_tracks(**kwargs)
    dev_ut_track_hits = ut_tracks["dev_ut_track_hits"]
    host_number_of_reconstructed_ut_tracks = ut_tracks[
        "host_number_of_reconstructed_ut_tracks"]
    dev_offsets_ut_tracks = ut_tracks["dev_offsets_ut_tracks"]
    dev_offsets_ut_track_hit_number = ut_tracks[
        "dev_offsets_ut_track_hit_number"]
    dev_ut_track_velo_indices = ut_tracks["dev_ut_track_velo_indices"]
    dev_ut_x = ut_tracks["dev_ut_x"]
    dev_ut_tx = ut_tracks["dev_ut_tx"]
    dev_ut_z = ut_tracks["dev_ut_z"]
    dev_ut_qop = ut_tracks["dev_ut_qop"]

    scifi_banks = Algorithm(
        data_provider_t, name="scifi_banks", bank_type="FTCluster")

    scifi_calculate_cluster_count_algorithm = None
    scifi_pre_decode_algorithm = None
    scifi_raw_bank_decoder_algorithm = None

    if forward_decoding == "v4":
        scifi_calculate_cluster_count_algorithm = scifi_calculate_cluster_count_v4_t
        scifi_pre_decode_algorithm = scifi_pre_decode_v4_t
        scifi_raw_bank_decoder_algorithm = scifi_raw_bank_decoder_v4_t
    elif forward_decoding == "v6":
        scifi_calculate_cluster_count_algorithm = scifi_calculate_cluster_count_v6_t
        scifi_pre_decode_algorithm = scifi_pre_decode_v6_t
        scifi_raw_bank_decoder_algorithm = scifi_raw_bank_decoder_v6_t
    else:
        raise

    scifi_calculate_cluster_count = Algorithm(
        scifi_calculate_cluster_count_algorithm,
        name="scifi_calculate_cluster_count",
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        host_number_of_events_t=host_number_of_events,
        dev_event_list_t=dev_event_list)

    prefix_sum_scifi_hits = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_scifi_hits",
        dev_input_buffer_t=scifi_calculate_cluster_count.dev_scifi_hit_count_t)

    scifi_pre_decode = Algorithm(
        scifi_pre_decode_algorithm,
        name="scifi_pre_decode",
        host_number_of_events_t=host_number_of_events,
        dev_event_list_t=dev_event_list,
        host_accumulated_number_of_scifi_hits_t=prefix_sum_scifi_hits.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t)

    scifi_raw_bank_decoder = Algorithm(
        scifi_raw_bank_decoder_algorithm,
        name="scifi_raw_bank_decoder",
        host_number_of_events_t=host_number_of_events,
        host_accumulated_number_of_scifi_hits_t=prefix_sum_scifi_hits.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_event_list_t=dev_event_list,
        dev_cluster_references_t=scifi_pre_decode.dev_cluster_references_t)

    lf_search_initial_windows = Algorithm(
        lf_search_initial_windows_t,
        name="lf_search_initial_windows",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_ut_tracks_t=
        host_number_of_reconstructed_ut_tracks,
        dev_scifi_hits_t=scifi_raw_bank_decoder.dev_scifi_hits_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_velo_states_t=dev_velo_states,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_ut_x_t=dev_ut_x,
        dev_ut_tx_t=dev_ut_tx,
        dev_ut_z_t=dev_ut_z,
        dev_ut_qop_t=dev_ut_qop,
        dev_ut_track_velo_indices_t=dev_ut_track_velo_indices)

    lf_triplet_seeding = Algorithm(
        lf_triplet_seeding_t,
        name="lf_triplet_seeding",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_ut_tracks_t=
        host_number_of_reconstructed_ut_tracks,
        dev_scifi_hits_t=scifi_raw_bank_decoder.dev_scifi_hits_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_velo_states_t=dev_velo_states,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_ut_track_velo_indices_t=dev_ut_track_velo_indices,
        dev_ut_qop_t=dev_ut_qop,
        dev_scifi_lf_initial_windows_t=lf_search_initial_windows.
        dev_scifi_lf_initial_windows_t,
        dev_ut_states_t=lf_search_initial_windows.dev_ut_states_t,
        dev_scifi_lf_process_track_t=lf_search_initial_windows.
        dev_scifi_lf_process_track_t)

    lf_create_tracks = Algorithm(
        lf_create_tracks_t,
        name="lf_create_tracks",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_ut_tracks_t=
        host_number_of_reconstructed_ut_tracks,
        dev_scifi_hits_t=scifi_raw_bank_decoder.dev_scifi_hits_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_velo_states_t=dev_velo_states,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_ut_track_velo_indices_t=dev_ut_track_velo_indices,
        dev_ut_qop_t=dev_ut_qop,
        dev_scifi_lf_initial_windows_t=lf_search_initial_windows.
        dev_scifi_lf_initial_windows_t,
        dev_ut_states_t=lf_search_initial_windows.dev_ut_states_t,
        dev_scifi_lf_process_track_t=lf_search_initial_windows.
        dev_scifi_lf_process_track_t,
        dev_scifi_lf_found_triplets_t=lf_triplet_seeding.
        dev_scifi_lf_found_triplets_t,
        dev_scifi_lf_number_of_found_triplets_t=lf_triplet_seeding.
        dev_scifi_lf_number_of_found_triplets_t)

    lf_quality_filter_length = Algorithm(
        lf_quality_filter_length_t,
        name="lf_quality_filter_length",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_ut_tracks_t=
        host_number_of_reconstructed_ut_tracks,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_scifi_lf_tracks_t=lf_create_tracks.dev_scifi_lf_tracks_t,
        dev_scifi_lf_atomics_t=lf_create_tracks.dev_scifi_lf_atomics_t,
        dev_scifi_lf_parametrization_t=lf_create_tracks.
        dev_scifi_lf_parametrization_t)

    lf_quality_filter = Algorithm(
        lf_quality_filter_t,
        name="lf_quality_filter",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_ut_tracks_t=
        host_number_of_reconstructed_ut_tracks,
        dev_scifi_hits_t=scifi_raw_bank_decoder.dev_scifi_hits_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_scifi_lf_length_filtered_atomics_t=lf_quality_filter_length.
        dev_scifi_lf_length_filtered_atomics_t,
        dev_scifi_lf_length_filtered_tracks_t=lf_quality_filter_length.
        dev_scifi_lf_length_filtered_tracks_t,
        dev_scifi_lf_parametrization_length_filter_t=lf_quality_filter_length.
        dev_scifi_lf_parametrization_length_filter_t,
        dev_ut_states_t=lf_search_initial_windows.dev_ut_states_t,
        dev_velo_states_t=dev_velo_states,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_ut_track_velo_indices_t=dev_ut_track_velo_indices)

    prefix_sum_forward_tracks = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_forward_tracks",
        dev_input_buffer_t=lf_quality_filter.dev_atomics_scifi_t)

    scifi_copy_track_hit_number = Algorithm(
        scifi_copy_track_hit_number_t,
        name="scifi_copy_track_hit_number",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t)

    prefix_sum_scifi_track_hit_number = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_scifi_track_hit_number",
        dev_input_buffer_t=scifi_copy_track_hit_number.
        dev_scifi_track_hit_number_t)

    scifi_consolidate_tracks = Algorithm(
        scifi_consolidate_tracks_t,
        name="scifi_consolidate_tracks",
        host_number_of_events_t=host_number_of_events,
        host_accumulated_number_of_hits_in_scifi_tracks_t=
        prefix_sum_scifi_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t,
        dev_scifi_hits_t=scifi_raw_bank_decoder.dev_scifi_hits_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t,
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t,
        dev_offsets_ut_tracks_t=dev_offsets_ut_tracks,
        dev_offsets_ut_track_hit_number_t=dev_offsets_ut_track_hit_number,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_scifi_lf_parametrization_consolidate_t=lf_quality_filter.
        dev_scifi_lf_parametrization_consolidate_t)

    return {
        "dev_scifi_track_hits":
        scifi_consolidate_tracks.dev_scifi_track_hits_t,
        "dev_scifi_qop":
        scifi_consolidate_tracks.dev_scifi_qop_t,
        "dev_scifi_states":
        scifi_consolidate_tracks.dev_scifi_states_t,
        "dev_scifi_track_ut_indices":
        scifi_consolidate_tracks.dev_scifi_track_ut_indices_t,
        "host_number_of_reconstructed_scifi_tracks":
        prefix_sum_forward_tracks.host_total_sum_holder_t,
        "dev_offsets_forward_tracks":
        prefix_sum_forward_tracks.dev_output_buffer_t,
        "dev_offsets_scifi_track_hit_number":
        prefix_sum_scifi_track_hit_number.dev_output_buffer_t
    }
