###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from AllenAlgorithms.algorithms import (
    data_provider_t, calo_count_digits_t, host_prefix_sum_t, calo_decode_t,
    track_digit_selective_matching_t, brem_recovery_t,
    momentum_brem_correction_t, calo_seed_clusters_t, calo_find_clusters_t,
    calo_filter_clusters_t, calo_find_twoclusters_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def decode_calo():
    number_of_events = initialize_number_of_events()
    ecal_banks = make_algorithm(
        data_provider_t, name="ecal_banks", bank_type="ECal")

    calo_count_digits = make_algorithm(
        calo_count_digits_t,
        name="calo_count_digits",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    prefix_sum_ecal_num_digits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_ecal_num_digits",
        dev_input_buffer_t=calo_count_digits.dev_ecal_num_digits_t)

    calo_decode = make_algorithm(
        calo_decode_t,
        name="calo_decode",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=prefix_sum_ecal_num_digits.
        host_total_sum_holder_t,
        host_raw_bank_version_t=ecal_banks.host_raw_bank_version_t,
        dev_ecal_raw_input_t=ecal_banks.dev_raw_banks_t,
        dev_ecal_raw_input_offsets_t=ecal_banks.dev_raw_offsets_t,
        dev_ecal_raw_input_sizes_t=ecal_banks.dev_raw_sizes_t,
        dev_ecal_raw_input_types_t=ecal_banks.dev_raw_types_t,
        dev_ecal_digits_offsets_t=prefix_sum_ecal_num_digits.
        dev_output_buffer_t)

    return {
        "host_ecal_number_of_digits":
        prefix_sum_ecal_num_digits.host_total_sum_holder_t,
        "dev_ecal_digits":
        calo_decode.dev_ecal_digits_t,
        "dev_ecal_digits_offsets":
        prefix_sum_ecal_num_digits.dev_output_buffer_t
    }


def make_track_matching(decoded_calo, velo_tracks, velo_states, long_tracks,
                        kalman_velo_only):
    number_of_events = initialize_number_of_events()

    track_digit_selective_matching = make_algorithm(
        track_digit_selective_matching_t,
        name="track_digit_selective_matching",
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_scifi_states_t=long_tracks["dev_scifi_states"],
        dev_scifi_tracks_view_t=long_tracks["dev_scifi_tracks_view"],
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    brem_recovery = make_algorithm(
        brem_recovery_t,
        name="brem_recovery",
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_kalman_beamline_states_t=velo_states[
            "dev_velo_kalman_beamline_states"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    momentum_brem_correction = make_algorithm(
        momentum_brem_correction_t,
        name="momentum_brem_correction",
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_kf_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_velo_tracks_offsets_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_brem_E_t=brem_recovery.dev_brem_E_t,
        dev_brem_ET_t=brem_recovery.dev_brem_ET_t)

    return {
        "dev_matched_ecal_energy":
        track_digit_selective_matching.dev_matched_ecal_energy_t,
        "dev_matched_ecal_digits_size":
        track_digit_selective_matching.dev_matched_ecal_digits_size_t,
        "dev_matched_ecal_digits":
        track_digit_selective_matching.dev_matched_ecal_digits_t,
        "dev_track_inEcalAcc":
        track_digit_selective_matching.dev_track_inEcalAcc_t,
        "dev_track_Eop":
        track_digit_selective_matching.dev_track_Eop_t,
        "dev_track_isElectron":
        track_digit_selective_matching.dev_track_isElectron_t,
        "dev_brem_E":
        brem_recovery.dev_brem_E_t,
        "dev_brem_ET":
        brem_recovery.dev_brem_ET_t,
        "dev_brem_inECALacc":
        brem_recovery.dev_brem_inECALacc_t,
        "dev_brem_ecal_digits_size":
        brem_recovery.dev_brem_ecal_digits_size_t,
        "dev_brem_ecal_digits":
        brem_recovery.dev_brem_ecal_digits_t,
        "dev_brem_corrected_p":
        momentum_brem_correction.dev_brem_corrected_p_t,
        "dev_brem_corrected_pt":
        momentum_brem_correction.dev_brem_corrected_pt_t
    }


def make_ecal_clusters(decoded_calo):
    number_of_events = initialize_number_of_events()

    calo_seed_clusters = make_algorithm(
        calo_seed_clusters_t,
        name="calo_seed_clusters",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"])

    prefix_sum_ecal_num_clusters = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_ecal_num_clusters",
        dev_input_buffer_t=calo_seed_clusters.dev_ecal_num_clusters_t)

    calo_find_clusters = make_algorithm(
        calo_find_clusters_t,
        name="calo_find_clusters",
        host_ecal_number_of_clusters_t=prefix_sum_ecal_num_clusters.
        host_total_sum_holder_t,
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_ecal_seed_clusters_t=calo_seed_clusters.dev_ecal_seed_clusters_t,
        dev_ecal_cluster_offsets_t=prefix_sum_ecal_num_clusters.
        dev_output_buffer_t)

    filter_clusters = make_algorithm(
        calo_filter_clusters_t,
        name="filter_clusters",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_clusters_t=prefix_sum_ecal_num_clusters.
        host_total_sum_holder_t,
        dev_ecal_clusters_t=calo_find_clusters.dev_ecal_clusters_t,
        dev_ecal_cluster_offsets_t=prefix_sum_ecal_num_clusters.
        dev_output_buffer_t)

    prefix_sum_filtered_calo_clusters = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_filtered_calo_clusters",
        dev_input_buffer_t=filter_clusters.dev_cluster_atomics_t)

    calo_find_twoclusters = make_algorithm(
        calo_find_twoclusters_t,
        name="calo_find_twoclusters",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_twoclusters_t=prefix_sum_filtered_calo_clusters.
        host_total_sum_holder_t,
        dev_ecal_clusters_t=calo_find_clusters.dev_ecal_clusters_t,
        dev_ecal_cluster_offsets_t=prefix_sum_ecal_num_clusters.
        dev_output_buffer_t,
        dev_cluster1_idx_t=filter_clusters.dev_cluster1_idx_t,
        dev_cluster2_idx_t=filter_clusters.dev_cluster2_idx_t,
        dev_ecal_twocluster_offsets_t=prefix_sum_filtered_calo_clusters.
        dev_output_buffer_t)

    return {
        "host_ecal_number_of_clusters":
        prefix_sum_ecal_num_clusters.host_total_sum_holder_t,
        "host_ecal_number_of_twoclusters":
        prefix_sum_filtered_calo_clusters.host_total_sum_holder_t,
        "dev_ecal_cluster_offsets":
        prefix_sum_ecal_num_clusters.dev_output_buffer_t,
        "dev_ecal_twocluster_offsets":
        prefix_sum_filtered_calo_clusters.dev_output_buffer_t,
        "dev_ecal_num_clusters":
        calo_seed_clusters.dev_ecal_num_clusters_t,
        "dev_ecal_num_twoclusters":
        filter_clusters.dev_cluster_atomics_t,
        "dev_ecal_clusters":
        calo_find_clusters.dev_ecal_clusters_t,
        "dev_ecal_twoclusters":
        calo_find_twoclusters.dev_ecal_twoclusters_t
    }
