###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import *
from AllenConf.utils import initialize_number_of_events
from AllenCore.event_list_utils import make_algorithm


def velo_validation(velo_tracks, name="velo_validator"):
    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_velo_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_data_provider.host_mc_events_t)


def veloUT_validation(veloUT_tracks, name="veloUT_validator"):
    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    number_of_events = initialize_number_of_events()

    velo_tracks = veloUT_tracks["velo_tracks"]
    velo_states = veloUT_tracks["velo_states"]

    return make_algorithm(
        host_velo_ut_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_data_provider.host_mc_events_t,
        dev_velo_kalman_endvelo_states_t=velo_states[
            "dev_velo_kalman_endvelo_states"],
        dev_offsets_ut_tracks_t=veloUT_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=veloUT_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_track_hits_t=veloUT_tracks["dev_ut_track_hits"],
        dev_ut_track_velo_indices_t=veloUT_tracks["dev_ut_track_velo_indices"],
        dev_ut_qop_t=veloUT_tracks["dev_ut_qop"])


def forward_validation(forward_tracks, name="forward_validator"):
    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    number_of_events = initialize_number_of_events()

    veloUT_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = veloUT_tracks["velo_tracks"]
    velo_states = veloUT_tracks["velo_states"]

    return make_algorithm(
        host_forward_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_data_provider.host_mc_events_t,
        dev_velo_kalman_endvelo_states_t=velo_states[
            "dev_velo_kalman_endvelo_states"],
        dev_offsets_ut_tracks_t=veloUT_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=veloUT_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_track_hits_t=veloUT_tracks["dev_ut_track_hits"],
        dev_ut_track_velo_indices_t=veloUT_tracks["dev_ut_track_velo_indices"],
        dev_ut_qop_t=veloUT_tracks["dev_ut_qop"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"])


def muon_validation(muonID, name="muon_validator"):
    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    number_of_events = initialize_number_of_events()

    forward_tracks = muonID["forward_tracks"]
    veloUT_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = veloUT_tracks["velo_tracks"]
    velo_states = veloUT_tracks["velo_states"]

    return make_algorithm(
        host_muon_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_data_provider.host_mc_events_t,
        dev_velo_kalman_endvelo_states_t=velo_states[
            "dev_velo_kalman_endvelo_states"],
        dev_offsets_ut_tracks_t=veloUT_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=veloUT_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_track_hits_t=veloUT_tracks["dev_ut_track_hits"],
        dev_ut_track_velo_indices_t=veloUT_tracks["dev_ut_track_velo_indices"],
        dev_ut_qop_t=veloUT_tracks["dev_ut_qop"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_is_muon_t=muonID["dev_is_muon"])


def pv_validation(pvs, name="pv_validator"):
    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    return make_algorithm(
        host_pv_validator_t,
        name=name,
        host_mc_events_t=mc_data_provider.host_mc_events_t,
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"])


def rate_validation(gather_selections, name="rate_validator"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_rate_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_names_of_lines_t=gather_selections.host_names_of_active_lines_t,
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t)


def kalman_validation(kalman_velo_only, name="kalman_validator"):
    number_of_events = initialize_number_of_events()

    mc_data_provider = make_algorithm(
        mc_data_provider_t, name="mc_data_provider")

    forward_tracks = kalman_velo_only["forward_tracks"]
    veloUT_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = veloUT_tracks["velo_tracks"]
    velo_states = veloUT_tracks["velo_states"]
    pvs = kalman_velo_only["pvs"]

    return make_algorithm(
        host_kalman_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_data_provider.host_mc_events_t,
        dev_velo_kalman_states_t=velo_states["dev_velo_kalman_endvelo_states"],
        dev_offsets_ut_tracks_t=veloUT_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=veloUT_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_track_hits_t=veloUT_tracks["dev_ut_track_hits"],
        dev_ut_track_velo_indices_t=veloUT_tracks["dev_ut_track_velo_indices"],
        dev_ut_qop_t=veloUT_tracks["dev_ut_qop"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_kf_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"])
