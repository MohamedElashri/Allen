###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from PyConf.components import Algorithm
from algorithms import *
from PVSequence import run_velo_kalman_filter, make_pvs
from VeloSequence import initialize_lists, make_velo_tracks
from UTSequence import make_ut_tracks
from ForwardSequence import make_forward_tracks
from MuonSequence import is_muon


def run_selections(**kwargs):
    initialized_lists = initialize_lists(**kwargs)
    velo_tracks = make_velo_tracks(**kwargs)
    pvs = make_pvs(**kwargs)
    ut_tracks = make_ut_tracks(**kwargs)
    forward_tracks = make_forward_tracks(**kwargs)
    velo_kalman_filter = run_velo_kalman_filter(**kwargs)
    is_muon_result = is_muon(**kwargs)

    velo_pv_ip = Algorithm(
        velo_pv_ip_t,
        name="velo_pv_ip",
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        dev_velo_kalman_beamline_states_t=velo_kalman_filter[
            "dev_velo_kalman_beamline_states"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_multi_fit_vertices_t=pvs["dev_multi_fit_vertices"],
        dev_number_of_multi_fit_vertices_t=pvs[
            "dev_number_of_multi_fit_vertices"])

    kalman_velo_only = Algorithm(
        kalman_velo_only_t,
        name="kalman_velo_only",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        dev_offsets_ut_tracks_t=ut_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=ut_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_qop_t=ut_tracks["dev_ut_qop"],
        dev_ut_track_velo_indices_t=ut_tracks["dev_ut_track_velo_indices"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_velo_pv_ip_t=velo_pv_ip.dev_velo_pv_ip_t,
        dev_multi_fit_vertices_t=pvs["dev_multi_fit_vertices"],
        dev_number_of_multi_fit_vertices_t=pvs[
            "dev_number_of_multi_fit_vertices"],
        dev_is_muon_t=is_muon_result["dev_is_muon"])

    filter_tracks = Algorithm(
        filter_tracks_t,
        name="filter_tracks",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_multi_fit_vertices_t=pvs["dev_multi_fit_vertices"],
        dev_number_of_multi_fit_vertices_t=pvs[
            "dev_number_of_multi_fit_vertices"],
        dev_kalman_pv_ipchi2_t=kalman_velo_only.dev_kalman_pv_ipchi2_t)

    prefix_sum_secondary_vertices = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_secondary_vertices",
        dev_input_buffer_t=filter_tracks.dev_sv_atomics_t)

    fit_secondary_vertices = Algorithm(
        fit_secondary_vertices_t,
        name="fit_secondary_vertices",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t,
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_multi_fit_vertices_t=pvs["dev_multi_fit_vertices"],
        dev_number_of_multi_fit_vertices_t=pvs[
            "dev_number_of_multi_fit_vertices"],
        dev_kalman_pv_ipchi2_t=kalman_velo_only.dev_kalman_pv_ipchi2_t,
        dev_svs_trk1_idx_t=filter_tracks.dev_svs_trk1_idx_t,
        dev_svs_trk2_idx_t=filter_tracks.dev_svs_trk2_idx_t,
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t)

    odin_banks = Algorithm(
        data_provider_t, name="populate_odin_banks", bank_type="ODIN")

    run_hlt1 = Algorithm(
        run_hlt1_t,
        name="run_hlt1",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t,
        dev_event_list_t=initialized_lists["dev_event_list"],
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t,
        dev_consolidated_svs_t=fit_secondary_vertices.dev_consolidated_svs_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t,
        dev_odin_raw_input_t=odin_banks.dev_raw_banks_t,
        dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t,
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"])

    prepare_raw_banks = Algorithm(
        prepare_raw_banks_t,
        name="prepare_raw_banks",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t,
        dev_event_list_t=initialized_lists["dev_event_list"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        dev_offsets_ut_tracks_t=ut_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=ut_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_qop_t=ut_tracks["dev_ut_qop"],
        dev_ut_track_velo_indices_t=ut_tracks["dev_ut_track_velo_indices"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_ut_track_hits_t=ut_tracks["dev_ut_track_hits"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"],
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t,
        dev_consolidated_svs_t=fit_secondary_vertices.dev_consolidated_svs_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t,
        dev_sel_results_t=run_hlt1.dev_sel_results_t,
        dev_sel_results_offsets_t=run_hlt1.dev_sel_results_offsets_t)

    prefix_sum_sel_reps = Algorithm(
        host_prefix_sum_t,
        name="prefix_sum_sel_reps",
        dev_input_buffer_t=prepare_raw_banks.dev_sel_rep_sizes_t)

    package_sel_reports = Algorithm(
        package_sel_reports_t,
        name="package_sel_reports",
        host_number_of_events_t=initialized_lists[
            "host_number_of_events"],
        host_number_of_sel_rep_words_t=prefix_sum_sel_reps.
        host_total_sum_holder_t,
        dev_event_list_t=initialized_lists["dev_event_list"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_sel_rb_hits_t=prepare_raw_banks.dev_sel_rb_hits_t,
        dev_sel_rb_stdinfo_t=prepare_raw_banks.dev_sel_rb_stdinfo_t,
        dev_sel_rb_objtyp_t=prepare_raw_banks.dev_sel_rb_objtyp_t,
        dev_sel_rb_substr_t=prepare_raw_banks.dev_sel_rb_substr_t,
        dev_sel_rep_offsets_t=prefix_sum_sel_reps.dev_output_buffer_t)

    return {
        "dev_sel_rep_raw_banks": package_sel_reports.dev_sel_rep_raw_banks_t
    }
