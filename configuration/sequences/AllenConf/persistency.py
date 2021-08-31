###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import gather_selections_t, dec_reporter_t, global_decision_t
from AllenConf.algorithms import count_long_track_hits_t, host_prefix_sum_t, make_hits_container_t
from AllenConf.algorithms import calc_rb_hits_size_t, calc_rb_substr_size_t, make_rb_substr_t
from AllenConf.algorithms import make_rb_hits_t, make_rb_stdinfo_t, make_rb_objtyp_t
from AllenConf.algorithms import calc_selrep_size_t, make_selrep_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.event_list_utils import make_algorithm


def make_gather_selections(lines):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        gather_selections_t,
        name="gather_selections",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        dev_input_selections_t=[line.dev_decisions_t for line in lines],
        dev_input_selections_offsets_t=[
            line.dev_decisions_offsets_t for line in lines
        ],
        host_input_post_scale_factors_t=[
            line.host_post_scaler_t for line in lines
        ],
        host_input_post_scale_hashes_t=[
            line.host_post_scaler_hash_t for line in lines
        ],
        host_lhcbid_containers_agg_t=[
            line.host_lhcbid_container_t for line in lines
        ],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        names_of_active_lines=",".join([line.name for line in lines]))


def make_dec_reporter(lines):
    gather_selections = make_gather_selections(lines)
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        dec_reporter_t,
        name="dec_reporter",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t)


def make_global_decision(lines):
    gather_selections = make_gather_selections(lines)
    dec_reporter = make_dec_reporter(lines)
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        global_decision_t,
        name="global_decision",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t)


