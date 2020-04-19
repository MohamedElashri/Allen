from definitions.algorithms import *


def UTSequence(restricted=True):
    ut_banks = data_provider_t("ut_banks",
        dev_raw_banks_t="dev_ut_raw_input_t",
        dev_raw_offsets_t="dev_ut_raw_input_offsets_t",
        bank_type="UT")

    ut_calculate_number_of_hits = ut_calculate_number_of_hits_t()

    prefix_sum_ut_hits = host_prefix_sum_t(
        "prefix_sum_ut_hits",
        host_total_sum_holder_t="host_accumulated_number_of_ut_hits_t",
        dev_input_buffer_t=ut_calculate_number_of_hits.dev_ut_hit_sizes_t(),
        dev_output_buffer_t="dev_ut_hit_offsets_t")

    ut_pre_decode = ut_pre_decode_t()
    ut_find_permutation = ut_find_permutation_t()
    ut_decode_raw_banks_in_order = ut_decode_raw_banks_in_order_t()
    ut_select_velo_tracks = ut_select_velo_tracks_t()

    ut_search_windows = None
    compass_ut = None
    if restricted:
        ut_search_windows = ut_search_windows_t(
            min_momentum="1500.0", min_pt="300.0")
        compass_ut = compass_ut_t(
            max_considered_before_found="6",
            min_momentum_final="2500.0",
            min_pt_final="425.0")
    else:
        ut_search_windows = ut_search_windows_t(
            min_momentum="3000.0", min_pt="0.0")
        compass_ut = compass_ut_t(
            max_considered_before_found="16",
            min_momentum_final="0.0",
            min_pt_final="0.0")

    ut_select_velo_tracks_with_windows = ut_select_velo_tracks_with_windows_t()

    prefix_sum_ut_tracks = host_prefix_sum_t(
        "prefix_sum_ut_tracks",
        host_total_sum_holder_t="host_number_of_reconstructed_ut_tracks_t",
        dev_input_buffer_t=compass_ut.dev_atomics_ut_t(),
        dev_output_buffer_t="dev_offsets_ut_tracks_t")

    ut_copy_track_hit_number = ut_copy_track_hit_number_t()

    prefix_sum_ut_track_hit_number = host_prefix_sum_t(
        "prefix_sum_ut_track_hit_number",
        host_total_sum_holder_t=
        "host_accumulated_number_of_hits_in_ut_tracks_t",
        dev_input_buffer_t=ut_copy_track_hit_number.
        dev_ut_track_hit_number_t(),
        dev_output_buffer_t="dev_offsets_ut_track_hit_number_t")

    ut_consolidate_tracks = ut_consolidate_tracks_t()

    ut_sequence = Sequence(
        ut_banks, ut_calculate_number_of_hits, prefix_sum_ut_hits,
        ut_pre_decode, ut_find_permutation, ut_decode_raw_banks_in_order,
        ut_select_velo_tracks, ut_search_windows,
        ut_select_velo_tracks_with_windows, compass_ut, prefix_sum_ut_tracks,
        ut_copy_track_hit_number, prefix_sum_ut_track_hit_number,
        ut_consolidate_tracks)

    return ut_sequence
