###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (
    data_provider_t, scifi_calculate_cluster_count_t, scifi_pre_decode_t,
    scifi_raw_bank_decoder_t, ut_select_velo_tracks_t,
    lf_search_initial_windows_t, lf_triplet_seeding_t, lf_create_tracks_t,
    lf_quality_filter_length_t, lf_quality_filter_t,
    scifi_copy_track_hit_number_t, scifi_consolidate_tracks_t, get_type_id_t,
    seed_xz_t, seed_confirmTracks_t, seeding_copy_track_hit_number_t,
    seed_confirmTracks_consolidate_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.ut_reconstruction import make_dummy_ut_hits


def fetch_momentum_parameters(version: int):
    '''
    Fetch momentum parametrization for VeloSciFi Matching (with UT) algorithm, first 8 floats correspond to MagUp
    last 8 floats correspond to MagDown:
        p = params[0] + 
            (
                params[1] + 
                params[2] * (txT * txT) + 
                params[3] * (txT * txT * txT * txT) + 
                params[4] * (txT * txV) + params[5] * (tyV * tyV) + 
                params[6] * (tyV * tyV * tyV * tyV) + 
                params[7] * (txV * txV)
            ) / fabsf(dslope)
    The following versioning are supported:
        v0: Use same parametrization as HLT2: great performance for MagDown, mass peak is shift in MagUp
        v1: Update parametrization values with Run2 Magnetic Field Map, setting momentum offset to 0: Align the mass peak in both MagUp and MagDown, 
            but both are slighly biased.
        v2: Use v0 in MagDown and v1 in MagUp
        v3: Update the momentum offset for v1, use v1+offset in MagUp and v0 in MagDown
        v4: Use v1+offset in both MagUp and MagDown
        v5: Update v3 with Run3 Magnetic Field Map
    '''
    parametrization_options = {
        # v0: OLD Hlt2 parameters for both MagUp and MagDown
        0: (42.04859549174048, 1239.4073749458162, 486.05664058906814,
            6.7158701518424815, 632.7283787142547, 2358.5758035677504,
            -9256.27946160669, 241.4601040854867, 42.04859549174048,
            1239.4073749458162, 486.05664058906814, 6.7158701518424815,
            632.7283787142547, 2358.5758035677504, -9256.27946160669,
            241.4601040854867),
        # v1: Updated v0 parameters for both MagUp and MagDown
        1: (
            0,
            1.239076e+03,
            5.650170e+02,
            -7.683592e+01,
            6.148917e+02,
            2.071115e+03,
            -6.795680e+03,
            4.577582e+02,
            0,
            1.239076e+03,
            5.650170e+02,
            -7.683592e+01,
            6.148917e+02,
            2.071115e+03,
            -6.795680e+03,
            4.577582e+02,
        ),
        # v2: v1 for MagUp and v0 for MagDown
        2: (0, 1.239076e+03, 5.650170e+02, -7.683592e+01, 6.148917e+02,
            2.071115e+03, -6.795680e+03, 4.577582e+02, 42.04859549174048,
            1239.4073749458162, 486.05664058906814, 6.7158701518424815,
            632.7283787142547, 2358.5758035677504, -9256.27946160669,
            241.4601040854867),
        # v3: Add offset to v1: v1+offset for MagUp and v0 for MagDown
        3: (34.27448, 1.239076e+03, 5.650170e+02, -7.683592e+01, 6.148917e+02,
            2.071115e+03, -6.795680e+03, 4.577582e+02, 42.04859549174048,
            1239.4073749458162, 486.05664058906814, 6.7158701518424815,
            632.7283787142547, 2358.5758035677504, -9256.27946160669,
            241.4601040854867),
        # v4: v1+offset for both MagUp and MagDown
        4: (34.27448, 1.239076e+03, 5.650170e+02, -7.683592e+01, 6.148917e+02,
            2.071115e+03, -6.795680e+03, 4.577582e+02, 34.27448, 1.239076e+03,
            5.650170e+02, -7.683592e+01, 6.148917e+02, 2.071115e+03,
            -6.795680e+03, 4.577582e+02),
        # v5: update v4 with 2024 Magnetic Field Map (no offset is set) : TODO compute offset based on KsToPiPi mass peak
        5: (0., 1.242252e+03, 5.793044e+02, -1.280154e+0, 5.831745e+02,
            1.935609e+03, -6.578155e+0, 4.498875e+02, 0., 1.242285e+03,
            5.795218e+02, -1.283602e+0, 5.839503e+02, 1.936307e+03,
            -6.577531e+0, 4.510438e+02),
    }
    return parametrization_options[version]


