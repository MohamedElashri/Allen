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
from AllenCore.algorithms import ut_compress_and_calculate_keys_t
from AllenCore.algorithms import (
    data_provider_t, ut_calculate_number_of_hits_t, ut_select_velo_tracks_t,
    compass_ut_define_candidates_t, compass_ut_find_tracks_t,
    compass_ut_select_tracks_t, compass_ut_fit_tracks_t,
    ut_copy_track_hit_number_t, ut_consolidate_tracks_t,
    ut_cluster_and_pre_decode_t, ut_find_permutation_t, ut_decode_in_order_t,
    create_reduced_ut_hits_container_t, ut_decoding_get_bank_offsets_t,
    ut_decoding_get_hit_offsets_t, ut_decoding_predecode_hits_t,
    ut_decoding_hit_clustering_t, ut_decoding_decode_clusters_t)
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events, make_dummy
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


def create_reduced_ut_container(decoded_ut, dev_used_ut_hits_offsets):
    number_of_events = initialize_number_of_events()

    create_reduced_ut_hit_container = make_algorithm(
        create_reduced_ut_hits_container_t,
        name="create_reduced_ut_hit_container_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_used_ut_hits_offsets_t=dev_used_ut_hits_offsets,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hit_offsets_input_t=decoded_ut["dev_ut_hit_offsets"],
        dev_ut_hits_input_t=decoded_ut["dev_ut_hits"])

    reduced_ut_hit_container = {
        "host_accumulated_number_of_ut_hits":
        create_reduced_ut_hit_container.host_number_of_ut_hits_t,
        "dev_ut_hits":
        create_reduced_ut_hit_container.dev_ut_hits_t,
        "dev_ut_hit_offsets":
        create_reduced_ut_hit_container.dev_ut_hit_offsets_t,
    }

    return reduced_ut_hit_container


def decode_ut_v1(
        cluster_ut_hits=True,
        position_method=0,  # 0 = AdcWeighting, 1 = GeoWeighting
        max_cluster_size=128,
        save_clusters_above_max=False):
    number_of_events = initialize_number_of_events()
    ut_banks = make_algorithm(data_provider_t, name='ut_banks', bank_type="UT")

    ut_calculate_number_of_hits = make_algorithm(
        ut_calculate_number_of_hits_t,
        name='ut_calculate_number_of_hits_{hash}',
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_raw_input_types_t=ut_banks.dev_raw_types_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t)

    ut_cluster_and_pre_decode = make_algorithm(
        ut_cluster_and_pre_decode_t,
        name='ut_cluster_and_pre_decode_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_ut_hits_t=ut_calculate_number_of_hits.
        host_total_sum_holder_t,
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_raw_input_types_t=ut_banks.dev_raw_types_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
        dev_ut_hit_offsets_t=ut_calculate_number_of_hits.dev_ut_hit_offsets_t,
        dev_ut_nonempty_channels_t=ut_calculate_number_of_hits.
        dev_ut_nonempty_channels_t,
        dev_ut_number_of_nonempty_channels_t=ut_calculate_number_of_hits.
        dev_ut_number_of_nonempty_channels_t,
        # UT clustering configurables
        cluster_ut_hits=cluster_ut_hits,
        position_method=position_method,
        max_cluster_size=max_cluster_size,
        save_clusters_above_max=save_clusters_above_max
    )  # False to be consistent with HLT2

    ut_compress_and_calculate_keys = make_algorithm(
        ut_compress_and_calculate_keys_t,
        name='ut_compress_and_calculate_keys_{hash}',
        host_accumulated_number_of_ut_clusters_t=ut_cluster_and_pre_decode.
        host_total_sum_holder_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hit_offsets_t=ut_calculate_number_of_hits.dev_ut_hit_offsets_t,
        dev_ut_cluster_offsets_t=ut_cluster_and_pre_decode.
        dev_ut_cluster_offsets_t,
        dev_ut_uncompressed_hits_t=ut_cluster_and_pre_decode.
        dev_ut_pre_decoded_hits_t,
        dev_ut_tiebreak_t=ut_cluster_and_pre_decode.dev_ut_tiebreak_t)

    ut_find_permutation = make_algorithm(
        ut_find_permutation_t,
        name='ut_find_permutation_{hash}',
        host_accumulated_number_of_ut_clusters_t=ut_cluster_and_pre_decode.
        host_total_sum_holder_t,
        dev_ut_sort_keys_t=ut_compress_and_calculate_keys.dev_ut_sort_keys_t,
        dev_ut_cluster_offsets_t=ut_cluster_and_pre_decode.
        dev_ut_cluster_offsets_t)

    ut_decode_in_order = make_algorithm(
        ut_decode_in_order_t,
        name='ut_decode_in_order_{hash}',
        host_accumulated_number_of_ut_clusters_t=ut_cluster_and_pre_decode.
        host_total_sum_holder_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_pre_decoded_hits_t=ut_compress_and_calculate_keys.
        dev_ut_compressed_hits_t,
        dev_ut_permutations_t=ut_find_permutation.dev_ut_permutations_t,
        dev_ut_cluster_offsets_t=ut_cluster_and_pre_decode.
        dev_ut_cluster_offsets_t)

    return {
        "dev_ut_hits":
        ut_decode_in_order.dev_ut_hits_t,
        "dev_ut_hit_offsets":
        ut_cluster_and_pre_decode.dev_ut_cluster_offsets_t,
        "host_accumulated_number_of_ut_hits":
        ut_cluster_and_pre_decode.host_total_sum_holder_t
    }


