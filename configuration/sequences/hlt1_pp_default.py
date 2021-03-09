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

# All line algorithms that will be used.
# We will need them in two places: The nodes, and the gather selection algorithm, which expects
# a list of the active lines.
line_algorithms = {
    "Hlt1TrackMVA":
    make_track_mva_line(),
    "Hlt1TwoTrackMVA":
    make_two_track_mva_line(),
    "Hlt1NoBeam":
    make_beam_line(beam_crossing_type="0",
        pre_scaler_hash_string="no_beam_line_pre",
        post_scaler_hash_string="no_beam_line_post"),
    "Hlt1BeamOne":
    make_beam_line(beam_crossing_type="1",
        pre_scaler_hash_string="beam_one_line_pre",
        post_scaler_hash_string="beam_one_line_post"),
    "Hlt1BeamTwo":
    make_beam_line(beam_crossing_type="2",
        pre_scaler_hash_string="beam_two_line_pre",
        post_scaler_hash_string="beam_two_line_post"),
    "Hlt1BothBeams":
    make_beam_line(beam_crossing_type="3",
        pre_scaler_hash_string="both_beams_line_pre",
        post_scaler_hash_string="both_beams_line_post"),
    "Hlt1VeloMicroBias":
    make_velo_micro_bias_line(),
    "Hlt1ODINLumi":
    make_odin_event_type_line(odin_event_type="0x8",
        pre_scaler_hash_string="odin_lumi_line_pre",
        post_scaler_hash_string="odin_lumi_line_post"),
    "Hlt1ODINNoBias":
    make_odin_event_type_line(odin_event_type="0x4",
        pre_scaler_hash_string="odin_no_bias_pre",
        post_scaler_hash_string="odin_no_bias_post"),
    "Hlt1SingleHighPtMuon":
    make_single_high_pt_muon_line(),
    "Hlt1LowPtMuon":
    make_low_pt_muon_line(),
    "Hlt1D2KK":
    make_d2kk_line(),
    "Hlt1D2KPi":
    make_d2kpi_line(),
    "Hlt1D2PiPi":
    make_d2pipi_line(),
    "Hlt1DiMuonHighMass":
    make_di_muon_mass_line(),
    "Hlt1DiMuonLowMass":
    make_di_muon_mass_line(
        name="Hlt1DiMuonLowMass",
        pre_scaler_hash_string="di_muon_low_mass_line_pre",
        post_scaler_hash_string="di_muon_low_mass_line_post",
        minHighMassTrackPt="500",
        minHighMassTrackP="3000",
        minMass="0",
        maxDoca="0.2",
        maxVertexChi2="25",
        minIPChi2="4"),
    "Hlt1DiMuonSoft":
    make_di_muon_soft_line(),
    "Hlt1LowPtDiMuon":
    make_low_pt_di_muon_line(),
    "Hlt1TrackMuonMVA":
    make_track_muon_mva_line(),
    "Hlt1PassthroughWithGEC":
    make_passthrough_line(
        name="Hlt1PassthroughWithGEC",
        pre_scaler_hash_string="passthrough_with_gec_line_pre",
        post_scaler_hash_string="passthrough_with_gec_line_post"),
    "Hlt1Passthrough":
    make_passthrough_line(),
}


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
    "Hlt1PassthroughWithGEC")
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
    forceOrder=False
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

compose_sequences(velo_sequence, pv_sequence, ut_sequence, forward_sequence,
                  muon_sequence, hlt1_sequence).generate()
