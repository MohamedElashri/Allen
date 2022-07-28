###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import (
    data_provider_t, host_prefix_sum_t, scifi_calculate_cluster_count_t,
    scifi_pre_decode_t, scifi_raw_bank_decoder_t, ut_select_velo_tracks_t,
    lf_search_initial_windows_t, lf_triplet_seeding_t, lf_create_tracks_t,
    lf_quality_filter_length_t, lf_quality_filter_t,
    scifi_copy_track_hit_number_t, scifi_consolidate_tracks_t, get_type_id_t,
    seed_xz_t, seed_confirmTracks_t, seeding_copy_track_hit_number_t,
    seed_confirmTracks_consolidate_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenConf.velo_reconstruction import run_velo_kalman_filter


@configurable
def decode_scifi():
    number_of_events = initialize_number_of_events()
    scifi_banks = make_algorithm(
        data_provider_t, name="scifi_banks", bank_type="FTCluster")

    scifi_calculate_cluster_count = make_algorithm(
        scifi_calculate_cluster_count_t,
        name="scifi_calculate_cluster_count",
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    prefix_sum_scifi_hits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_scifi_hits",
        dev_input_buffer_t=scifi_calculate_cluster_count.dev_scifi_hit_count_t)

    scifi_pre_decode = make_algorithm(
        scifi_pre_decode_t,
        name="scifi_pre_decode",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_accumulated_number_of_scifi_hits_t=prefix_sum_scifi_hits.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    scifi_raw_bank_decoder = make_algorithm(
        scifi_raw_bank_decoder_t,
        name="scifi_raw_bank_decoder",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_scifi_hits_t=prefix_sum_scifi_hits.
        host_total_sum_holder_t,
        dev_scifi_raw_input_t=scifi_banks.dev_raw_banks_t,
        dev_scifi_raw_input_offsets_t=scifi_banks.dev_raw_offsets_t,
        dev_scifi_raw_input_sizes_t=scifi_banks.dev_raw_sizes_t,
        dev_scifi_hit_offsets_t=prefix_sum_scifi_hits.dev_output_buffer_t,
        dev_cluster_references_t=scifi_pre_decode.dev_cluster_references_t,
        host_raw_bank_version_t=scifi_banks.host_raw_bank_version_t)

    return {
        "dev_scifi_hit_counts":
        scifi_calculate_cluster_count.dev_scifi_hit_count_t,
        "host_number_of_scifi_hits":
        prefix_sum_scifi_hits.host_total_sum_holder_t,
        "dev_scifi_hits":
        scifi_raw_bank_decoder.dev_scifi_hits_t,
        "dev_scifi_hit_offsets":
        prefix_sum_scifi_hits.dev_output_buffer_t,
        "host_number_of_scifi_hits":
        prefix_sum_scifi_hits.host_total_sum_holder_t
    }


@configurable
def make_forward_tracks(decoded_scifi, input_tracks, with_ut=True):
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
        maximum_number_of_triplets_per_warp = 64
        chi2_max_triplet_single = 8.
        z_mag_difference = 10.
        #create tracks
        max_triplets_per_input_track = 12
        chi2_max_extrapolation_to_x_layers_single = 2.
        uv_hits_chi2_factor = 50.
        #quality factor
        max_diff_ty_window = 0.02
    else:
        velo_tracks = input_tracks
        dev_offsets_all_velo_tracks = velo_tracks[
            "dev_offsets_all_velo_tracks"]
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
        maximum_number_of_triplets_per_warp = 64
        chi2_max_triplet_single = 2.0
        z_mag_difference = 12.
        #create tracks
        max_triplets_per_input_track = 20
        chi2_max_extrapolation_to_x_layers_single = 0.5
        uv_hits_chi2_factor = 15.
        #quality factor
        max_diff_ty_window = 0.003

    dev_offsets_all_velo_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
    host_number_of_reconstructed_velo_tracks = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_accepted_velo_tracks = velo_tracks["dev_accepted_velo_tracks"]

    # The preexisting will be deduplicated in UT-ful
    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name="ut_select_velo_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks)

    # With or without UT (get type if of input_track_views)
    get_type_id = make_algorithm(
        get_type_id_t, name="get_type_id", dev_imec_t=input_track_views)

    lf_search_initial_windows = make_algorithm(
        lf_search_initial_windows_t,
        name="lf_search_initial_windows",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        dev_tracks_view_t=input_track_views,
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
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
        name="lf_triplet_seeding",
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
        maximum_number_of_triplets_per_warp=maximum_number_of_triplets_per_warp,
        chi2_max_triplet_single=chi2_max_triplet_single,
        z_mag_difference=z_mag_difference,
        dev_scifi_lf_number_of_tracks_t=lf_search_initial_windows.
        dev_scifi_lf_number_of_tracks_t,
        dev_scifi_lf_tracks_indices_t=lf_search_initial_windows.
        dev_scifi_lf_tracks_indices_t,
        host_track_type_id_t=get_type_id.host_type_id_t)

    lf_create_tracks = make_algorithm(
        lf_create_tracks_t,
        name="lf_create_tracks",
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
        uv_hits_chi2_factor=uv_hits_chi2_factor,
        max_triplets_per_input_track=max_triplets_per_input_track,
        maximum_number_of_triplets_per_warp=maximum_number_of_triplets_per_warp,
        dev_scifi_lf_number_of_tracks_t=lf_search_initial_windows.
        dev_scifi_lf_number_of_tracks_t,
        dev_scifi_lf_tracks_indices_t=lf_search_initial_windows.
        dev_scifi_lf_tracks_indices_t,
        host_track_type_id_t=get_type_id.host_type_id_t)

    lf_quality_filter_length = make_algorithm(
        lf_quality_filter_length_t,
        name="lf_quality_filter_length",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_input_tracks_t=
        host_number_of_reconstructed_input_tracks,
        dev_tracks_view_t=input_track_views,
        dev_scifi_lf_tracks_t=lf_create_tracks.dev_scifi_lf_tracks_t,
        dev_scifi_lf_atomics_t=lf_create_tracks.dev_scifi_lf_atomics_t,
        dev_scifi_lf_parametrization_t=lf_create_tracks.
        dev_scifi_lf_parametrization_t,
        maximum_number_of_candidates_per_ut_track=max_triplets_per_input_track)

    lf_quality_filter = make_algorithm(
        lf_quality_filter_t,
        name="lf_quality_filter",
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
        max_diff_ty_window=max_diff_ty_window)

    prefix_sum_forward_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_forward_tracks",
        dev_input_buffer_t=lf_quality_filter.dev_atomics_scifi_t)

    scifi_copy_track_hit_number = make_algorithm(
        scifi_copy_track_hit_number_t,
        name="scifi_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t,
        dev_offsets_input_tracks_t=dev_offsets_input_tracks,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_offsets_long_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t)

    prefix_sum_scifi_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_scifi_track_hit_number",
        dev_input_buffer_t=scifi_copy_track_hit_number.
        dev_scifi_track_hit_number_t)

    scifi_consolidate_tracks = make_algorithm(
        scifi_consolidate_tracks_t,
        name="scifi_consolidate_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_scifi_tracks_t=
        prefix_sum_scifi_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_offsets_long_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t,
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t,
        dev_scifi_tracks_t=lf_quality_filter.dev_scifi_tracks_t,
        dev_scifi_lf_parametrization_consolidate_t=lf_quality_filter.
        dev_scifi_lf_parametrization_consolidate_t,
        dev_tracks_view_t=input_track_views,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"])

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
        prefix_sum_forward_tracks.host_total_sum_holder_t,
        "dev_offsets_long_tracks":
        prefix_sum_forward_tracks.dev_output_buffer_t,
        "dev_offsets_scifi_track_hit_number":
        prefix_sum_scifi_track_hit_number.dev_output_buffer_t,
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
        scifi_consolidate_tracks.dev_scifi_hits_view_t
    }


