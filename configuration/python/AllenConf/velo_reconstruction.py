###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import (
    data_provider_t, velo_calculate_number_of_candidates_t, host_prefix_sum_t,
    velo_estimate_input_size_t, velo_masked_clustering_t, velo_sort_by_phi_t,
    velo_search_by_triplet_t, velo_three_hit_tracks_filter_t,
    velo_copy_track_hit_number_t, velo_consolidate_tracks_t,
    velo_kalman_filter_t,
    calculate_number_of_retinaclusters_each_sensor_pair_t,
    decode_retinaclusters_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


@configurable
def decode_velo(retina_decoding=True):
    number_of_events = initialize_number_of_events()

    if retina_decoding:
        velo_banks = make_algorithm(
            data_provider_t, name="velo_banks", bank_type="VPRetinaCluster")
            
        calculate_number_of_retinaclusters_each_sensor_pair = make_algorithm(
            calculate_number_of_retinaclusters_each_sensor_pair_t,
            name="calculate_number_of_retinaclusters_each_sensor_pair",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
            dev_velo_retina_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_retina_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_retina_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_retina_raw_input_types_t=velo_banks.dev_raw_types_t)

        prefix_sum_offsets_estimated_input_size = make_algorithm(
            host_prefix_sum_t,
            name="prefix_sum_offsets_estimated_input_size",
            dev_input_buffer_t=
            calculate_number_of_retinaclusters_each_sensor_pair.
            dev_each_sensor_pair_size_t)

        decode_retinaclusters = make_algorithm(
            decode_retinaclusters_t,
            name="decode_retinaclusters",
            host_total_number_of_velo_clusters_t=
            prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_velo_retina_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_retina_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_retina_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_retina_raw_input_types_t=velo_banks.dev_raw_types_t,
            dev_retina_bank_index_t=
            calculate_number_of_retinaclusters_each_sensor_pair.
            dev_retina_bank_index_t,
            dev_offsets_each_sensor_pair_size_t=
            prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
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
            prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
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
            dev_velo_raw_input_types_t=velo_banks.dev_raw_types_t)

        prefix_sum_offsets_velo_candidates = make_algorithm(
            host_prefix_sum_t,
            name="prefix_sum_offsets_velo_candidates",
            dev_input_buffer_t=velo_calculate_number_of_candidates.
            dev_number_of_candidates_t,
        )

        velo_estimate_input_size = make_algorithm(
            velo_estimate_input_size_t,
            name="velo_estimate_input_size",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_number_of_cluster_candidates_t=
            prefix_sum_offsets_velo_candidates.host_total_sum_holder_t,
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
            dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
            dev_output_buffer_t,
            dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_raw_input_types_t=velo_banks.dev_raw_types_t)

        prefix_sum_offsets_estimated_input_size = make_algorithm(
            host_prefix_sum_t,
            name="prefix_sum_offsets_estimated_input_size",
            dev_input_buffer_t=velo_estimate_input_size.
            dev_estimated_input_size_t,
        )

        velo_masked_clustering = make_algorithm(
            velo_masked_clustering_t,
            name="velo_masked_clustering",
            host_total_number_of_velo_clusters_t=
            prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_raw_bank_version_t=velo_banks.host_raw_bank_version_t,
            dev_velo_raw_input_t=velo_banks.dev_raw_banks_t,
            dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t,
            dev_velo_raw_input_sizes_t=velo_banks.dev_raw_sizes_t,
            dev_velo_raw_input_types_t=velo_banks.dev_raw_types_t,
            dev_offsets_estimated_input_size_t=
            prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
            dev_module_candidate_num_t=velo_estimate_input_size.
            dev_module_candidate_num_t,
            dev_cluster_candidates_t=velo_estimate_input_size.
            dev_cluster_candidates_t,
            dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
            dev_output_buffer_t,
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            dev_velo_bank_index_t=velo_calculate_number_of_candidates.
            dev_velo_bank_index_t)

        velo_sort_by_phi = make_algorithm(
            velo_sort_by_phi_t,
            name="velo_sort_by_phi",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_total_number_of_velo_clusters_t=
            prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
            dev_offsets_estimated_input_size_t=
            prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
            dev_module_cluster_num_t=velo_masked_clustering.
            dev_module_cluster_num_t,
            dev_velo_cluster_container_t=velo_masked_clustering.
            dev_velo_cluster_container_t,
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            dev_velo_clusters_t=velo_masked_clustering.dev_velo_clusters_t,
        )

        return {
            "dev_sorted_velo_cluster_container":
            velo_sort_by_phi.dev_sorted_velo_cluster_container_t,
            "dev_module_cluster_num":
            velo_masked_clustering.dev_module_cluster_num_t,
            "dev_offsets_estimated_input_size":
            prefix_sum_offsets_estimated_input_size.dev_output_buffer_t,
            "host_total_number_of_velo_clusters":
            prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t,
            "dev_velo_clusters":
            velo_masked_clustering.dev_velo_clusters_t
        }


