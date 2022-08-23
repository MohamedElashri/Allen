###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import gather_selections_t, dec_reporter_t, global_decision_t, host_routingbits_writer_t
from AllenAlgorithms.algorithms import host_prefix_sum_t, make_selrep_t
from AllenAlgorithms.algorithms import make_selected_object_lists_t, make_subbanks_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


def _build_decision_ids(decision_names, offset=0):
    """Return a dict of decision names to integer IDs.

    Decision report IDs must not be zero. This method generates IDs starting
    from offset.

    Args:
        decision_names (list of str)
        offset (int): needed so that there are no identical ints in the int->str relations
        of HltRawBankDecoderBase

    Returns:
        decision_ids (dict of str to int): Mapping from decision name to ID.
    """
    return {name: idx for idx, name in enumerate(decision_names, offset)}


# Example routing bits map to be passed as property in the host_routingbits_writer algorithm
rb_map = {
    # RB 1 Lumi after HLT1
    '^Hlt1.*Lumi.*':
    1,
    # RB 3 Beam-Gas for Velo alignment
    'Hlt1(?!BeamGasHighRhoVertices)BeamGas.*':
    3,
    # Hlt1ODINBeamGas? RB 4 EXPRESS stream (bypasses Hlt2)
    'Hlt1(Velo.*|BeamGas.*VeloOpen)':
    4,
    #RB 5 Beam-Beam collisions for Velo alignment
    'Hlt1(TrackMVA|TwoTrackMVA|TwoTrackCatBoost|TrackMuonMVA)':
    5,
    # RB 8 Velo (closing) monitoring
    'Hlt1ODINVelo.*':
    8,
    #RB 14 HLT1 physics for monitoring and alignment
    'Hlt1(?!ODIN)(?!L0)(?!Lumi)(?!Tell1)(?!MB)(?!NZS)(?!Velo)(?!BeamGas)(?!Incident).*':
    14,
    #RB 16 NoBias, prescaled
    'Hlt1.*NoBias':
    16,
    # RB 21 Tracker alignment
    'Hlt1D2KPi':
    21,
    #RB 22 RICH mirror alignment
    'Hlt1RICH.*Alignment':
    22,
    #RB 24 Muon alignment
    'Hlt1CalibMuonAlignJpsi':
    24,
    #RB 25 Tell1 Error events
    'Hlt1Tell1Error':
    25
}


def make_gather_selections(lines):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        gather_selections_t,
        name="gather_selections",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_decisions_sizes_t=[line.host_decisions_size_t for line in lines],
        host_input_post_scale_factors_t=[
            line.host_post_scaler_t for line in lines
        ],
        host_input_post_scale_hashes_t=[
            line.host_post_scaler_hash_t for line in lines
        ],
        dev_odin_data_t=odin["dev_odin_data"],
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


def make_routingbits_writer(lines):
    gather_selections = make_gather_selections(lines)
    dec_reporter = make_dec_reporter(lines)
    number_of_events = initialize_number_of_events()
    name_to_decID_map = _build_decision_ids([line.name for line in lines])
    return make_algorithm(
        host_routingbits_writer_t,
        name="host_routingbits_writer",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        host_names_of_active_lines_t=gather_selections.
        host_names_of_active_lines_t,
        host_dec_reports_t=dec_reporter.host_dec_reports_t,
        routingbit_map=rb_map,
        name_to_id_map=name_to_decID_map)


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

    prefix_sum_max_objects = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_max_objects",
        dev_input_buffer_t=dec_reporter.dev_selected_candidates_counts_t)

    make_selected_object_lists = make_algorithm(
        make_selected_object_lists_t,
        name="make_selected_object_lists",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        host_max_objects_t=prefix_sum_max_objects.host_total_sum_holder_t,
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_multi_event_particle_containers_t=gather_selections.
        dev_particle_containers_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        dev_max_objects_offsets_t=prefix_sum_max_objects.dev_output_buffer_t)

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
        dev_max_objects_offsets_t=prefix_sum_max_objects.dev_output_buffer_t,
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