def make_sel_report_writer(lines, forward_tracks, secondary_vertices):
    gather_selections = make_gather_selections(lines)
    dec_reporter = make_dec_reporter(lines)
    number_of_events = initialize_number_of_events()

    ut_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = ut_tracks["velo_tracks"]

    count_long_track_hits = make_algorithm(
        count_long_track_hits_t,
        name="count_long_track_hits",
        host_number_of_events_t=number_of_events["host_number_of_events"],
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
        dev_ut_track_hits_t=ut_tracks["dev_ut_track_hits"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    prefix_sum_long_track_hits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_long_track_hits",
        dev_input_buffer_t=count_long_track_hits.dev_long_track_hit_number_t)

    make_hits_container = make_algorithm(
        make_hits_container_t,
        name="make_hits_container",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        host_hits_container_size_t=prefix_sum_long_track_hits.
        host_total_sum_holder_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_hits_offsets_t=prefix_sum_long_track_hits.dev_output_buffer_t,
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
        dev_ut_track_hits_t=ut_tracks["dev_ut_track_hits"],
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_offsets_scifi_track_hit_number_t=forward_tracks[
            "dev_offsets_scifi_track_hit_number"],
        dev_scifi_qop_t=forward_tracks["dev_scifi_qop"],
        dev_scifi_states_t=forward_tracks["dev_scifi_states"],
        dev_scifi_track_ut_indices_t=forward_tracks[
            "dev_scifi_track_ut_indices"],
        dev_scifi_track_hits_t=forward_tracks["dev_scifi_track_hits"])

    calc_rb_hits_size = make_algorithm(
        calc_rb_hits_size_t,
        name="calc_rb_hits_size",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_svs_trk1_idx_t=secondary_vertices["dev_svs_trk1_idx"],
        dev_svs_trk2_idx_t=secondary_vertices["dev_svs_trk2_idx"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_track_offsets_t=forward_tracks["dev_offsets_forward_tracks"],
        dev_track_hits_offsets_t=prefix_sum_long_track_hits.
        dev_output_buffer_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        dev_lhcbid_containers_t=gather_selections.dev_lhcbid_containers_t)

    prefix_sum_track_tags = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_track_tags",
        dev_input_buffer_t=calc_rb_hits_size.dev_track_tags_t)

    prefix_sum_sv_tags = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_sv_tags",
        dev_input_buffer_t=calc_rb_hits_size.dev_sv_tags_t)

    prefix_sum_selected_hits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_selected_hits",
        dev_input_buffer_t=calc_rb_hits_size.dev_tag_hits_counts_t)

    prefix_sum_hits_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_hits_size",
        dev_input_buffer_t=calc_rb_hits_size.dev_hits_bank_size_t)

    calc_rb_substr_size = make_algorithm(
        calc_rb_substr_size_t,
        name="calc_rb_substr_size",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_candidate_count_t=calc_rb_hits_size.dev_candidate_count_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t,
        dev_sel_track_count_t=calc_rb_hits_size.dev_sel_track_count_t,
        dev_sel_sv_count_t=calc_rb_hits_size.dev_sel_sv_count_t)

    prefix_sum_substr_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_substr_size",
        dev_input_buffer_t=calc_rb_substr_size.dev_substr_bank_size_t)

    prefix_sum_stdinfo_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_stdinfo_size",
        dev_input_buffer_t=calc_rb_substr_size.dev_stdinfo_bank_size_t)

    prefix_sum_candidate_count = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_candidate_count",
        dev_input_buffer_t=calc_rb_hits_size.dev_candidate_count_t)

    make_rb_hits = make_algorithm(
        make_rb_hits_t,
        name="make_rb_hits",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_total_hits_bank_size_t=prefix_sum_hits_size.
        host_total_sum_holder_t,
        dev_hits_container_t=make_hits_container.dev_hits_container_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_sel_hits_offsets_t=prefix_sum_selected_hits.dev_output_buffer_t,
        dev_hits_offsets_t=prefix_sum_long_track_hits.dev_output_buffer_t,
        dev_rb_hits_offsets_t=prefix_sum_hits_size.dev_output_buffer_t,
        dev_sel_track_tables_t=calc_rb_hits_size.dev_sel_track_tables_t)

    make_rb_substr = make_algorithm(
        make_rb_substr_t,
        name="make_rb_substr",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_substr_bank_size_t=prefix_sum_substr_size.host_total_sum_holder_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_offsets_forward_tracks_t=forward_tracks[
            "dev_offsets_forward_tracks"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_sel_track_tables_t=calc_rb_hits_size.dev_sel_track_tables_t,
        dev_sel_sv_tables_t=calc_rb_hits_size.dev_sel_sv_tables_t,
        dev_svs_trk1_idx_t=secondary_vertices["dev_svs_trk1_idx"],
        dev_svs_trk2_idx_t=secondary_vertices["dev_svs_trk2_idx"],
        dev_sel_count_t=calc_rb_substr_size.dev_sel_count_t,
        dev_sel_list_t=calc_rb_substr_size.dev_sel_list_t,
        dev_substr_sel_size_t=calc_rb_substr_size.dev_substr_sel_size_t,
        dev_rb_substr_offsets_t=prefix_sum_substr_size.dev_output_buffer_t,
        dev_candidate_count_t=calc_rb_hits_size.dev_candidate_count_t,
        dev_candidate_offsets_t=prefix_sum_candidate_count.dev_output_buffer_t,
        dev_lhcbid_containers_t=gather_selections.dev_lhcbid_containers_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t)

    make_rb_stdinfo = make_algorithm(
        make_rb_stdinfo_t,
        name="make_rb_stdinfo",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_stdinfo_bank_size_t=prefix_sum_stdinfo_size.
        host_total_sum_holder_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_rb_stdinfo_bank_offsets_t=prefix_sum_stdinfo_size.
        dev_output_buffer_t,
        dev_sel_count_t=calc_rb_substr_size.dev_sel_count_t,
        dev_sel_sv_count_t=calc_rb_hits_size.dev_sel_sv_count_t,
        dev_sel_track_count_t=calc_rb_hits_size.dev_sel_track_count_t,
        dev_sel_list_t=calc_rb_substr_size.dev_sel_list_t)

    make_rb_objtyp = make_algorithm(
        make_rb_objtyp_t,
        name="make_rb_objtyp",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_sel_count_t=calc_rb_substr_size.dev_sel_count_t,
        dev_sel_sv_count_t=calc_rb_hits_size.dev_sel_sv_count_t,
        dev_sel_track_count_t=calc_rb_hits_size.dev_sel_track_count_t)

    calc_selrep_size = make_algorithm(
        calc_selrep_size_t,
        name="calc_selrep_size",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_rb_hits_offsets_t=prefix_sum_hits_size.dev_output_buffer_t,
        dev_rb_substr_offsets_t=prefix_sum_substr_size.dev_output_buffer_t,
        dev_rb_stdinfo_offsets_t=prefix_sum_stdinfo_size.dev_output_buffer_t,
        dev_rb_objtyp_t=make_rb_objtyp.dev_rb_objtyp_t)

    prefix_sum_selrep_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_selrep_size",
        dev_input_buffer_t=calc_selrep_size.dev_selrep_sizes_t)

    make_selreps = make_algorithm(
        make_selrep_t,
        name="make_selreps",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_selrep_size_t=prefix_sum_selrep_size.host_total_sum_holder_t,
        dev_selrep_offsets_t=prefix_sum_selrep_size.dev_output_buffer_t,
        dev_rb_hits_offsets_t=prefix_sum_hits_size.dev_output_buffer_t,
        dev_rb_substr_offsets_t=prefix_sum_substr_size.dev_output_buffer_t,
        dev_rb_stdinfo_offsets_t=prefix_sum_stdinfo_size.dev_output_buffer_t,
        dev_rb_objtyp_t=make_rb_objtyp.dev_rb_objtyp_t,
        dev_rb_hits_t=make_rb_hits.dev_rb_hits_t,
        dev_rb_substr_t=make_rb_substr.dev_rb_substr_t,
        dev_rb_stdinfo_t=make_rb_stdinfo.dev_rb_stdinfo_t)

    return {
        "dev_sel_reports": make_selreps.dev_sel_reports_t,
        "dev_selrep_offsets": prefix_sum_selrep_size.dev_output_buffer_t
    }
