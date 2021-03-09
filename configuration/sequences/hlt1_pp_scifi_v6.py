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

velo_sequence = VeloSequence()

pv_sequence = PVSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

ut_sequence = UTSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"],
    host_ut_banks=velo_sequence["host_ut_banks"])

forward_sequence = ForwardSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    forward_decoding="v6",
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

# Helper function to make composite nodes with the gec
def make_line_composite_node_with_gec(alg_name, gec_name="gec", **kwargs):
    return CompositeNode(
        alg_name,
        [
            make_leaf(name=gec_name, alg=gec(**kwargs)),
            make_leaf(alg_name, alg=line_algorithms[alg_name])
        ],
        NodeLogic.LAZY_AND,
        forceOrder=True)

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

track_mva_line = make_line_composite_node_with_gec("Hlt1TrackMVA")
two_track_mva_line = make_line_composite_node_with_gec("Hlt1TwoTrackMVA")
no_beam_line = make_line_composite_node_with_gec("Hlt1NoBeam")
one_beam_line = make_line_composite_node_with_gec("Hlt1BeamOne")
two_beam_line = make_line_composite_node_with_gec("Hlt1BeamTwo")
both_beam_line = make_line_composite_node_with_gec("Hlt1BothBeams")
velo_micro_bias_line = make_line_composite_node_with_gec("Hlt1VeloMicroBias")
odin_lumi_line = make_line_composite_node_with_gec("Hlt1ODINLumi")
odin_no_bias_line = make_line_composite_node_with_gec("Hlt1ODINNoBias")
single_high_pt_muon_line = make_line_composite_node_with_gec(
    "Hlt1SingleHighPtMuon")
low_pt_muon_line = make_line_composite_node_with_gec("Hlt1LowPtMuon")
d2kk_line = make_line_composite_node_with_gec("Hlt1D2KK")
d2kpi_line = make_line_composite_node_with_gec("Hlt1D2KPi")
d2pipi_line = make_line_composite_node_with_gec("Hlt1D2PiPi")
di_muon_high_mass_line = make_line_composite_node_with_gec(
    "Hlt1DiMuonHighMass")
di_muon_low_mass_line = make_line_composite_node_with_gec("Hlt1DiMuonLowMass")
di_muon_soft_line = make_line_composite_node_with_gec("Hlt1DiMuonSoft")
low_pt_di_muon_line = make_line_composite_node_with_gec("Hlt1LowPtDiMuon")
track_muon_mva_line = make_line_composite_node_with_gec("Hlt1TrackMuonMVA")
passthrough_with_gec_line = make_line_composite_node_with_gec(
    "Hlt1GECPassthrough")
passthrough_line = make_leaf(
    "Hlt1Passthrough", alg=line_algorithms["Hlt1Passthrough"])

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
            name="dec_reporter",
            alg=make_dec_reporter(lines=line_algorithms.values()))
    ], NodeLogic.NONLAZY_AND,
    forceOrder=True)

generate(gather_selections_node)

# # Generate a pydot graph out of the configuration
# from pydot import Graph
# y = Graph()
# gather_selections_node._graph(y)
# with open('blub.dot', 'w') as f:
#     f.write(y.to_string())
