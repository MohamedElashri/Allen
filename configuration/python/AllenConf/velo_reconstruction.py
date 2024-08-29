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
    data_provider_t, velo_calculate_number_of_candidates_t,
    velo_estimate_input_size_t, velo_masked_clustering_t, velo_sparse_ccl_t,
    velo_sort_by_phi_t, velo_search_by_triplet_t,
    velo_three_hit_tracks_filter_t, velo_copy_track_hit_number_t,
    velo_consolidate_tracks_t, tracks_ACsplit_counters_t, tracks_ACsplit_t,
    velo_kalman_filter_t, count_materialinteraction_candidates_t,
    fill_materialinteraction_candidates_t,
    calculate_number_of_retinaclusters_each_sensor_pair_t,
    decode_retinaclusters_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


@configurable
def decode_velo(retina_decoding=True, use_sparse_ccl=False):
    number_of_events = initialize_number_of_events()

    if retina_decoding:
        velo_banks = make_algorithm(
            data_provider_t, name="velo_banks", bank_type="VP")

        calculate_number_of_retinaclusters_each_sensor_pair = make_algorithm(
            calculate_number_of_retinaclusters_each_sensor_pair_t,
            name="calculate_number_of_retinaclusters_each_sensor_pair",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
            dev_velo_retina_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_retina_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_retina_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_retina_raw_input_types_t=velo_banks.dev_raw_types_t)

        decode_retinaclusters = make_algorithm(
            decode_retinaclusters_t,
            name="decode_retinaclusters",
            host_total_number_of_velo_clusters_t=
            calculate_number_of_retinaclusters_each_sensor_pair.
            host_total_sum_holder_t,
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_velo_retina_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_retina_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_retina_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_retina_raw_input_types_t=velo_banks.dev_raw_types_t,
            dev_retina_bank_index_t=
            calculate_number_of_retinaclusters_each_sensor_pair.
            dev_retina_bank_index_t,
            dev_offsets_each_sensor_pair_size_t=
            calculate_number_of_retinaclusters_each_sensor_pair.
            dev_offsets_each_sensor_pair_size_t,
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t)

        return {
            "dev_sorted_velo_cluster_container":
            decode_retinaclusters.dev_velo_cluster_container_t,
            "dev_module_cluster_num":
            decode_retinaclusters.dev_module_cluster_num_t,
            "dev_offsets_estimated_input_size":
            decode_retinaclusters.dev_offsets_module_pair_cluster_t,
            "host_total_number_of_velo_clusters":
            calculate_number_of_retinaclusters_each_sensor_pair.
            host_total_sum_holder_t,
            "dev_velo_clusters":
            decode_retinaclusters.dev_velo_clusters_t
        }
    else:
        velo_banks = make_algorithm(
            data_provider_t, name="velo_banks", bank_type="VP")

        velo_calculate_number_of_candidates = make_algorithm(
            velo_calculate_number_of_candidates_t,
            name="velo_calculate_number_of_candidates",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
            dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_raw_input_types_t=velo_banks.dev_raw_types_t,
            count_candidates=not use_sparse_ccl)

        if not use_sparse_ccl:
            velo_estimate_input_size = make_algorithm(
                velo_estimate_input_size_t,
                name="velo_estimate_input_size",
                host_number_of_events_t=number_of_events[
                    "host_number_of_events"],
                host_number_of_cluster_candidates_t=
                velo_calculate_number_of_candidates.
                host_number_of_cluster_candidates_t,
                host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
                dev_superpixels_t=velo_calculate_number_of_candidates.
                dev_superpixels_t,
                dev_superpixels_offsets_t=velo_calculate_number_of_candidates.
                dev_superpixels_offsets_t,
                dev_candidates_offsets_t=velo_calculate_number_of_candidates.
                dev_candidates_offsets_t)

            velo_masked_clustering = make_algorithm(
                velo_masked_clustering_t,
                name="velo_masked_clustering",
                host_total_number_of_velo_clusters_t=velo_estimate_input_size.
                host_total_number_of_velo_clusters_t,
                host_number_of_events_t=number_of_events[
                    "host_number_of_events"],
                host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
                dev_superpixels_t=velo_calculate_number_of_candidates.
                dev_superpixels_t,
                dev_superpixels_offsets_t=velo_calculate_number_of_candidates.
                dev_superpixels_offsets_t,
                dev_offsets_estimated_input_size_t=velo_estimate_input_size.
                dev_offsets_estimated_input_size_t,
                dev_module_candidate_num_t=velo_estimate_input_size.
                dev_module_candidate_num_t,
                dev_cluster_candidates_t=velo_estimate_input_size.
                dev_cluster_candidates_t,
                dev_candidates_offsets_t=velo_calculate_number_of_candidates.
                dev_candidates_offsets_t,
                dev_number_of_events_t=number_of_events[
                    "dev_number_of_events"],
                dev_velo_bank_index_t=velo_calculate_number_of_candidates.
                dev_velo_bank_index_t)

            velo_sort_by_phi = make_algorithm(
                velo_sort_by_phi_t,
                name="velo_sort_by_phi",
                host_number_of_events_t=number_of_events[
                    "host_number_of_events"],
                host_total_number_of_velo_clusters_t=velo_estimate_input_size.
                host_total_number_of_velo_clusters_t,
                dev_offsets_estimated_input_size_t=velo_estimate_input_size.
                dev_offsets_estimated_input_size_t,
                dev_module_cluster_num_t=velo_masked_clustering.
                dev_module_cluster_num_t,
                dev_velo_cluster_container_t=velo_masked_clustering.
                dev_velo_cluster_container_t,
                dev_number_of_events_t=number_of_events[
                    "dev_number_of_events"],
                dev_velo_clusters_t=velo_masked_clustering.dev_velo_clusters_t)

            return {
                "dev_sorted_velo_cluster_container":
                velo_sort_by_phi.dev_sorted_velo_cluster_container_t,
                "dev_module_cluster_num":
                velo_masked_clustering.dev_module_cluster_num_t,
                "dev_offsets_estimated_input_size":
                velo_estimate_input_size.dev_offsets_estimated_input_size_t,
                "host_total_number_of_velo_clusters":
                velo_estimate_input_size.host_total_number_of_velo_clusters_t,
                "dev_velo_clusters":
                velo_masked_clustering.dev_velo_clusters_t
            }

        else:
            velo_sparse_ccl = make_algorithm(
                velo_sparse_ccl_t,
                name="velo_sparse_ccl",
                host_number_of_events_t=number_of_events[
                    "host_number_of_events"],
                host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
                dev_superpixels_t=velo_calculate_number_of_candidates.
                dev_superpixels_t,
                dev_superpixels_offsets_t=velo_calculate_number_of_candidates.
                dev_superpixels_offsets_t,
                host_total_number_of_superpixels_t=
                velo_calculate_number_of_candidates.
                host_total_number_of_superpixels_t,
                dev_number_of_events_t=number_of_events[
                    "dev_number_of_events"],
            )

            return {
                "dev_sorted_velo_cluster_container":
                velo_sparse_ccl.dev_sorted_velo_cluster_container_t,
                "dev_module_cluster_num":
                velo_sparse_ccl.dev_module_pair_cluster_num_t,
                "dev_offsets_estimated_input_size":
                velo_sparse_ccl.dev_module_pair_cluster_offset_t,
                "host_total_number_of_velo_clusters":
                velo_sparse_ccl.host_total_number_of_clusters_t,
                "dev_velo_clusters":
                velo_sparse_ccl.dev_velo_clusters_t
            }


