###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.InitSequence import gec
from definitions.HLT1Sequence import (
    fit_vertices,
    make_track_mva_line,
    make_two_track_mva_line,
    make_beam_line,
    make_velo_micro_bias_line,
    make_odin_event_type_line,
    make_single_high_pt_muon_line,
    make_low_pt_muon_line,
    make_d2kk_line,
    make_d2kpi_line,
    make_d2pipi_line,
    make_di_muon_mass_line,
    make_di_muon_soft_line,
    make_low_pt_di_muon_line,
    make_track_muon_mva_line,
    make_passthrough_line,
    make_gather_selections,
    make_dec_reporter,
)
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf

velo_sequence = VeloSequence(doGEC=False)

pv_sequence = PVSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

lines_leaf = CompositeNode(
    "AllLines",
    [
        track_mva_line, two_track_mva_line, no_beam_line, one_beam_line,
        two_beam_line, both_beam_line, velo_micro_bias_line, odin_lumi_line,
        odin_no_bias_line, single_high_pt_muon_line, low_pt_muon_line,
        d2kk_line, d2kpi_line, d2pipi_line, di_muon_high_mass_line,
        di_muon_low_mass_line, di_muon_soft_line, low_pt_di_muon_line,
        track_muon_mva_line, passthrough_with_gec_line, passthrough_line
    ],
    NodeLogic.NONLAZY_OR,
    forceOrder=False,
)

gather_selections_node = CompositeNode(
    "Allen",
    [
        lines_leaf,
        make_leaf(
            name="gather_selections",
            alg=make_gather_selections(lines=line_algorithms.values()))
    ], NodeLogic.NONLAZY_AND,
    forceOrder=True)

muon_sequence = MuonSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks_t=forward_sequence["scifi_consolidate_tracks_t"])

hlt1_sequence = HLT1Sequence(
    layout_provider=velo_sequence["mep_layout"],
    initialize_lists=velo_sequence["initialize_lists"],
    full_event_list=velo_sequence["full_event_list"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_kalman_filter=pv_sequence["velo_kalman_filter"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    pv_beamline_multi_fitter=pv_sequence["pv_beamline_cleanup"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks=forward_sequence["scifi_consolidate_tracks_t"],
    is_muon=muon_sequence["is_muon_t"])

compose_sequences(velo_sequence, pv_sequence, ut_sequence, forward_sequence,
                  muon_sequence, hlt1_sequence).generate()