@configurable
def make_seeding_XZ_tracks(decoded_scifi):
    number_of_events = initialize_number_of_events()

    seed_xz_tracks = make_algorithm(
        seed_xz_t,
        name="seed_xz",
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
def make_seeding_tracks(decoded_scifi, xz_tracks):
    number_of_events = initialize_number_of_events()

    seed_tracks = make_algorithm(
        seed_confirmTracks_t,
        name="seed_confirmTracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_count_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_seeding_tracksXZ_t=xz_tracks["seed_xz_tracks"],
        dev_seeding_number_of_tracksXZ_part0_t=xz_tracks[
            "seed_xz_tracks_part0"],
        dev_seeding_number_of_tracksXZ_part1_t=xz_tracks[
            "seed_xz_tracks_part1"],
    )

    prefix_sum_seeding_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_seeding_track",
        dev_input_buffer_t=seed_tracks.dev_seeding_confirmTracks_atomics_t)

    seeding_copy_track_hit_number = make_algorithm(
        seeding_copy_track_hit_number_t,
        name="seeding_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_seeding_tracks_t=prefix_sum_seeding_tracks
        .host_total_sum_holder_t,
        dev_seeding_tracks_t=seed_tracks.dev_seeding_tracks_t,
        dev_seeding_atomics_t=prefix_sum_seeding_tracks.dev_output_buffer_t,
        dev_event_list_t=number_of_events["dev_number_of_events"])

    prefix_sum_seeding_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_seeding_track_hit_number",
        dev_input_buffer_t=seeding_copy_track_hit_number.
        dev_seeding_track_hit_number_t)

    seed_confirmTracks_consolidate = make_algorithm(
        seed_confirmTracks_consolidate_t,
        name="scifi_consolidate_seeds",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_scifi_tracks_t=
        prefix_sum_seeding_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_seeding_tracks_t=prefix_sum_seeding_tracks
        .host_total_sum_holder_t,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_offsets_seeding_tracks_t=prefix_sum_seeding_tracks.
        dev_output_buffer_t,
        dev_offsets_seeding_hit_number_t=prefix_sum_seeding_track_hit_number.
        dev_output_buffer_t,
        dev_seeding_tracks_t=seed_tracks.dev_seeding_tracks_t)

    return {
        "seed_tracks":
        seed_tracks.dev_seeding_tracks_t,
        "seed_atomics":
        seed_tracks.dev_seeding_confirmTracks_atomics_t,
        "dev_seeding_track_hits":
        seed_confirmTracks_consolidate.dev_seeding_track_hits_t,
        "dev_seeding_states":
        seed_confirmTracks_consolidate.dev_seeding_states_t,
        "dev_seeding_qop":
        seed_confirmTracks_consolidate.dev_seeding_qop_t,
        "host_number_of_reconstructed_seeding_tracks":
        prefix_sum_seeding_tracks.host_total_sum_holder_t,
        "dev_offsets_scifi_seeds":
        prefix_sum_seeding_tracks.dev_output_buffer_t,
        "dev_offsets_scifi_seed_hit_number":
        prefix_sum_seeding_track_hit_number.dev_output_buffer_t,
        "dev_scifi_tracks_view":
        seed_confirmTracks_consolidate.dev_scifi_tracks_view_t,
        "dev_scifi_track_view":
        seed_confirmTracks_consolidate.dev_scifi_track_view_t,
        "dev_scifi_hits_view":
        seed_confirmTracks_consolidate.dev_scifi_hits_view_t
    }


def forward_tracking():
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
    from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    long_tracks = make_forward_tracks(decoded_scifi, ut_tracks)
    alg = long_tracks["dev_scifi_track_hits"].producer
    return alg


def seeding_xz():
    decoded_scifi = decode_scifi()
    seeding_tracks = make_seeding_XZ_tracks(decoded_scifi)
    alg = seeding_tracks["seed_xz_tracks"]
    return alg


def seeding():
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    alg = seeding_tracks["seed_tracks"]
    return alg