def make_pr_velo_tracks(decoded_velo):

    number_of_events = initialize_number_of_events()
    dev_module_cluster_num = decoded_velo["dev_module_cluster_num"]
    host_total_number_of_velo_clusters = decoded_velo[
        "host_total_number_of_velo_clusters"]
    dev_sorted_velo_cluster_container = decoded_velo[
        "dev_sorted_velo_cluster_container"]
    dev_offsets_estimated_input_size = decoded_velo[
        "dev_offsets_estimated_input_size"]

    velo_search_by_triplet = make_algorithm(
        velo_search_by_triplet_t,
        name="velo_search_by_triplet",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_module_cluster_num_t=dev_module_cluster_num,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        max_skipped_modules=1,
    )

    velo_three_hit_tracks_filter = make_algorithm(
        velo_three_hit_tracks_filter_t,
        name="velo_three_hit_tracks_filter",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_atomics_velo_t=velo_search_by_triplet.dev_atomics_velo_t,
        dev_hit_used_t=velo_search_by_triplet.dev_hit_used_t,
        dev_three_hit_tracks_input_t=velo_search_by_triplet.
        dev_three_hit_tracks_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
    )

    velo_copy_track_hit_number = make_algorithm(
        velo_copy_track_hit_number_t,
        name="velo_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_velo_tracks_at_least_four_hits_t=velo_search_by_triplet.
        host_number_of_velo_tracks_at_least_four_hits_t,
        host_number_of_three_hit_tracks_filtered_t=velo_three_hit_tracks_filter
        .host_number_of_three_hit_tracks_filtered_t,
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t,
        dev_offsets_velo_tracks_t=velo_search_by_triplet.
        dev_offsets_velo_tracks_t,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        velo_three_hit_tracks_filter.
        dev_offsets_number_of_three_hit_tracks_filtered_t,
    )
    return {
        "dev_offsets_velo_track_hit_number":
        velo_copy_track_hit_number.dev_offsets_velo_track_hit_number_t,
        "host_accumulated_number_of_hits_in_velo_tracks":
        velo_copy_track_hit_number.
        host_accumulated_number_of_hits_in_velo_tracks_t,
        "host_number_of_reconstructed_velo_tracks":
        velo_copy_track_hit_number.host_number_of_reconstructed_velo_tracks_t,
        "host_number_of_three_hit_tracks_filtered":
        velo_three_hit_tracks_filter.
        host_number_of_three_hit_tracks_filtered_t,
        "dev_offsets_all_velo_tracks":
        velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        "dev_tracks":
        velo_search_by_triplet.dev_tracks_t,
        "dev_three_hit_tracks_output":
        velo_three_hit_tracks_filter.dev_three_hit_tracks_output_t,
        "dev_offsets_number_of_three_hit_tracks_filtered":
        velo_three_hit_tracks_filter.
        dev_offsets_number_of_three_hit_tracks_filtered_t,
    }