@configurable
def decode_scifi():
    number_of_events = initialize_number_of_events()
    scifi_banks = make_algorithm(
        data_provider_t, name='scifi_banks_{hash}', bank_type="FTCluster")

    scifi_calculate_cluster_count = make_algorithm(
        scifi_calculate_cluster_count_t,
        name='scifi_calculate_cluster_count_{hash}',
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        dev_scifi_raw_input_types_t=scifi_banks.dev_raw_types_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    scifi_pre_decode = make_algorithm(
        scifi_pre_decode_t,
        name='scifi_pre_decode_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_accumulated_number_of_scifi_hits_t=scifi_calculate_cluster_count.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        dev_scifi_raw_input_types_t=scifi_banks.dev_raw_types_t,
        dev_scifi_hit_offsets_t=scifi_calculate_cluster_count.
        dev_scifi_hit_count_t,
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    scifi_raw_bank_decoder = make_algorithm(
        scifi_raw_bank_decoder_t,
        name='scifi_raw_bank_decoder_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_scifi_hits_t=scifi_calculate_cluster_count.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        dev_scifi_raw_input_types_t=scifi_banks.dev_raw_types_t,
        dev_scifi_hit_offsets_t=scifi_calculate_cluster_count.
        dev_scifi_hit_offsets_t,
        dev_cluster_references_t=scifi_pre_decode.dev_cluster_references_t,
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    return {
        "host_number_of_scifi_hits":
        scifi_calculate_cluster_count.host_total_sum_holder_t,
        "dev_scifi_hits":
        scifi_raw_bank_decoder.dev_scifi_hits_t,
        "dev_scifi_hit_offsets":
        scifi_calculate_cluster_count.dev_scifi_hit_offsets_t,
    }


@configurable
def make_forward_tracks(
        decoded_scifi,
        input_tracks,
        ut_hits=None,
        dev_accepted_velo_tracks=None,
        with_ut=True,
        ghost_killer_threshold=0.5,
        momentum_parameter_version=3,
        scifi_consolidate_tracks_name='scifi_consolidate_tracks'):
    number_of_events = initialize_number_of_events()

    if (with_ut):
        velo_tracks = input_tracks["velo_tracks"]
        host_number_of_reconstructed_input_tracks = input_tracks[
            "host_number_of_reconstructed_ut_tracks"]
        dev_offsets_input_tracks = input_tracks["dev_offsets_ut_tracks"]
        velo_states = input_tracks["velo_states"]
        input_track_views = input_tracks["dev_imec_ut_tracks"]
        #search windows
        hit_window_size = 32
        overlap_in_mm = 5.
        initial_windows_max_offset_uv_window = 800.
        x_windows_factor = 1.
        input_momentum = 5000
        input_pt = 1000
        #triplet seeding
        chi2_max_triplet_single = 8.
        z_mag_difference = 10.
        #create tracks
        max_triplets_per_input_track = 12
        chi2_max_extrapolation_to_x_layers_single = 2.
        uv_hits_chi2_factor_x = 50.
        uv_hits_chi2_factor_y = 50.
        #quality factor
        max_diff_ty_window = 0.02
        max_final_quality = 0.5
        min_tot_scifi_hits = 9
        min_UV_scifi_hits = 3
        min_X_scifi_hits = 3
        factor_9_hits = 5.
        factor_10_hits = 1.
        factor_11_hits = 0.8
        factor_12_hits = 0.5
    else:
        velo_tracks = input_tracks
        host_number_of_reconstructed_input_tracks = velo_tracks[
            "host_number_of_reconstructed_velo_tracks"]
        dev_offsets_input_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
        velo_states = run_velo_kalman_filter(velo_tracks)
        input_track_views = velo_tracks["dev_imec_velo_tracks"]
        #search windows
        hit_window_size = 64
        overlap_in_mm = 5.
        initial_windows_max_offset_uv_window = 1200.
        x_windows_factor = 1.2
        input_momentum = 5000
        input_pt = 1000
        #triplet seeding
        chi2_max_triplet_single = 4.0
        z_mag_difference = 8.
        #create tracks
        max_triplets_per_input_track = 15
        chi2_max_extrapolation_to_x_layers_single = 0.5
        uv_hits_chi2_factor_x = 15.
        uv_hits_chi2_factor_y = 5.
        #quality factor
        max_diff_ty_window = 0.01

        max_final_quality = 2.0
        min_tot_scifi_hits = 9
        min_UV_scifi_hits = 4
        min_X_scifi_hits = 3
        factor_9_hits = 5.
        factor_10_hits = 1.
        factor_11_hits = 0.8
        factor_12_hits = 0.5

    if not dev_accepted_velo_tracks:
        dev_accepted_velo_tracks = velo_tracks["dev_accepted_velo_tracks"]

    if not ut_hits:
        ut_hits = make_dummy_ut_hits()

    # The preexisting will be deduplicated in UT-ful
    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name='ut_select_velo_tracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks)

    # With or without UT (get type if of input_track_views)
    get_type_id = make_algorithm(
        get_type_id_t, name='get_type_id_{hash}', dev_imec_t=input_track_views)

    lf_search_initial_windows = make_algorithm(
        lf_search_initial_windows_t,
        name='lf_search_initial_windows_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        dev_tracks_view_t=input_track_views,
        dev_ut_selected_velo_tracks_offsets_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_offsets_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        hit_window_size=hit_window_size,
        overlap_in_mm=overlap_in_mm,
        initial_windows_max_offset_uv_window=
        initial_windows_max_offset_uv_window,
        x_windows_factor=x_windows_factor,
        host_track_type_id_t=get_type_id.host_type_id_t,
        input_momentum=input_momentum,
        input_pt=input_pt)

    lf_triplet_seeding = make_algorithm(
        lf_triplet_seeding_t,
        name='lf_triplet_seeding_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        host_scifi_hit_count_t=decoded_scifi["host_number_of_scifi_hits"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        dev_tracks_view_t=input_track_views,
        dev_scifi_lf_initial_windows_t=lf_search_initial_windows.
        dev_scifi_lf_initial_windows_t,
        dev_input_states_t=lf_search_initial_windows.dev_input_states_t,
        chi2_max_triplet_single=chi2_max_triplet_single,
        z_mag_difference=z_mag_difference,
        dev_scifi_lf_number_of_tracks_t=lf_search_initial_windows.
        dev_scifi_lf_number_of_tracks_t,
        dev_scifi_lf_tracks_indices_t=lf_search_initial_windows.
        dev_scifi_lf_tracks_indices_t,
        host_track_type_id_t=get_type_id.host_type_id_t)

    lf_create_tracks = make_algorithm(
        lf_create_tracks_t,
        name='lf_create_tracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        dev_tracks_view_t=input_track_views,
        dev_scifi_lf_initial_windows_t=lf_search_initial_windows.
        dev_scifi_lf_initial_windows_t,
        dev_input_states_t=lf_search_initial_windows.dev_input_states_t,
        dev_scifi_lf_found_triplets_t=lf_triplet_seeding.
        dev_scifi_lf_found_triplets_t,
        dev_scifi_lf_number_of_found_triplets_t=lf_triplet_seeding.
        dev_scifi_lf_number_of_found_triplets_t,
        chi2_max_extrapolation_to_x_layers_single=
        chi2_max_extrapolation_to_x_layers_single,
        uv_hits_chi2_factor_x=uv_hits_chi2_factor_x,
        uv_hits_chi2_factor_y=uv_hits_chi2_factor_y,
        max_triplets_per_input_track=max_triplets_per_input_track,
        dev_scifi_lf_number_of_tracks_t=lf_search_initial_windows.
        dev_scifi_lf_number_of_tracks_t,
        dev_scifi_lf_tracks_indices_t=lf_search_initial_windows.
        dev_scifi_lf_tracks_indices_t,
        host_track_type_id_t=get_type_id.host_type_id_t)

    lf_quality_filter_length = make_algorithm(
        lf_quality_filter_length_t,
        name='lf_quality_filter_length_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_tracks_view_t=input_track_views,
        dev_scifi_lf_tracks_t=lf_create_tracks.dev_scifi_lf_tracks_t,
        dev_scifi_lf_atomics_t=lf_create_tracks.dev_scifi_lf_atomics_t,
        dev_scifi_lf_parametrization_t=lf_create_tracks.
        dev_scifi_lf_parametrization_t,
        maximum_number_of_candidates_per_ut_track=max_triplets_per_input_track,
        min_tot_scifi_hits=min_tot_scifi_hits,
        min_UV_scifi_hits=min_UV_scifi_hits,
        min_X_scifi_hits=min_X_scifi_hits)

    lf_quality_filter = make_algorithm(
        lf_quality_filter_t,
        name='lf_quality_filter_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_tracks_view_t=input_track_views,
        dev_scifi_lf_length_filtered_atomics_t=lf_quality_filter_length.
        dev_scifi_lf_length_filtered_atomics_t,
        dev_scifi_lf_length_filtered_tracks_t=lf_quality_filter_length.
        dev_scifi_lf_length_filtered_tracks_t,
        dev_scifi_lf_parametrization_length_filter_t=lf_quality_filter_length.
        dev_scifi_lf_parametrization_length_filter_t,
        dev_input_states_t=lf_search_initial_windows.dev_input_states_t,
        maximum_number_of_candidates_per_ut_track=max_triplets_per_input_track,
        max_diff_ty_window=max_diff_ty_window,
        max_final_quality=max_final_quality,
        factor_9_hits=factor_9_hits,
        factor_10_hits=factor_10_hits,
        factor_11_hits=factor_11_hits,
        factor_12_hits=factor_12_hits,
        ghost_killer_threshold=ghost_killer_threshold)

    scifi_copy_track_hit_number = make_algorithm(
        scifi_copy_track_hit_number_t,
        name='scifi_copy_track_hit_number_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=lf_quality_filter.
        host_number_of_reconstructed_scifi_tracks_t,
        dev_offsets_input_tracks_t=dev_offsets_input_tracks,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_offsets_long_tracks_t=lf_quality_filter.dev_offsets_long_tracks_t)

    momentum_parameters = fetch_momentum_parameters(momentum_parameter_version)

    scifi_consolidate_tracks = make_algorithm(
        scifi_consolidate_tracks_t,
        name=str(scifi_consolidate_tracks_name),
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_scifi_tracks_t=
        scifi_copy_track_hit_number.
        host_accumulated_number_of_hits_in_scifi_tracks_t,
        host_accumulated_number_of_ut_hits_t=ut_hits[
            "host_accumulated_number_of_ut_hits"],
        host_number_of_reconstructed_scifi_tracks_t=lf_quality_filter.
        host_number_of_reconstructed_scifi_tracks_t,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_offsets_long_tracks_t=lf_quality_filter.dev_offsets_long_tracks_t,
        dev_offsets_scifi_track_hit_number_t=scifi_copy_track_hit_number.
        dev_offsets_scifi_track_hit_number_t,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_scifi_lf_parametrization_consolidate_t=lf_quality_filter.
        dev_scifi_lf_parametrization_consolidate_t,
        dev_tracks_view_t=input_track_views,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        host_scifi_hit_count_t=decoded_scifi["host_number_of_scifi_hits"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks,
        momentum_parameters=momentum_parameters)

    return {
        "veloUT_tracks":
        input_tracks,
        "velo_tracks":
        velo_tracks,
        "dev_scifi_track_hits":
        scifi_consolidate_tracks.dev_scifi_track_hits_t,
        "dev_scifi_qop":
        scifi_consolidate_tracks.dev_scifi_qop_t,
        "dev_scifi_states":
        scifi_consolidate_tracks.dev_scifi_states_t,
        "dev_scifi_track_ut_indices":
        scifi_consolidate_tracks.dev_scifi_track_ut_indices_t,
        "host_number_of_reconstructed_scifi_tracks":
        lf_quality_filter.host_number_of_reconstructed_scifi_tracks_t,
        "dev_offsets_long_tracks":
        lf_quality_filter.dev_offsets_long_tracks_t,
        "dev_offsets_scifi_track_hit_number":
        scifi_copy_track_hit_number.dev_offsets_scifi_track_hit_number_t,
        "dev_scifi_tracks_view":
        scifi_consolidate_tracks.dev_scifi_tracks_view_t,
        "dev_multi_event_long_tracks_view":
        scifi_consolidate_tracks.dev_multi_event_long_tracks_view_t,
        "dev_multi_event_long_tracks_ptr":
        scifi_consolidate_tracks.dev_multi_event_long_tracks_ptr_t,
        "velo_kalman_filter":
        velo_states,
        # Needed for long track particle dependencies.
        "dev_scifi_track_view":
        scifi_consolidate_tracks.dev_scifi_track_view_t,
        "dev_scifi_hits_view":
        scifi_consolidate_tracks.dev_scifi_hits_view_t,
        "dev_long_track_view":
        scifi_consolidate_tracks.dev_long_track_view_t,
        "dev_used_scifi_hits":
        scifi_consolidate_tracks.dev_used_scifi_hits_t,
        "dev_accepted_and_unused_velo_tracks":
        scifi_consolidate_tracks.dev_accepted_and_unused_velo_tracks_t,
        # UT hits veto
        "dev_used_ut_hits_offsets":
        scifi_consolidate_tracks.dev_used_ut_hits_offsets_t,
    }


@configurable
def make_seeding_XZ_tracks(decoded_scifi):
    number_of_events = initialize_number_of_events()

    seed_xz_tracks = make_algorithm(
        seed_xz_t,
        name='seed_xz_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_scifi_hit_count_t=decoded_scifi["host_number_of_scifi_hits"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_count_t=decoded_scifi["dev_scifi_hit_offsets"])

    return {
        "seed_xz_tracks":
        seed_xz_tracks.dev_seeding_tracksXZ_t,
        "seed_xz_tracks_part0":
        seed_xz_tracks.dev_seeding_number_of_tracksXZ_part0_t,
        "seed_xz_tracks_part1":
        seed_xz_tracks.dev_seeding_number_of_tracksXZ_part1_t,
        "seed_xz_number_of_tracks":
        seed_xz_tracks.dev_seeding_number_of_tracksXZ_t
    }


@configurable
def make_seeding_tracks(
        decoded_scifi,
        xz_tracks,
        scifi_consolidate_seeds_name='scifi_consolidate_seeds'):
    number_of_events = initialize_number_of_events()

    seed_tracks = make_algorithm(
        seed_confirmTracks_t,
        name='seed_confirmTracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_count_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_seeding_tracksXZ_t=xz_tracks["seed_xz_tracks"],
        dev_seeding_number_of_tracksXZ_part0_t=xz_tracks[
            "seed_xz_tracks_part0"],
        dev_seeding_number_of_tracksXZ_part1_t=xz_tracks[
            "seed_xz_tracks_part1"],
        tuning_nhits=10,
        tuning_tol_chi2=100,
        tuning_tol=0.8,
    )

    seeding_copy_track_hit_number = make_algorithm(
        seeding_copy_track_hit_number_t,
        name='seeding_copy_track_hit_number_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_seeding_tracks_t=seed_tracks.
        host_seeding_number_of_tracks_t,
        dev_seeding_tracks_t=seed_tracks.dev_seeding_tracks_t,
        dev_seeding_atomics_t=seed_tracks.dev_offsets_seeding_tracks_t)

    seed_confirmTracks_consolidate = make_algorithm(
        seed_confirmTracks_consolidate_t,
        name=str(scifi_consolidate_seeds_name),
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_scifi_tracks_t=
        seeding_copy_track_hit_number.
        host_accumulated_number_of_hits_in_scifi_tracks_t,
        host_number_of_reconstructed_seeding_tracks_t=seed_tracks.
        host_seeding_number_of_tracks_t,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_offsets_seeding_tracks_t=seed_tracks.dev_offsets_seeding_tracks_t,
        dev_offsets_seeding_hit_number_t=seeding_copy_track_hit_number.
        dev_offsets_seeding_hit_number_t,
        dev_seeding_tracks_t=seed_tracks.dev_seeding_tracks_t,
        host_scifi_hit_count_t=decoded_scifi["host_number_of_scifi_hits"])

    return {
        "seed_tracks":
        seed_tracks.dev_seeding_tracks_t,
        "dev_seeding_track_hits":
        seed_confirmTracks_consolidate.dev_seeding_track_hits_t,
        "dev_seeding_states":
        seed_confirmTracks_consolidate.dev_seeding_states_t,
        "dev_seeding_qop":
        seed_confirmTracks_consolidate.dev_seeding_qop_t,
        "dev_seeding_chi2Y":
        seed_confirmTracks_consolidate.dev_seeding_chi2Y_t,
        # "dev_seeding_chi2X":
        # seed_confirmTracks_consolidate.dev_seeding_chi2X_t,
        # "dev_seeding_nY":
        # seed_confirmTracks_consolidate.dev_seeding_nY_t,
        "host_number_of_reconstructed_seeding_tracks":
        seed_tracks.host_seeding_number_of_tracks_t,
        "dev_offsets_scifi_seeds":
        seed_tracks.dev_offsets_seeding_tracks_t,
        "dev_offsets_scifi_seed_hit_number":
        seeding_copy_track_hit_number.dev_offsets_seeding_hit_number_t,
        "dev_scifi_tracks_view":
        seed_confirmTracks_consolidate.dev_scifi_tracks_view_t,
        "dev_scifi_track_view":
        seed_confirmTracks_consolidate.dev_scifi_track_view_t,
        "dev_scifi_hits_view":
        seed_confirmTracks_consolidate.dev_scifi_hits_view_t,
        "dev_used_scifi_hits":
        seed_confirmTracks_consolidate.dev_used_scifi_hits_t,
        "dev_scifi_multi_event_tracks_view":
        seed_confirmTracks_consolidate.dev_scifi_multi_event_tracks_view_t,
        "dev_scifi_hit_offsets":
        decoded_scifi["dev_scifi_hit_offsets"]
    }


def forward_tracking(with_ut=True):
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
    from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    if with_ut:
        ut_hits = decode_ut()
        ut_tracks = make_ut_tracks(ut_hits, velo_tracks)
        input_tracks = ut_tracks
    else:
        ut_hits = make_dummy_ut_hits()
        input_tracks = velo_tracks
    decoded_scifi = decode_scifi()

    return make_forward_tracks(
        decoded_scifi,
        input_tracks,
        ut_hits,
        velo_tracks["dev_accepted_velo_tracks"],
        with_ut=with_ut)


def seeding_xz():
    decoded_scifi = decode_scifi()
    seeding_tracks = make_seeding_XZ_tracks(decoded_scifi)
    alg = seeding_tracks["seed_xz_tracks"]
    return alg


def seeding():
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    alg = seeding_tracks["dev_scifi_tracks_view"]
    return alg
