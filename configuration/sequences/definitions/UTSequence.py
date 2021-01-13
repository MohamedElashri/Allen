###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *
from definitions.VeloSequence import make_velo_tracks, run_velo_kalman_filter
from definitions.InitSequence import initialize_number_of_events
from definitions.event_list_utils import make_algorithm
from minipyconf.tonic import configurable


@configurable
def make_ut_tracks(restricted=True, **kwargs):
    number_of_events = initialize_number_of_events(**kwargs)
    velo_tracks = make_velo_tracks(**kwargs)
    velo_states = run_velo_kalman_filter(**kwargs)

    ut_calculate_number_of_hits = ut_calculate_number_of_hits_t(
        name="ut_calculate_number_of_hits",
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t(),
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t(),
        host_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    prefix_sum_ut_hits = host_prefix_sum_t(
        name="prefix_sum_ut_hits",
        dev_input_buffer_t=ut_calculate_number_of_hits.dev_ut_hit_sizes_t())

    ut_pre_decode = ut_pre_decode_t(
        name="ut_pre_decode",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t(),
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t(),
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t(),
        host_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    ut_find_permutation = ut_find_permutation_t(
        name="ut_find_permutation",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t(),
        dev_ut_pre_decoded_hits_t=ut_pre_decode.dev_ut_pre_decoded_hits_t(),
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    ut_decode_raw_banks_in_order = ut_decode_raw_banks_in_order_t(
        name="ut_decode_raw_banks_in_order",
        host_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t(),
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t(),
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t(),
        dev_ut_pre_decoded_hits_t=ut_pre_decode.dev_ut_pre_decoded_hits_t(),
        dev_ut_hit_permutations_t=ut_find_permutation.
        dev_ut_hit_permutations_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    ut_select_velo_tracks = ut_select_velo_tracks_t(
        name="ut_select_velo_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number_t,
        dev_velo_states_t=velo_states["dev_velo_kalman_beamline_states"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks_t,
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"])

    ut_search_windows_min_momentum = "1500.0"
    ut_search_windows_min_pt = "300.0"
    compass_ut_max_considered_before_found = "6"
    compass_ut_min_momentum_final = "2500.0"
    compass_ut_min_pt_final = "425.0"

    if not restricted:
        ut_search_windows_min_momentum = "3000.0"
        ut_search_windows_min_pt = "0.0"
        compass_ut_max_considered_before_found = "16"
        compass_ut_min_momentum_final = "0.0"
        compass_ut_min_pt_final = "0.0"

    ut_search_windows = make_algorithm(
        ut_search_windows_t,
        name="ut_search_windows",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_ut_hits_t=ut_decode_raw_banks_in_order.dev_ut_hits_t,
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number_t,
        dev_velo_states_t=velo_states["dev_velo_kalman_endvelo_states"],
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        min_momentum=ut_search_windows_min_momentum,
        min_pt=ut_search_windows_min_pt)

    ut_select_velo_tracks_with_windows = make_algorithm(
        ut_select_velo_tracks_with_windows_t,
        name="ut_select_velo_tracks_with_windows",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number_t,
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks_t,
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        dev_ut_windows_layers_t=ut_search_windows.dev_ut_windows_layers_t)

    compass_ut = make_algorithm(
        compass_ut_t,
        name="compass_ut",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hits_t=ut_decode_raw_banks_in_order.dev_ut_hits_t,
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks_t,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number_t,
        dev_velo_states_t=velo_states["dev_velo_lmsfit_beamline_states"],
        dev_ut_windows_layers_t=ut_search_windows.dev_ut_windows_layers_t,
        dev_ut_number_of_selected_velo_tracks_with_windows_t=
        ut_select_velo_tracks_with_windows.
        dev_ut_number_of_selected_velo_tracks_with_windows_t,
        dev_ut_selected_velo_tracks_with_windows_t=
        ut_select_velo_tracks_with_windows.
        dev_ut_selected_velo_tracks_with_windows_t,
        max_considered_before_found=compass_ut_max_considered_before_found,
        min_momentum_final=compass_ut_min_momentum_final,
        min_pt_final=compass_ut_min_pt_final)

    prefix_sum_ut_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_ut_tracks",
        dev_input_buffer_t=compass_ut.dev_atomics_ut_t())

    ut_copy_track_hit_number = ut_copy_track_hit_number_t(
        name="ut_copy_track_hit_number",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_reconstructed_ut_tracks_t=prefix_sum_ut_tracks.
        host_total_sum_holder_t(),
        dev_ut_tracks_t=compass_ut.dev_ut_tracks_t(),
        dev_offsets_ut_tracks_t=prefix_sum_ut_tracks.dev_output_buffer_t())

    prefix_sum_ut_track_hit_number = host_prefix_sum_t(
        name="prefix_sum_ut_track_hit_number",
        dev_input_buffer_t=ut_copy_track_hit_number.
        dev_ut_track_hit_number_t())

    ut_consolidate_tracks = ut_consolidate_tracks_t(
        name="ut_consolidate_tracks",
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t(),
        host_number_of_reconstructed_ut_tracks_t=prefix_sum_ut_tracks.
        host_total_sum_holder_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_accumulated_number_of_hits_in_ut_tracks_t=
        prefix_sum_ut_track_hit_number.host_total_sum_holder_t(),
        dev_ut_hits_t=ut_decode_raw_banks_in_order.dev_ut_hits_t(),
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t(),
        dev_offsets_ut_tracks_t=prefix_sum_ut_tracks.dev_output_buffer_t(),
        dev_offsets_ut_track_hit_number_t=prefix_sum_ut_track_hit_number.
        dev_output_buffer_t(),
        dev_ut_tracks_t=compass_ut.dev_ut_tracks_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    ut_sequence = Sequence(
        ut_banks, ut_calculate_number_of_hits, prefix_sum_ut_hits,
        ut_pre_decode, ut_find_permutation, ut_decode_raw_banks_in_order,
        ut_select_velo_tracks, ut_search_windows,
        ut_select_velo_tracks_with_windows, compass_ut, prefix_sum_ut_tracks,
        ut_copy_track_hit_number, prefix_sum_ut_track_hit_number,
        ut_consolidate_tracks)

    return ut_sequence