def make_velo_tracks(decoded_velo):
    number_of_events = initialize_number_of_events()
    velo_tracks_preparation = make_pr_velo_tracks(decoded_velo)
    dev_sorted_velo_cluster_container = decoded_velo[
        "dev_sorted_velo_cluster_container"]
    dev_offsets_estimated_input_size = decoded_velo[
        "dev_offsets_estimated_input_size"]

    velo_consolidate_tracks = make_algorithm(
        velo_consolidate_tracks_t,
        name="velo_consolidate_tracks",
        host_accumulated_number_of_hits_in_velo_tracks_t=
        velo_tracks_preparation[
            "host_accumulated_number_of_hits_in_velo_tracks"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks_preparation[
            "host_number_of_reconstructed_velo_tracks"],
        host_number_of_three_hit_tracks_filtered_t=velo_tracks_preparation[
            "host_number_of_three_hit_tracks_filtered"],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks_preparation[
            "dev_offsets_all_velo_tracks"],
        dev_tracks_t=velo_tracks_preparation["dev_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks_preparation[
            "dev_offsets_velo_track_hit_number"],
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=velo_tracks_preparation[
            "dev_three_hit_tracks_output"],
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        velo_tracks_preparation[
            "dev_offsets_number_of_three_hit_tracks_filtered"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
    )

    return {
        "host_number_of_reconstructed_velo_tracks":
        velo_tracks_preparation["host_number_of_reconstructed_velo_tracks"],
        "dev_velo_track_hits":
        velo_consolidate_tracks.dev_velo_track_hits_t,
        "dev_offsets_all_velo_tracks":
        velo_tracks_preparation["dev_offsets_all_velo_tracks"],
        "dev_offsets_velo_track_hit_number":
        velo_tracks_preparation["dev_offsets_velo_track_hit_number"],
        "dev_accepted_velo_tracks":
        velo_consolidate_tracks.dev_accepted_velo_tracks_t,
        "dev_velo_tracks_view":
        velo_consolidate_tracks.dev_velo_tracks_view_t,
        "dev_velo_multi_event_tracks_view":
        velo_consolidate_tracks.dev_velo_multi_event_tracks_view_t,
        "dev_imec_velo_tracks":
        velo_consolidate_tracks.dev_imec_velo_tracks_t,

        # Needed for long track particles dependencies.
        "dev_velo_track_view":
        velo_consolidate_tracks.dev_velo_track_view_t,
        "dev_velo_hits_view":
        velo_consolidate_tracks.dev_velo_hits_view_t
    }


def make_velo_tracks_ACsplit(decoded_velo, split_alg="A/C split"):

    number_of_events = initialize_number_of_events()
    velo_tracks_preparation = make_pr_velo_tracks(decoded_velo)

    host_total_number_of_velo_clusters = decoded_velo[
        "host_total_number_of_velo_clusters"]
    dev_sorted_velo_cluster_container = decoded_velo[
        "dev_sorted_velo_cluster_container"]
    dev_offsets_estimated_input_size = decoded_velo[
        "dev_offsets_estimated_input_size"]

    tracks_ACsplit_counters = make_algorithm(
        tracks_ACsplit_counters_t,
        name="tracks_ACsplit_counters",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_tracks_t=velo_tracks_preparation["dev_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_three_hit_tracks_output_t=velo_tracks_preparation[
            "dev_three_hit_tracks_output"],
        dev_offsets_all_velo_tracks_t=velo_tracks_preparation[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        velo_tracks_preparation[
            "dev_offsets_number_of_three_hit_tracks_filtered"],
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        splitting_algorithm=split_alg)

    tracks_ACsplit = make_algorithm(
        tracks_ACsplit_t,
        name="tracks_ACsplit",
        host_number_of_reconstructed_velo_tracks_A_side_t=tracks_ACsplit_counters
        .host_number_of_reconstructed_velo_tracks_A_side_t,
        host_number_of_reconstructed_velo_tracks_C_side_t=tracks_ACsplit_counters
        .host_number_of_reconstructed_velo_tracks_C_side_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_tracks_t=velo_tracks_preparation["dev_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks_preparation[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_tracks_A_side_t=tracks_ACsplit_counters.
        dev_offsets_velo_tracks_A_side_t,
        dev_offsets_velo_tracks_C_side_t=tracks_ACsplit_counters.
        dev_offsets_velo_tracks_C_side_t,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=velo_tracks_preparation[
            "dev_three_hit_tracks_output"],
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        velo_tracks_preparation[
            "dev_offsets_number_of_three_hit_tracks_filtered"],
        splitting_algorithm=split_alg)

    velo_consolidate_tracks_A_side = make_algorithm(
        velo_consolidate_tracks_t,
        name="velo_consolidate_tracks_A_tracks",
        host_accumulated_number_of_hits_in_velo_tracks_t=tracks_ACsplit.
        host_accumulated_number_of_hits_in_velo_tracks_A_side_t,
        host_number_of_reconstructed_velo_tracks_t=tracks_ACsplit_counters.
        host_number_of_reconstructed_velo_tracks_A_side_t,
        host_number_of_three_hit_tracks_filtered_t=tracks_ACsplit_counters.
        host_number_of_three_hit_tracks_filtered_A_side_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=tracks_ACsplit_counters.
        dev_offsets_velo_tracks_A_side_t,
        dev_tracks_t=tracks_ACsplit.dev_tracks_A_side_t,
        dev_offsets_velo_track_hit_number_t=tracks_ACsplit.
        dev_offsets_velo_track_hit_number_A_side_t,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=tracks_ACsplit.
        dev_three_hit_tracks_output_A_side_t,
        dev_offsets_number_of_three_hit_tracks_filtered_t=tracks_ACsplit_counters
        .dev_offsets_number_of_three_hit_tracks_filtered_A_side_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
    )

    velo_consolidate_tracks_C_side = make_algorithm(
        velo_consolidate_tracks_t,
        name="velo_consolidate_tracks_C_tracks",
        host_accumulated_number_of_hits_in_velo_tracks_t=tracks_ACsplit.
        host_accumulated_number_of_hits_in_velo_tracks_C_side_t,
        host_number_of_reconstructed_velo_tracks_t=tracks_ACsplit_counters.
        host_number_of_reconstructed_velo_tracks_C_side_t,
        host_number_of_three_hit_tracks_filtered_t=tracks_ACsplit_counters.
        host_number_of_three_hit_tracks_filtered_C_side_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=tracks_ACsplit_counters.
        dev_offsets_velo_tracks_C_side_t,
        dev_tracks_t=tracks_ACsplit.dev_tracks_C_side_t,
        dev_offsets_velo_track_hit_number_t=tracks_ACsplit.
        dev_offsets_velo_track_hit_number_C_side_t,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=tracks_ACsplit.
        dev_three_hit_tracks_output_C_side_t,
        dev_offsets_number_of_three_hit_tracks_filtered_t=tracks_ACsplit_counters
        .dev_offsets_number_of_three_hit_tracks_filtered_C_side_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
    )

    return (
        {
            "host_number_of_reconstructed_velo_tracks":
            tracks_ACsplit_counters.
            host_number_of_reconstructed_velo_tracks_A_side_t,
            "dev_velo_track_hits":
            velo_consolidate_tracks_A_side.dev_velo_track_hits_t,
            "dev_offsets_all_velo_tracks":
            tracks_ACsplit_counters.dev_offsets_velo_tracks_A_side_t,
            "dev_offsets_velo_track_hit_number":
            tracks_ACsplit.dev_offsets_velo_track_hit_number_A_side_t,
            "dev_accepted_velo_tracks":
            velo_consolidate_tracks_A_side.dev_accepted_velo_tracks_t,
            "dev_velo_tracks_view":
            velo_consolidate_tracks_A_side.dev_velo_tracks_view_t,
            "dev_velo_multi_event_tracks_view":
            velo_consolidate_tracks_A_side.dev_velo_multi_event_tracks_view_t,
            "dev_imec_velo_tracks":
            velo_consolidate_tracks_A_side.dev_imec_velo_tracks_t,

            # Needed for long track particles dependencies.
            "dev_velo_track_view":
            velo_consolidate_tracks_A_side.dev_velo_track_view_t,
            "dev_velo_hits_view":
            velo_consolidate_tracks_A_side.dev_velo_hits_view_t
        },
        {
            "host_number_of_reconstructed_velo_tracks":
            tracks_ACsplit_counters.
            host_number_of_reconstructed_velo_tracks_C_side_t,
            "dev_velo_track_hits":
            velo_consolidate_tracks_C_side.dev_velo_track_hits_t,
            "dev_offsets_all_velo_tracks":
            tracks_ACsplit_counters.dev_offsets_velo_tracks_C_side_t,
            "dev_offsets_velo_track_hit_number":
            tracks_ACsplit.dev_offsets_velo_track_hit_number_C_side_t,
            "dev_accepted_velo_tracks":
            velo_consolidate_tracks_C_side.dev_accepted_velo_tracks_t,
            "dev_velo_tracks_view":
            velo_consolidate_tracks_C_side.dev_velo_tracks_view_t,
            "dev_velo_multi_event_tracks_view":
            velo_consolidate_tracks_C_side.dev_velo_multi_event_tracks_view_t,
            "dev_imec_velo_tracks":
            velo_consolidate_tracks_C_side.dev_imec_velo_tracks_t,

            # Needed for long track particles dependencies.
            "dev_velo_track_view":
            velo_consolidate_tracks_C_side.dev_velo_track_view_t,
            "dev_velo_hits_view":
            velo_consolidate_tracks_C_side.dev_velo_hits_view_t
        })


def run_velo_kalman_filter(velo_tracks, name=""):
    number_of_events = initialize_number_of_events()

    velo_kalman_filter = make_algorithm(
        velo_kalman_filter_t,
        name="velo_kalman_filter" + name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
    )

    return {
        "dev_velo_kalman_beamline_states":
        velo_kalman_filter.dev_velo_kalman_beamline_states_t,
        "dev_velo_kalman_endvelo_states":
        velo_kalman_filter.dev_velo_kalman_endvelo_states_t,
        "dev_velo_kalman_beamline_states_view":
        velo_kalman_filter.dev_velo_kalman_beamline_states_view_t,
        "dev_velo_kalman_endvelo_states_view":
        velo_kalman_filter.dev_velo_kalman_endvelo_states_view_t,
        "dev_is_backward":
        velo_kalman_filter.dev_is_backward_t
    }


def filter_tracks_for_material_interactions(velo_tracks,
                                            velo_states,
                                            beam_r_distance=3.5,
                                            close_doca=0.5):

    number_of_events = initialize_number_of_events()

    count_materialinteraction_vertices = make_algorithm(
        count_materialinteraction_candidates_t,
        name="count_materialinteraction_candidates_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        beamdoca_r=beam_r_distance,
        max_doca_for_close_track_pairs=close_doca)

    fill_materialinteraction_vertices = make_algorithm(
        fill_materialinteraction_candidates_t,
        name="count_materialinteraction_vertices_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_total_interaction_seeds_t=
        count_materialinteraction_vertices.
        host_number_of_total_interaction_seeds_t,
        dev_interaction_seeds_offsets_t=count_materialinteraction_vertices.
        dev_interaction_seeds_offsets_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_filtered_velo_track_idx_t=count_materialinteraction_vertices.
        dev_filtered_velo_track_idx_t,
        dev_number_of_filtered_tracks_t=count_materialinteraction_vertices.
        dev_number_of_filtered_tracks_t,
        max_doca_for_close_track_pairs=close_doca)

    return {
        "dev_number_of_filtered_velo_tracks":
        count_materialinteraction_vertices.dev_number_of_filtered_tracks_t,
        "dev_interaction_seeds_offsets":
        count_materialinteraction_vertices.dev_interaction_seeds_offsets_t,
        "dev_interaction_seeds":
        fill_materialinteraction_vertices.dev_interaction_seeds_t,
        "host_total_number_of_seeds":
        count_materialinteraction_vertices.
        host_number_of_total_interaction_seeds_t,
    }


def velo_tracking():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    alg = velo_tracks["dev_velo_track_hits"].producer
    return alg
