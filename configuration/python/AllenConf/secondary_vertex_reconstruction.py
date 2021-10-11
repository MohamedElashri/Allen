###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (velo_pv_ip_t, kalman_velo_only_t,
                                  filter_tracks_t, host_prefix_sum_t,
                                  fit_secondary_vertices_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenCore.generator import make_algorithm


def make_kalman_velo_only(forward_tracks, pvs, is_muon_result):
    number_of_events = initialize_number_of_events()
    ut_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = ut_tracks["velo_tracks"]
    velo_states = run_velo_kalman_filter(velo_tracks)

    velo_pv_ip = make_algorithm(
        velo_pv_ip_t,
        name="velo_pv_ip",
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_kalman_beamline_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
    )

    kalman_velo_only = make_algorithm(
        kalman_velo_only_t,
        name="kalman_velo_only",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_scifi_tracks_view_t=forward_tracks["dev_scifi_tracks_view"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        dev_is_muon_t=is_muon_result["dev_is_muon"],
    )

    return {
        "forward_tracks": forward_tracks,
        "pvs": pvs,
        "dev_kf_tracks": kalman_velo_only.dev_kf_tracks_t,
        "dev_kalman_pv_ipchi2": kalman_velo_only.dev_kalman_pv_ipchi2_t,
        "dev_long_track_particles": kalman_velo_only.dev_long_track_particles_t
    }


def fit_secondary_vertices(forward_tracks, pvs, kalman_velo_only):
    number_of_events = initialize_number_of_events()

    filter_tracks = make_algorithm(
        filter_tracks_t,
        name="filter_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_long_track_particles_t=kalman_velo_only["dev_long_track_particles"]
    )

    prefix_sum_secondary_vertices = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_secondary_vertices",
        dev_input_buffer_t=filter_tracks.dev_sv_atomics_t,
    )

    fit_secondary_vertices = make_algorithm(
        fit_secondary_vertices_t,
        name="fit_secondary_vertices",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t,
        dev_kf_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        dev_kalman_pv_ipchi2_t=kalman_velo_only["dev_kalman_pv_ipchi2"],
        dev_svs_trk1_idx_t=filter_tracks.dev_svs_trk1_idx_t,
        dev_svs_trk2_idx_t=filter_tracks.dev_svs_trk2_idx_t,
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t,
        dev_sv_poca_t=filter_tracks.dev_sv_poca_t)

    return {
        "dev_consolidated_svs":
        fit_secondary_vertices.dev_consolidated_svs_t,
        "dev_kf_tracks":
        kalman_velo_only["dev_kf_tracks"],
        "host_number_of_svs":
        prefix_sum_secondary_vertices.host_total_sum_holder_t,
        "dev_sv_offsets":
        prefix_sum_secondary_vertices.dev_output_buffer_t,
        "dev_svs_trk1_idx":
        filter_tracks.dev_svs_trk1_idx_t,
        "dev_svs_trk2_idx":
        filter_tracks.dev_svs_trk2_idx_t
    }