def decode_ut_v2(
        cluster_ut_hits=True,
        position_method=0,  # 0 = AdcWeighting, 1 = GeoWeighting
        max_cluster_size=128,
        save_clusters_above_max=False):
    number_of_events = initialize_number_of_events()
    ut_banks = make_algorithm(data_provider_t, name='ut_banks', bank_type="UT")

    ut_decoding_get_bank_offsets = make_algorithm(
        ut_decoding_get_bank_offsets_t,
        name='ut_decoding_get_bank_offsets_{hash}',
        # verbosity=5,
        block_dim=(256, 1, 1),
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # RawBanks
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_raw_input_types_t=ut_banks.dev_raw_types_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
    )

    ut_decoding_get_hit_offsets = make_algorithm(
        ut_decoding_get_hit_offsets_t,
        name='ut_decoding_get_hit_offsets_{hash}',
        # verbosity=5,
        block_dim=(256, 1, 1),
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # RawBanks
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_raw_input_types_t=ut_banks.dev_raw_types_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
        # Bank offsets
        host_total_number_of_ut_banks_t=ut_decoding_get_bank_offsets.
        host_total_number_of_ut_banks_t,
        dev_ut_banks_offsets_t=ut_decoding_get_bank_offsets.
        dev_ut_banks_offsets_t,
    )

    ut_decoding_predecode_hits = make_algorithm(
        ut_decoding_predecode_hits_t,
        name='ut_decoding_predecode_hits_{hash}',
        # verbosity=5,
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # RawBanks
        dev_ut_raw_input_t=ut_banks.dev_raw_banks_t,
        dev_ut_raw_input_offsets_t=ut_banks.dev_raw_offsets_t,
        dev_ut_raw_input_sizes_t=ut_banks.dev_raw_sizes_t,
        dev_ut_raw_input_types_t=ut_banks.dev_raw_types_t,
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
        # Bank offsets
        dev_ut_banks_offsets_t=ut_decoding_get_bank_offsets.
        dev_ut_banks_offsets_t,
        # Hit offsets
        host_total_number_of_ut_hits_t=ut_decoding_get_hit_offsets.
        host_total_number_of_ut_hits_t,
        dev_ut_lanes_hit_offsets_t=ut_decoding_get_hit_offsets.
        dev_ut_lanes_hit_offsets_t,
    )

    ut_decoding_hit_clustering = make_algorithm(
        ut_decoding_hit_clustering_t,
        name='ut_decoding_hit_clustering_{hash}',
        # verbosity=5,
        # Basics
        cluster_ut_hits=cluster_ut_hits,
        position_method=position_method,
        max_cluster_size=max_cluster_size,
        save_clusters_above_max=save_clusters_above_max,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Rawbank
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
        # Hit offsets
        host_total_number_of_ut_hits_t=ut_decoding_get_hit_offsets.
        host_total_number_of_ut_hits_t,
        # Predecoding
        dev_ut_predecoded_hits_t=ut_decoding_predecode_hits.
        dev_ut_predecoded_hits_t,
        dev_ut_hits_strip_info_t=ut_decoding_predecode_hits.
        dev_ut_hits_strip_info_t,
        dev_ut_predecoded_event_offsets_t=ut_decoding_predecode_hits.
        dev_ut_predecoded_event_offsets_t,
    )

    ut_decoding_decode_clusters = make_algorithm(
        ut_decoding_decode_clusters_t,
        name='ut_decoding_decode_clusters_{hash}',
        # verbosity=5,
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Rawbank
        host_raw_bank_version_t=ut_banks.host_raw_bank_version_t,
        # Hit offsets
        # host_total_number_of_ut_hits_t=ut_decoding_get_hit_offsets.
        # host_total_number_of_ut_hits_t,
        # Clustering
        host_ut_num_clusters_t=ut_decoding_hit_clustering.
        host_ut_num_clusters_t,
        dev_ut_clusters_t=ut_decoding_hit_clustering.dev_ut_clusters_t,
        dev_ut_clusters_sector_group_offsets_t=ut_decoding_hit_clustering.
        dev_ut_clusters_sector_group_offsets_t,
        dev_ut_clusters_permutations_t=ut_decoding_hit_clustering.
        dev_ut_clusters_permutations_t,
    )

    return {
        # Algorithms
        "ut_decoding_get_bank_offsets":
        ut_decoding_get_bank_offsets,
        "ut_decoding_get_hit_offsets":
        ut_decoding_get_hit_offsets,
        "ut_decoding_predecode_hits":
        ut_decoding_predecode_hits,
        "ut_decoding_hit_clustering":
        ut_decoding_hit_clustering,
        "ut_decoding_decode_clusters":
        ut_decoding_decode_clusters,
        # Output
        "dev_ut_hits":
        ut_decoding_decode_clusters.dev_ut_hits_t,
        "dev_ut_hit_offsets":
        ut_decoding_hit_clustering.dev_ut_clusters_sector_group_offsets_t,
        "host_accumulated_number_of_ut_hits":
        ut_decoding_hit_clustering.host_ut_num_clusters_t,
    }