def make_velo_tracks(decoded_velo):
    number_of_events = initialize_number_of_events()
    dev_sorted_velo_cluster_container = decoded_velo[
        "dev_sorted_velo_cluster_container"]
    dev_module_cluster_num = decoded_velo["dev_module_cluster_num"]
    dev_offsets_estimated_input_size = decoded_velo[
        "dev_offsets_estimated_input_size"]
    host_total_number_of_velo_clusters = decoded_velo[
        "host_total_number_of_velo_clusters"]
    dev_velo_clusters = decoded_velo["dev_velo_clusters"]

    velo_search_by_triplet = make_algorithm(
        velo_search_by_triplet_t,
        name="velo_search_by_triplet",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_total_number_of_velo_clusters_t=host_total_number_of_velo_clusters,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_module_cluster_num_t=dev_module_cluster_num,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_clusters_t=dev_velo_clusters,
        max_skipped_modules=1,
    )

    prefix_sum_offsets_velo_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_velo_tracks",
        dev_input_buffer_t=velo_search_by_triplet.dev_number_of_velo_tracks_t,
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

    prefix_sum_offsets_number_of_three_hit_tracks_filtered = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_number_of_three_hit_tracks_filtered",
        dev_input_buffer_t=velo_three_hit_tracks_filter.
        dev_number_of_three_hit_tracks_output_t,
    )

    velo_copy_track_hit_number = make_algorithm(
        velo_copy_track_hit_number_t,
        name="velo_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_velo_tracks_at_least_four_hits_t=
        prefix_sum_offsets_velo_tracks.host_total_sum_holder_t,
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t,
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t,
        dev_offsets_velo_tracks_t=prefix_sum_offsets_velo_tracks.
        dev_output_buffer_t,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t,
    )

    prefix_sum_offsets_velo_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_offsets_velo_track_hit_number",
        dev_input_buffer_t=velo_copy_track_hit_number.
        dev_velo_track_hit_number_t,
    )

    velo_consolidate_tracks = make_algorithm(
        velo_consolidate_tracks_t,
        name="velo_consolidate_tracks",
        host_accumulated_number_of_hits_in_velo_tracks_t=
        prefix_sum_offsets_velo_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t,
        host_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        host_total_sum_holder_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t,
        dev_tracks_t=velo_search_by_triplet.dev_tracks_t,
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        dev_sorted_velo_cluster_container_t=dev_sorted_velo_cluster_container,
        dev_offsets_estimated_input_size_t=dev_offsets_estimated_input_size,
        dev_three_hit_tracks_output_t=velo_three_hit_tracks_filter.
        dev_three_hit_tracks_output_t,
        dev_offsets_number_of_three_hit_tracks_filtered_t=
        prefix_sum_offsets_number_of_three_hit_tracks_filtered.
        dev_output_buffer_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
    )

    return {
        "host_number_of_reconstructed_velo_tracks":
        velo_copy_track_hit_number.host_number_of_reconstructed_velo_tracks_t,
        "dev_velo_track_hits":
        velo_consolidate_tracks.dev_velo_track_hits_t,
        "dev_offsets_all_velo_tracks":
        velo_copy_track_hit_number.dev_offsets_all_velo_tracks_t,
        "dev_offsets_velo_track_hit_number":
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t,
        "dev_accepted_velo_tracks":
        velo_consolidate_tracks.dev_accepted_velo_tracks_t,
        "dev_velo_tracks_view":
        velo_consolidate_tracks.dev_velo_tracks_view_t,
        "dev_imec_velo_tracks":
        velo_consolidate_tracks.dev_imec_velo_tracks_t,

        # Needed for long track particles dependencies.
        "dev_velo_track_view":
        velo_consolidate_tracks.dev_velo_track_view_t,
        "dev_velo_hits_view":
        velo_consolidate_tracks.dev_velo_hits_view_t
    }


def run_velo_kalman_filter(velo_tracks):
    number_of_events = initialize_number_of_events()

    velo_kalman_filter = make_algorithm(
        velo_kalman_filter_t,
        name="velo_kalman_filter",
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
    }


def velo_tracking():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    alg = velo_tracks["dev_velo_track_hits"].producer
    return alg
