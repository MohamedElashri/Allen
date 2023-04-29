###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    data_provider_t, ut_calculate_number_of_hits_t, host_prefix_sum_t,
    ut_pre_decode_t, ut_find_permutation_t, ut_decode_raw_banks_in_order_t,
    ut_select_velo_tracks_t, ut_search_windows_t,
    ut_select_velo_tracks_with_windows_t, compass_ut_t,
    ut_copy_track_hit_number_t, ut_consolidate_tracks_t)
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


def decode_ut():
    number_of_events = initialize_number_of_events()
    ut_banks = make_algorithm(
        data_provider_t, name='ut_banks_{hash}', bank_type="UT")

    ut_calculate_number_of_hits = make_algorithm(
        ut_calculate_number_of_hits_t,
        name='ut_calculate_number_of_hits_{hash}',
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t)

    prefix_sum_ut_hits = make_algorithm(
        host_prefix_sum_t,
        name='prefix_sum_ut_hits_{hash}',
        dev_input_buffer_t=ut_calculate_number_of_hits.dev_ut_hit_sizes_t)

    ut_pre_decode = make_algorithm(
        ut_pre_decode_t,
        name='ut_pre_decode_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t,
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t)

    ut_find_permutation = make_algorithm(
        ut_find_permutation_t,
        name='ut_find_permutation_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t,
        dev_ut_pre_decoded_hits_t=ut_pre_decode.dev_ut_pre_decoded_hits_t,
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t)

    ut_decode_raw_banks_in_order = make_algorithm(
        ut_decode_raw_banks_in_order_t,
        name='ut_decode_raw_banks_in_order_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_ut_hits_t=prefix_sum_ut_hits.
        host_total_sum_holder_t,
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_hit_offsets_t=prefix_sum_ut_hits.dev_output_buffer_t,
        dev_ut_pre_decoded_hits_t=ut_pre_decode.dev_ut_pre_decoded_hits_t,
        dev_ut_hit_permutations_t=ut_find_permutation.
        dev_ut_hit_permutations_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t)

    return {
        "dev_ut_hits":
        ut_decode_raw_banks_in_order.dev_ut_hits_t,
        "dev_ut_hit_offsets":
        prefix_sum_ut_hits.dev_output_buffer_t,
        "host_accumulated_number_of_ut_hits":
        prefix_sum_ut_hits.host_total_sum_holder_t
    }


@configurable
def make_ut_tracks(decoded_ut, velo_tracks, restricted=True):
    number_of_events = initialize_number_of_events()
    velo_states = run_velo_kalman_filter(velo_tracks)

    host_number_of_reconstructed_velo_tracks_t = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_offsets_all_velo_tracks_t = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number_t = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    dev_accepted_velo_tracks_t = velo_tracks["dev_accepted_velo_tracks"]

    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name='ut_select_velo_tracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks_t)

    ut_search_windows_min_momentum = 1250.0
    ut_search_windows_min_pt = 275.0
    compass_ut_max_considered_before_found = 6
    compass_ut_min_momentum_final = 1500.0
    compass_ut_min_pt_final = 400.0

    if not restricted:
        ut_search_windows_min_momentum = 1250.0
        ut_search_windows_min_pt = 200.0
        compass_ut_max_considered_before_found = 6
        compass_ut_min_momentum_final = 1500.0
        compass_ut_min_pt_final = 250.0

    ut_search_windows = make_algorithm(
        ut_search_windows_t,
        name='ut_search_windows_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        min_momentum=ut_search_windows_min_momentum,
        min_pt=ut_search_windows_min_pt)

    ut_select_velo_tracks_with_windows = make_algorithm(
        ut_select_velo_tracks_with_windows_t,
        name='ut_select_velo_tracks_with_windows_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks_t,
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        dev_ut_windows_layers_t=ut_search_windows.dev_ut_windows_layers_t)

    compass_ut = make_algorithm(
        compass_ut_t,
        name='compass_ut_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
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
        name='prefix_sum_ut_tracks_{hash}',
        dev_input_buffer_t=compass_ut.dev_atomics_ut_t)

    ut_copy_track_hit_number = make_algorithm(
        ut_copy_track_hit_number_t,
        name='ut_copy_track_hit_number_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_ut_tracks_t=prefix_sum_ut_tracks.
        host_total_sum_holder_t,
        dev_ut_tracks_t=compass_ut.dev_ut_tracks_t,
        dev_offsets_ut_tracks_t=prefix_sum_ut_tracks.dev_output_buffer_t)

    prefix_sum_ut_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name='prefix_sum_ut_track_hit_number_{hash}',
        dev_input_buffer_t=ut_copy_track_hit_number.dev_ut_track_hit_number_t)

    ut_consolidate_tracks = make_algorithm(
        ut_consolidate_tracks_t,
        name='ut_consolidate_tracks_{hash}',
        host_accumulated_number_of_ut_hits_t=decoded_ut[
            "host_accumulated_number_of_ut_hits"],
        host_number_of_reconstructed_ut_tracks_t=prefix_sum_ut_tracks.
        host_total_sum_holder_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_ut_tracks_t=
        prefix_sum_ut_track_hit_number.host_total_sum_holder_t,
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_offsets_ut_tracks_t=prefix_sum_ut_tracks.dev_output_buffer_t,
        dev_offsets_ut_track_hit_number_t=prefix_sum_ut_track_hit_number.
        dev_output_buffer_t,
        dev_ut_tracks_t=compass_ut.dev_ut_tracks_t,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"])

    return {
        "velo_tracks":
        velo_tracks,
        "velo_states":
        velo_states,
        "host_number_of_reconstructed_ut_tracks":
        prefix_sum_ut_tracks.host_total_sum_holder_t,
        "dev_offsets_ut_tracks":
        prefix_sum_ut_tracks.dev_output_buffer_t,
        "dev_offsets_ut_track_hit_number":
        prefix_sum_ut_track_hit_number.dev_output_buffer_t,
        "dev_ut_track_hits":
        ut_consolidate_tracks.dev_ut_track_hits_t,
        "dev_ut_qop":
        ut_consolidate_tracks.dev_ut_qop_t,
        "dev_ut_track_velo_indices":
        ut_consolidate_tracks.dev_ut_track_velo_indices_t,
        "dev_ut_tracks_view":
        ut_consolidate_tracks.dev_ut_tracks_view_t,
        "dev_ut_multi_event_tracks_view":
        ut_consolidate_tracks.dev_ut_multi_event_tracks_view_t,
        "dev_imec_ut_tracks":
        ut_consolidate_tracks.dev_imec_ut_tracks_t,

        # TODO: Is this needed anymore?
        # Needed for long track particle dependencies
        "dev_ut_track_view":
        ut_consolidate_tracks.dev_ut_track_view_t,
        "dev_ut_hits_view":
        ut_consolidate_tracks.dev_ut_hits_view_t
    }


def ut_tracking():
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    alg = ut_tracks["dev_ut_track_hits"].producer
    return alg