@configurable
def decode_ut(
        cluster_ut_hits=True,
        position_method=0,  # 0 = AdcWeighting, 1 = GeoWeighting
        max_cluster_size=128,
        save_clusters_above_max=False,
        decoder_version=2):
    """Decodes UT hits.

    Arguments:
    cluster_ut_hits: Enable UT hit clustering.
    position_method: Clustering method. 0 = AdcWeighting, 1 = GeoWeighting.
    max_cluster_size: Maximum cluster size for UT clustering (128 is recommended by the UT group).
    save_clusters_above_max: Whether to keep clusters larger than max_cluster_size.
    decoder_version: Decoder version (not the UT rawbank version).
      - 1 = Legacy UT decoding, where each thread processes a non-empty UT lane.
      - 2 = New UT decoding, where each thread processes a UT cluster (a range of UT hits).
    """

    decoders = {1: decode_ut_v1, 2: decode_ut_v2}
    decoder = decoders[decoder_version]

    return decoder(
        cluster_ut_hits=cluster_ut_hits,
        position_method=position_method,
        max_cluster_size=max_cluster_size,
        save_clusters_above_max=save_clusters_above_max,
    )


@configurable
def make_ut_tracks(decoded_ut,
                   velo_tracks,
                   dev_accepted_velo_tracks=None,
                   restricted=True):
    number_of_events = initialize_number_of_events()
    velo_states = run_velo_kalman_filter(velo_tracks)

    host_number_of_reconstructed_velo_tracks_t = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_offsets_all_velo_tracks_t = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number_t = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    if not dev_accepted_velo_tracks:
        dev_accepted_velo_tracks = velo_tracks["dev_accepted_velo_tracks"]

    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name='ut_select_velo_tracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks_t,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=dev_accepted_velo_tracks)

    # TODO: Tune min LD parameter
    ut_search_windows_min_momentum = 1250.0
    ut_search_windows_min_pt = 275.0
    compass_ut_min_momentum_final = 1500.0
    compass_ut_min_pt_final = 400.0

    if not restricted:
        ut_search_windows_min_momentum = 1250.0
        ut_search_windows_min_pt = 200.0
        compass_ut_min_momentum_final = 1500.0
        compass_ut_min_pt_final = 250.0

    compass_ut_define_candidates = make_algorithm(
        compass_ut_define_candidates_t,
        name="compass_ut_define_candidates_{hash}",
        # verbosity=5,
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # UT
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        # VELO
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        # Selection
        host_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        host_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_offsets_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_offsets_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        # Constants
        min_momentum=ut_search_windows_min_momentum,
        min_pt=ut_search_windows_min_pt,
    )

    compass_ut_find_tracks = make_algorithm(
        compass_ut_find_tracks_t,
        name="compass_ut_find_tracks_{hash}",
        # verbosity=5,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        host_number_of_ut_track_candidate_t=compass_ut_define_candidates.
        host_number_of_ut_track_candidate_t,
        dev_ut_track_consolidate_candidate_offset_t=compass_ut_define_candidates
        .dev_ut_track_consolidate_candidate_offset_t,
        dev_ut_track_consolidate_candidates_t=compass_ut_define_candidates.
        dev_ut_track_consolidate_candidates_t,
        # xtol_axial=2.0,
        # xtol_stereo=4.0,
        # ytol=1.0,
    )

    compass_ut_select_tracks = make_algorithm(
        compass_ut_select_tracks_t,
        name='compass_ut_select_tracks_{hash}',
        # verbosity=5,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_ut_track_consolidate_candidate_offset_t=compass_ut_define_candidates
        .dev_ut_track_consolidate_candidate_offset_t,
        host_number_of_ut_track_output_tracks_t=compass_ut_find_tracks.
        host_number_of_ut_track_output_tracks_t,
        dev_ut_track_output_offset_t=compass_ut_find_tracks.
        dev_ut_track_output_offset_t,
        dev_ut_track_output_tracks_t=compass_ut_find_tracks.
        dev_ut_track_output_tracks_t)

    compass_ut_fit_tracks = make_algorithm(
        compass_ut_fit_tracks_t,
        name="compass_ut_fit_tracks_{hash}",
        # verbosity=5,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Input
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_endvelo_states_view"],
        # From tracking
        host_number_of_ut_track_selected_tracks_t=compass_ut_select_tracks.
        host_number_of_ut_track_selected_tracks_t,
        dev_ut_track_output_offset_t=compass_ut_find_tracks.
        dev_ut_track_output_offset_t,
        dev_ut_track_selected_offset_t=compass_ut_select_tracks.
        dev_ut_track_selected_offset_t,
        dev_ut_track_selected_tracks_t=compass_ut_select_tracks.
        dev_ut_track_selected_tracks_t,
        # Properties
        min_momentum_final=compass_ut_min_momentum_final,
        min_pt_final=compass_ut_min_pt_final,
        min_ghost_prob_3_hit=0.8,
        min_ghost_prob_4_hit=0.5,
    )

    ut_copy_track_hit_number = make_algorithm(
        ut_copy_track_hit_number_t,
        name='ut_copy_track_hit_number_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_ut_track_hits_t=compass_ut_fit_tracks.
        host_number_of_ut_track_hits_t,
        dev_ut_track_selected_offset_t=compass_ut_select_tracks.
        dev_ut_track_selected_offset_t,
        dev_ut_track_hits_offset_t=compass_ut_fit_tracks.
        dev_ut_track_hits_offset_t,
        dev_ut_track_hits_t=compass_ut_fit_tracks.dev_ut_track_hits_t)

    ut_consolidate_tracks = make_algorithm(
        ut_consolidate_tracks_t,
        name='ut_consolidate_tracks_{hash}',
        host_accumulated_number_of_ut_hits_t=decoded_ut[
            "host_accumulated_number_of_ut_hits"],
        host_number_of_reconstructed_ut_tracks_t=compass_ut_fit_tracks.
        host_number_of_ut_track_hits_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_ut_tracks_t=ut_copy_track_hit_number
        .host_accumulated_number_of_hits_in_ut_tracks_t,
        dev_ut_hits_t=decoded_ut["dev_ut_hits"],
        dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
        dev_offsets_ut_tracks_t=compass_ut_fit_tracks.
        dev_ut_track_hits_offset_t,
        dev_input_offsets_ut_tracks_t=compass_ut_select_tracks.
        dev_ut_track_selected_offset_t,
        dev_offsets_ut_track_hit_number_t=ut_copy_track_hit_number.
        dev_offsets_ut_track_hit_number_t,
        dev_ut_tracks_t=compass_ut_fit_tracks.dev_ut_track_hits_t,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"])

    return {
        # Basics
        "velo_tracks":
        velo_tracks,
        "velo_states":
        velo_states,
        # Algorithms
        "compass_ut_define_candidates":
        compass_ut_define_candidates,
        "compass_ut_find_tracks":
        compass_ut_find_tracks,
        "compass_ut_select_tracks":
        compass_ut_select_tracks,
        "compass_ut_fit_tracks":
        compass_ut_fit_tracks,
        "ut_copy_track_hit_number":
        ut_copy_track_hit_number,
        "ut_consolidate_tracks":
        ut_consolidate_tracks,
        "test":
        ut_consolidate_tracks,
        # Host outputs
        'host_number_of_reconstructed_ut_tracks':
        compass_ut_fit_tracks.host_number_of_ut_track_hits_t,
        'host_number_of_hits_of_reconstructed_ut_tracks':
        ut_copy_track_hit_number.
        host_accumulated_number_of_hits_in_ut_tracks_t,
        # Outputs
        "dev_offsets_ut_tracks":
        compass_ut_fit_tracks.dev_ut_track_hits_offset_t,
        "dev_offsets_ut_track_hit_number":
        ut_copy_track_hit_number.dev_offsets_ut_track_hit_number_t,
        "dev_ut_track_view":
        ut_consolidate_tracks.dev_ut_track_view_t,
        "dev_ut_tracks_view":
        ut_consolidate_tracks.dev_ut_tracks_view_t,
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
    }


def ut_tracking():
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    return ut_tracks["dev_ut_tracks_view"]


def make_dummy_ut_hits():

    dummy = make_dummy()

    return {
        "dev_ut_hits": dummy.dev_char_dummy_t,
        "dev_ut_hit_offsets": dummy.dev_unsigned_dummy_t,
        "host_ut_hit_offsets": dummy.host_unsigned_dummy_t,
        "host_accumulated_number_of_ut_hits": dummy.host_sum_dummy_t,
    }
