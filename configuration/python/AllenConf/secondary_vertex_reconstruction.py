###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (velo_pv_ip_t, kalman_velo_only_t,
                                  make_lepton_id_t,
                                  make_long_track_particles_t, filter_tracks_t,
                                  host_prefix_sum_t, fit_secondary_vertices_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenCore.generator import make_algorithm


def make_kalman_velo_only(forward_tracks,
                          pvs,
                          is_muon_result,
                          is_electron_result=None):
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
        "dev_kalman_pv_tables": kalman_velo_only.dev_kalman_pv_tables_t,
        "dev_kalman_fit_results": kalman_velo_only.dev_kalman_fit_results_t,
        "dev_kalman_states_view": kalman_velo_only.dev_kalman_states_view_t
    }


def make_basic_particles(kalman_velo_only,
                         is_muon_result,
                         is_electron_result=None):
    number_of_events = initialize_number_of_events()
    forward_tracks = kalman_velo_only["forward_tracks"]
    pvs = kalman_velo_only["pvs"]

    if is_electron_result is not None:
        make_lepton_id = make_algorithm(
            make_lepton_id_t,
            name="make_lepton_id",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            host_number_of_scifi_tracks_t=forward_tracks[
                "host_number_of_reconstructed_scifi_tracks"],
            dev_scifi_tracks_view_t=forward_tracks["dev_scifi_tracks_view"],
            dev_is_muon_t=is_muon_result["dev_is_muon"],
            dev_is_electron_t=is_electron_result["dev_track_isElectron"])
        lepton_id = make_lepton_id.dev_lepton_id_t
    else:
        lepton_id = is_muon_result["dev_is_muon"]

    make_long_track_particles = make_algorithm(
        make_long_track_particles_t,
        name="make_long_track_particles",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_scifi_tracks_view_t=forward_tracks["dev_scifi_tracks_view"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_kalman_states_view_t=kalman_velo_only["dev_kalman_states_view"],
        dev_kalman_pv_tables_t=kalman_velo_only["dev_kalman_pv_tables"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_lepton_id_t=lepton_id)
    return {
        "dev_long_track_particles":
        make_long_track_particles.dev_long_track_particles_view_t,
        "dev_long_track_particle":
        make_long_track_particles.dev_long_track_particle_view_t,
        "dev_multi_event_basic_particles":
        make_long_track_particles.dev_multi_event_basic_particles_view_t
    }


def fit_secondary_vertices(forward_tracks, pvs, kalman_velo_only,
                           long_track_particles):
    number_of_events = initialize_number_of_events()
    ut_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = ut_tracks["velo_tracks"]

    filter_tracks = make_algorithm(
        filter_tracks_t,
        name="filter_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_long_track_particles_t=long_track_particles[
            "dev_long_track_particles"])

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
        dev_long_track_particles_t=long_track_particles[
            "dev_long_track_particles"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
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
        filter_tracks.dev_svs_trk2_idx_t,
        # "dev_long_track_particles":
        # long_track_particles["dev_long_track_particles"],
        "dev_two_track_particles":
        fit_secondary_vertices.dev_two_track_composites_view_t,
        "dev_multi_event_composites":
        fit_secondary_vertices.dev_multi_event_composites_view_t
    }
