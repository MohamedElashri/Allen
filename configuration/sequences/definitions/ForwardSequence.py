from definitions.algorithms import *


def ForwardSequence(forward_decoding="v4"):
    lf_search_initial_windows = lf_search_initial_windows_t()
    lf_triplet_seeding = lf_triplet_seeding_t()
    lf_create_tracks = lf_create_tracks_t()
    lf_quality_filter_length = lf_quality_filter_length_t()
    lf_quality_filter = lf_quality_filter_t()

    prefix_sum_forward_tracks = host_prefix_sum_t(
        "prefix_sum_forward_tracks",
        host_total_sum_holder_t="host_number_of_reconstructed_scifi_tracks_t",
        dev_input_buffer_t=lf_quality_filter.dev_atomics_scifi_t(),
        dev_output_buffer_t="dev_offsets_forward_tracks_t")

    scifi_copy_track_hit_number = scifi_copy_track_hit_number_t()

    prefix_sum_scifi_track_hit_number = host_prefix_sum_t(
        "prefix_sum_scifi_track_hit_number",
        host_total_sum_holder_t=
        "host_accumulated_number_of_hits_in_scifi_tracks_t",
        dev_input_buffer_t=scifi_copy_track_hit_number.
        dev_scifi_track_hit_number_t(),
        dev_output_buffer_t="dev_offsets_scifi_track_hit_number")

    scifi_consolidate_tracks = scifi_consolidate_tracks_t()

    forward_sequence = None
    if forward_decoding == "v4":
        scifi_calculate_cluster_count_v4 = scifi_calculate_cluster_count_v4_t()

        prefix_sum_scifi_hits = host_prefix_sum_t(
            "prefix_sum_scifi_hits",
            host_total_sum_holder_t="host_accumulated_number_of_scifi_hits_t",
            dev_input_buffer_t=scifi_calculate_cluster_count_v4.
            dev_scifi_hit_count_t(),
            dev_output_buffer_t="dev_scifi_hit_offsets_t")

        scifi_pre_decode_v4 = scifi_pre_decode_v4_t()
        scifi_raw_bank_decoder_v4 = scifi_raw_bank_decoder_v4_t()

        forward_sequence = Sequence(
            scifi_calculate_cluster_count_v4, prefix_sum_scifi_hits,
            scifi_pre_decode_v4, scifi_raw_bank_decoder_v4,
            lf_search_initial_windows,
            lf_triplet_seeding, lf_create_tracks,
            lf_quality_filter_length, lf_quality_filter,
            prefix_sum_forward_tracks, scifi_copy_track_hit_number,
            prefix_sum_scifi_track_hit_number, scifi_consolidate_tracks)
    elif forward_decoding == "v6":
        scifi_calculate_cluster_count_v6 = scifi_calculate_cluster_count_v6_t()

        prefix_sum_scifi_hits = host_prefix_sum_t(
            "prefix_sum_scifi_hits",
            host_total_sum_holder_t="host_accumulated_number_of_scifi_hits_t",
            dev_input_buffer_t=scifi_calculate_cluster_count_v6.
            dev_scifi_hit_count_t(),
            dev_output_buffer_t="dev_scifi_hit_offsets_t")

        scifi_pre_decode_v6 = scifi_pre_decode_v6_t()
        scifi_raw_bank_decoder_v6 = scifi_raw_bank_decoder_v6_t()

        forward_sequence = Sequence(
            scifi_calculate_cluster_count_v6, prefix_sum_scifi_hits,
            scifi_pre_decode_v6, scifi_raw_bank_decoder_v6,
            lf_search_initial_windows, lf_triplet_seeding,
            lf_create_tracks, lf_quality_filter_length,
            lf_quality_filter, prefix_sum_forward_tracks,
            scifi_copy_track_hit_number, prefix_sum_scifi_track_hit_number,
            scifi_consolidate_tracks)

    return forward_sequence
