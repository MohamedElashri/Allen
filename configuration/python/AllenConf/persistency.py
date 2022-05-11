###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import gather_selections_t, dec_reporter_t, global_decision_t
from AllenConf.algorithms import host_prefix_sum_t, make_selrep_t
from AllenConf.algorithms import make_selected_object_lists_t, make_subbanks_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


def make_gather_selections(lines):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        gather_selections_t,
        name="gather_selections",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        host_decisions_sizes_t=[line.host_decisions_size_t for line in lines],
        host_input_post_scale_factors_t=[
            line.host_post_scaler_t for line in lines
        ],
        host_input_post_scale_hashes_t=[
            line.host_post_scaler_hash_t for line in lines
        ],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        names_of_active_lines=",".join([line.name for line in lines]),
        names_of_active_line_algorithms=",".join(
            [line.typename for line in lines]),
        host_fn_parameters_agg_t=[line.host_fn_parameters_t for line in lines])


@configurable
def make_dec_reporter(lines, TCK=0):
    gather_selections = make_gather_selections(lines)
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        dec_reporter_t,
        name="dec_reporter",
        tck=TCK,
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

    make_selected_object_lists = make_algorithm(
        make_selected_object_lists_t,
        name="make_selected_object_lists",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_multi_event_particle_containers_t=gather_selections.
        dev_particle_containers_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t)

    prefix_sum_hits_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_hits_size",
        dev_input_buffer_t=make_selected_object_lists.dev_hits_bank_size_t)

    prefix_sum_substr_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_substr_size",
        dev_input_buffer_t=make_selected_object_lists.dev_substr_bank_size_t)

    prefix_sum_objtyp_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_objtyp_size",
        dev_input_buffer_t=make_selected_object_lists.dev_objtyp_bank_size_t)

    prefix_sum_stdinfo_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_stdinfo_size",
        dev_input_buffer_t=make_selected_object_lists.dev_stdinfo_bank_size_t)

    prefix_sum_candidate_count = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_candidate_count",
        dev_input_buffer_t=make_selected_object_lists.dev_candidate_count_t)

    prefix_sum_selrep_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_selrep_size",
        dev_input_buffer_t=make_selected_object_lists.dev_selrep_size_t)

    make_subbanks = make_algorithm(
        make_subbanks_t,
        name="make_subbanks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_substr_bank_size_t=prefix_sum_substr_size.host_total_sum_holder_t,
        host_hits_bank_size_t=prefix_sum_hits_size.host_total_sum_holder_t,
        host_objtyp_bank_size_t=prefix_sum_objtyp_size.host_total_sum_holder_t,
        host_stdinfo_bank_size_t=prefix_sum_stdinfo_size.
        host_total_sum_holder_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        dev_sel_count_t=make_selected_object_lists.dev_sel_count_t,
        dev_sel_list_t=make_selected_object_lists.dev_sel_list_t,
        dev_candidate_count_t=make_selected_object_lists.dev_candidate_count_t,
        dev_candidate_offsets_t=prefix_sum_candidate_count.dev_output_buffer_t,
        dev_unique_track_list_t=make_selected_object_lists.
        dev_unique_track_list_t,
        dev_unique_track_count_t=make_selected_object_lists.
        dev_unique_track_count_t,
        dev_unique_sv_list_t=make_selected_object_lists.dev_unique_sv_list_t,
        dev_unique_sv_count_t=make_selected_object_lists.dev_unique_sv_count_t,
        dev_track_duplicate_map_t=make_selected_object_lists.
        dev_track_duplicate_map_t,
        dev_sv_duplicate_map_t=make_selected_object_lists.
        dev_sv_duplicate_map_t,
        dev_sel_track_indices_t=make_selected_object_lists.
        dev_sel_track_indices_t,
        dev_sel_sv_indices_t=make_selected_object_lists.dev_sel_sv_indices_t,
        dev_multi_event_particle_containers_t=gather_selections.
        dev_particle_containers_t,
        dev_basic_particle_ptrs_t=make_selected_object_lists.
        dev_selected_basic_particle_ptrs_t,
        dev_composite_particle_ptrs_t=make_selected_object_lists.
        dev_selected_composite_particle_ptrs_t,
        dev_rb_substr_offsets_t=prefix_sum_substr_size.dev_output_buffer_t,
        dev_substr_sel_size_t=make_selected_object_lists.dev_substr_sel_size_t,
        dev_substr_sv_size_t=make_selected_object_lists.dev_substr_sv_size_t,
        dev_rb_hits_offsets_t=prefix_sum_hits_size.dev_output_buffer_t,
        dev_rb_objtyp_offsets_t=prefix_sum_objtyp_size.dev_output_buffer_t,
        dev_rb_stdinfo_offsets_t=prefix_sum_stdinfo_size.dev_output_buffer_t)

    make_selreps = make_algorithm(
        make_selrep_t,
        name="make_selreps",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_selrep_size_t=prefix_sum_selrep_size.host_total_sum_holder_t,
        dev_selrep_offsets_t=prefix_sum_selrep_size.dev_output_buffer_t,
        dev_rb_objtyp_offsets_t=prefix_sum_objtyp_size.dev_output_buffer_t,
        dev_rb_hits_offsets_t=prefix_sum_hits_size.dev_output_buffer_t,
        dev_rb_substr_offsets_t=prefix_sum_substr_size.dev_output_buffer_t,
        dev_rb_stdinfo_offsets_t=prefix_sum_stdinfo_size.dev_output_buffer_t,
        dev_rb_objtyp_t=make_subbanks.dev_rb_objtyp_t,
        dev_rb_hits_t=make_subbanks.dev_rb_hits_t,
        dev_rb_substr_t=make_subbanks.dev_rb_substr_t,
        dev_rb_stdinfo_t=make_subbanks.dev_rb_stdinfo_t)

    return {
        "algorithms":
        [make_selected_object_lists, make_subbanks, make_selreps],
        "dev_sel_reports": make_selreps.dev_sel_reports_t,
        "dev_selrep_offsets": prefix_sum_selrep_size.dev_output_buffer_t
    }
