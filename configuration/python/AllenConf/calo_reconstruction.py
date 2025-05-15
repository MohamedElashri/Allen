###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (
    data_provider_t, calo_count_digits_t, calo_decode_t,
    track_digit_selective_matching_t, brem_recovery_t,
    momentum_brem_correction_t, calo_seed_clusters_t, calo_find_clusters_t,
    calo_prefilter_clusters_t, calo_filter_clusters_t, calo_find_twoclusters_t,
    total_ecal_energy_t, make_neutral_particles_t, calo_overlap_clusters_t,
    electronid_nn_t, fake_digit_matching_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


def decode_calo(empty_banks=False):
    number_of_events = initialize_number_of_events()
    ecal_banks = make_algorithm(
        data_provider_t,
        name='ecal_banks_{hash}',
        bank_type="ECal",
        empty=empty_banks)

    calo_count_digits = make_algorithm(
        calo_count_digits_t,
        name='calo_count_digits_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    calo_decode = make_algorithm(
        calo_decode_t,
        name='calo_decode_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=calo_count_digits.host_total_sum_holder_t,
        host_raw_bank_version_t=ecal_banks.host_raw_bank_version_t,
        dev_ecal_raw_input_t=ecal_banks.dev_raw_banks_t,
        dev_ecal_raw_input_offsets_t=ecal_banks.dev_raw_offsets_t,
        dev_ecal_raw_input_sizes_t=ecal_banks.dev_raw_sizes_t,
        dev_ecal_raw_input_types_t=ecal_banks.dev_raw_types_t,
        dev_ecal_digits_offsets_t=calo_count_digits.dev_digits_offsets_t)

    sum_ecal_energy = make_algorithm(
        total_ecal_energy_t,
        name='total_ecal_energy_{hash}',
        host_ecal_number_of_digits_t=calo_count_digits.host_total_sum_holder_t,
        dev_ecal_digits_offsets_t=calo_count_digits.dev_digits_offsets_t,
        dev_ecal_digits_t=calo_decode.dev_ecal_digits_t)

    return {
        "host_ecal_number_of_digits":
        calo_count_digits.host_total_sum_holder_t,
        "dev_ecal_digits": calo_decode.dev_ecal_digits_t,
        "dev_ecal_digits_offsets": calo_count_digits.dev_digits_offsets_t,
        "dev_total_ecal_e": sum_ecal_energy.dev_total_ecal_e_t
    }


def make_is_electron(decoded_calo, host_number_of_tracks,
                     dev_multi_event_tracks_ptr, dev_velo_states,
                     dev_scifi_states):
    number_of_events = initialize_number_of_events()

    track_digit_selective_matching = make_algorithm(
        track_digit_selective_matching_t,
        name='track_digit_selective_matching_{hash}',
        host_number_of_reconstructed_scifi_tracks_t=host_number_of_tracks,
        dev_scifi_states_t=dev_scifi_states,
        # dev_long_tracks_view_t=dev_multi_event_tracks_ptr,
        dev_tracks_view_t=dev_multi_event_tracks_ptr,
        host_ecal_number_of_digits_t=decoded_calo[
            "host_ecal_number_of_digits"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    return {
        "dev_delta_barycenter":
        track_digit_selective_matching.dev_delta_barycenter_t,
        "dev_dispersion_x":
        track_digit_selective_matching.dev_dispersion_x_t,
        "dev_dispersion_y":
        track_digit_selective_matching.dev_dispersion_y_t,
        "dev_dispersion_xy":
        track_digit_selective_matching.dev_dispersion_xy_t,
        "dev_track_local_max":
        track_digit_selective_matching.dev_track_local_max_t,
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
        "dev_track_Eop3x3":
        track_digit_selective_matching.dev_track_Eop3x3_t,
        "dev_track_isElectron":
        track_digit_selective_matching.dev_track_isElectron_t,
    }


def make_track_matching(decoded_calo, velo_tracks, velo_states, long_tracks,
                        kalman_velo_only):
    number_of_events = initialize_number_of_events()

    track_digit_selective_matching = make_algorithm(
        track_digit_selective_matching_t,
        name='track_digit_selective_matching_{hash}',
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_scifi_states_t=long_tracks["dev_scifi_states"],
        # dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_tracks_view_t=long_tracks["dev_multi_event_long_tracks_ptr"],
        host_ecal_number_of_digits_t=decoded_calo[
            "host_ecal_number_of_digits"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    brem_recovery = make_algorithm(
        brem_recovery_t,
        name='brem_recovery_{hash}',
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_kalman_beamline_states_t=velo_states[
            "dev_velo_kalman_beamline_states"],
        host_ecal_number_of_digits_t=decoded_calo[
            "host_ecal_number_of_digits"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    momentum_brem_correction = make_algorithm(
        momentum_brem_correction_t,
        name='momentum_brem_correction_{hash}',
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_kf_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_velo_tracks_offsets_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_brem_E_t=brem_recovery.dev_brem_E_t,
        dev_brem_ET_t=brem_recovery.dev_brem_ET_t,
        dev_track_Eop_t=track_digit_selective_matching.dev_track_Eop_t)

    return {
        "dev_region":
        track_digit_selective_matching.dev_region_t,
        "dev_delta_barycenter":
        track_digit_selective_matching.dev_delta_barycenter_t,
        "dev_dispersion_x":
        track_digit_selective_matching.dev_dispersion_x_t,
        "dev_dispersion_y":
        track_digit_selective_matching.dev_dispersion_y_t,
        "dev_dispersion_xy":
        track_digit_selective_matching.dev_dispersion_xy_t,
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
        "dev_track_Eop3x3":
        track_digit_selective_matching.dev_track_Eop3x3_t,
        "dev_track_isElectron":
        track_digit_selective_matching.dev_track_isElectron_t,
        "dev_ecal_digits_isTrackMatched":
        track_digit_selective_matching.dev_ecal_digits_isTrackMatched_t,
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
        "dev_ecal_digits_isBremMatched":
        brem_recovery.dev_ecal_digits_isBremMatched_t,
        "dev_brem_corrected_p":
        momentum_brem_correction.dev_brem_corrected_p_t,
        "dev_brem_corrected_pt":
        momentum_brem_correction.dev_brem_corrected_pt_t
    }


# Produce arrays with fake matching decisions, all set to false,
# to run calo_find_clusters without vetoing any seed clusters.
def fake_digit_matching(decoded_calo):
    fake_digit_match = make_algorithm(
        fake_digit_matching_t,
        name='empty_digit_track_matching_{hash}',
        host_ecal_number_of_digits_t=decoded_calo["host_ecal_number_of_digits"]
    )

    return {
        "dev_ecal_digits_isTrackMatched":
        fake_digit_match.dev_ecal_digits_isMatched_t,
        "dev_ecal_digits_isBremMatched":
        fake_digit_match.dev_ecal_digits_isMatched_t
    }


@configurable
def make_ecal_clusters(decoded_calo,
                       calo_matching_objects=None,
                       calo_find_clusters_name='calo_find_clusters',
                       seed_min_adc=50,
                       neighbour_min_adc=10,
                       min_et=400,
                       min_e19=0.6):
    number_of_events = initialize_number_of_events()

    calo_seed_clusters = make_algorithm(
        calo_seed_clusters_t,
        name='calo_seed_clusters_{hash}',
        ecal_min_adc=seed_min_adc,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=decoded_calo[
            "host_ecal_number_of_digits"],
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"])

    calo_overlap_clusters = make_algorithm(
        calo_overlap_clusters_t,
        name="calo_overlap_clusters_{hash}",
        host_ecal_number_of_clusters_t=calo_seed_clusters.
        host_total_sum_holder_t,
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_ecal_seed_clusters_t=calo_seed_clusters.dev_ecal_seed_clusters_t,
        dev_ecal_cluster_offsets_t=calo_seed_clusters.
        dev_ecal_cluster_offsets_t,
        dev_ecal_digit_is_seed_t=calo_seed_clusters.dev_ecal_digit_is_seed_t)

    # If calo_matching_objects is None, produce arrays with fake matching decisions,
    # all set to false, to run calo_find_clusters without vetoing any seed clusters.
    # Otherwise, calo_matching_objects contains the output from make_track_matching(),
    # and seed clusters matched with charged tracks or brem photons are vetoed.
    if calo_matching_objects is None:
        calo_matching_objects = fake_digit_matching(decoded_calo)

    calo_find_clusters = make_algorithm(
        calo_find_clusters_t,
        name=calo_find_clusters_name,
        ecal_min_adc=neighbour_min_adc,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_clusters_t=calo_seed_clusters.
        host_total_sum_holder_t,
        dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
        dev_ecal_seed_clusters_t=calo_seed_clusters.dev_ecal_seed_clusters_t,
        dev_ecal_cluster_offsets_t=calo_seed_clusters.
        dev_ecal_cluster_offsets_t,
        dev_ecal_corrections_t=calo_overlap_clusters.dev_ecal_corrections_t,
        dev_ecal_digits_isTrackMatched_t=calo_matching_objects[
            "dev_ecal_digits_isTrackMatched"],
        dev_ecal_digits_isBremMatched_t=calo_matching_objects[
            "dev_ecal_digits_isBremMatched"])

    make_neutral_particles = make_algorithm(
        make_neutral_particles_t,
        name="make_neutral_particles_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_neutral_clusters_t=calo_find_clusters.
        host_total_sum_holder_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ecal_cluster_offsets_t=calo_seed_clusters.
        dev_ecal_cluster_offsets_t,
        dev_ecal_neutral_cluster_offsets_t=calo_find_clusters.
        dev_ecal_neutral_cluster_offsets_t,
        dev_ecal_clusters_t=calo_find_clusters.dev_ecal_clusters_t)

    calo_prefilter_clusters = make_algorithm(
        calo_prefilter_clusters_t,
        name='calo_prefilter_clusters_{hash}',
        minEt_clusters=min_et,
        minE19_clusters=min_e19,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_ecal_number_of_neutral_clusters_t=calo_find_clusters.
        host_total_sum_holder_t,
        dev_neutral_particles_t=make_neutral_particles.
        dev_multi_event_neutral_particles_view_t)

    calo_filter_clusters = make_algorithm(
        calo_filter_clusters_t,
        name='calo_filter_clusters_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_twoclusters_t=calo_prefilter_clusters.
        host_total_sum_holder_t,
        dev_neutral_particles_t=make_neutral_particles.
        dev_multi_event_neutral_particles_view_t,
        dev_num_prefiltered_clusters_t=calo_prefilter_clusters.
        dev_num_prefiltered_clusters_t,
        dev_ecal_twocluster_offsets_t=calo_prefilter_clusters.
        dev_ecal_twocluster_offsets_t,
        dev_prefiltered_clusters_idx_t=calo_prefilter_clusters.
        dev_prefiltered_clusters_idx_t,
        dev_ecal_cluster_offsets_t=calo_seed_clusters.
        dev_ecal_cluster_offsets_t)

    calo_find_twoclusters = make_algorithm(
        calo_find_twoclusters_t,
        name='calo_find_twoclusters_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_twoclusters_t=calo_prefilter_clusters.
        host_total_sum_holder_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_neutral_particles_t=make_neutral_particles.
        dev_multi_event_neutral_particles_view_t,
        dev_cluster1_idx_t=calo_filter_clusters.dev_cluster1_idx_t,
        dev_cluster2_idx_t=calo_filter_clusters.dev_cluster2_idx_t,
        dev_ecal_twocluster_offsets_t=calo_prefilter_clusters.
        dev_ecal_twocluster_offsets_t)

    return {
        "host_ecal_number_of_clusters":
        calo_seed_clusters.host_total_sum_holder_t,
        "host_ecal_number_of_neutral_particles":
        calo_find_clusters.host_total_sum_holder_t,
        "host_ecal_number_of_twoclusters":
        calo_prefilter_clusters.host_total_sum_holder_t,
        "dev_ecal_cluster_offsets":
        calo_seed_clusters.dev_ecal_cluster_offsets_t,
        "dev_ecal_neutral_particle_offsets":
        calo_find_clusters.dev_ecal_neutral_cluster_offsets_t,
        "dev_ecal_clusters":
        calo_find_clusters.dev_ecal_clusters_t,
        "dev_multi_event_neutral_particles":
        make_neutral_particles.dev_multi_event_neutral_particles_view_t,
        "dev_multi_event_diphotons":
        calo_find_twoclusters.dev_multi_event_twoclusters_view_t
    }


def ecal_cluster_reco(calo_find_clusters_name='calo_find_clusters_reco'):
    decoded_calo = decode_calo()
    ecal_clusters = make_ecal_clusters(
        decoded_calo, calo_find_clusters_name=calo_find_clusters_name)
    alg = ecal_clusters["dev_ecal_clusters"].producer
    return alg


def make_electronid_nn(long_tracks, track_matching):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_scifi_tracks = long_tracks[
        "host_number_of_reconstructed_scifi_tracks"]

    electronid_nn = make_algorithm(
        electronid_nn_t,
        name='electronid_nn_{hash}',
        dev_track_inEcalAcc_t=track_matching['dev_track_inEcalAcc'],
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_track_Eop_t=track_matching["dev_track_Eop"],
        dev_track_Eop3x3_t=track_matching["dev_track_Eop3x3"],
        dev_delta_barycenter_t=track_matching["dev_delta_barycenter"],
        dev_region_t=track_matching["dev_region"],
        dev_dispersion_x_t=track_matching["dev_dispersion_x"],
        dev_dispersion_y_t=track_matching["dev_dispersion_y"],
        dev_dispersion_xy_t=track_matching["dev_dispersion_xy"],
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
    )
    return {
        "dev_electronidnn": electronid_nn.dev_electronid_evaluation_t,
        "dev_track_isElectron": electronid_nn.dev_is_electron_nn_t
    }
