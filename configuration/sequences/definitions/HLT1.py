###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.algorithms import *
from definitions.utils import initialize_number_of_events, mep_layout, gec
from definitions.hlt1_reconstruction import hlt1_reconstruction, validator_node
from definitions.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line
from definitions.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line
from definitions.hlt1_alignment_lines import make_d2kpi_line
from definitions.hlt1_muon_lines import make_single_high_pt_muon_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line
from definitions.hlt1_technical_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line, make_passthrough_line

from definitions.event_list_utils import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import make_leaf
from PyConf.tonic import configurable
from definitions.odin import decode_odin
from definitions.persistency import make_gather_selections, make_dec_reporter


@configurable
def default_hlt1_lines(velo_tracks,
                       forward_tracks,
                       secondary_vertices,
                       withGECPassthrough=True):
    line_algorithms = {
        "Hlt1TrackMVA":
        make_track_mva_line(forward_tracks, secondary_vertices),
        "Hlt1TwoTrackMVA":
        make_two_track_mva_line(forward_tracks, secondary_vertices),
        "Hlt1NoBeam":
        make_beam_line(
            beam_crossing_type="0",
            pre_scaler_hash_string="no_beam_line_pre",
            post_scaler_hash_string="no_beam_line_post"),
        "Hlt1BeamOne":
        make_beam_line(
            beam_crossing_type="1",
            pre_scaler_hash_string="beam_one_line_pre",
            post_scaler_hash_string="beam_one_line_post"),
        "Hlt1BeamTwo":
        make_beam_line(
            beam_crossing_type="2",
            pre_scaler_hash_string="beam_two_line_pre",
            post_scaler_hash_string="beam_two_line_post"),
        "Hlt1BothBeams":
        make_beam_line(
            beam_crossing_type="3",
            pre_scaler_hash_string="both_beams_line_pre",
            post_scaler_hash_string="both_beams_line_post"),
        "Hlt1VeloMicroBias":
        make_velo_micro_bias_line(velo_tracks),
        "Hlt1ODINLumi":
        make_odin_event_type_line(
            odin_event_type="0x8",
            pre_scaler_hash_string="odin_lumi_line_pre",
            post_scaler_hash_string="odin_lumi_line_post"),
        "Hlt1ODINNoBias":
        make_odin_event_type_line(
            odin_event_type="0x4",
            pre_scaler_hash_string="odin_no_bias_pre",
            post_scaler_hash_string="odin_no_bias_post"),
        "Hlt1SingleHighPtMuon":
        make_single_high_pt_muon_line(forward_tracks, secondary_vertices),
        "Hlt1LowPtMuon":
        make_low_pt_muon_line(forward_tracks, secondary_vertices),
        "Hlt1D2KK":
        make_d2kk_line(forward_tracks, secondary_vertices),
        "Hlt1D2KPi":
        make_d2kpi_line(forward_tracks, secondary_vertices),
        "Hlt1D2PiPi":
        make_d2pipi_line(forward_tracks, secondary_vertices),
        "Hlt1DiMuonHighMass":
        make_di_muon_mass_line(forward_tracks, secondary_vertices),
        "Hlt1DiMuonLowMass":
        make_di_muon_mass_line(
            forward_tracks,
            secondary_vertices,
            name="Hlt1DiMuonLowMass",
            pre_scaler_hash_string="di_muon_low_mass_line_pre",
            post_scaler_hash_string="di_muon_low_mass_line_post",
            minHighMassTrackPt="500.",
            minHighMassTrackP="3000.",
            minMass="0.",
            maxDoca="0.2",
            maxVertexChi2="25.",
            minIPChi2="4."),
        "Hlt1DiMuonSoft":
        make_di_muon_soft_line(forward_tracks, secondary_vertices),
        "Hlt1LowPtDiMuon":
        make_low_pt_di_muon_line(forward_tracks, secondary_vertices),
        "Hlt1TrackMuonMVA":
        make_track_muon_mva_line(forward_tracks, secondary_vertices),
        "Hlt1Passthrough":
        make_passthrough_line(),
    }

    if (withGECPassthrough == True):
        line_algorithms["Hlt1GECPassthrough"] = make_passthrough_line(
            name="Hlt1GECPassthrough",
            pre_scaler_hash_string="passthrough_with_gec_line_pre",
            post_scaler_hash_string="passthrough_with_gec_line_post")

    return line_algorithms


# Helper function to make composite nodes with the gec
def make_line_composite_node_with_gec(alg_name,
                                      line_algorithms,
                                      gec_name="gec"):
    return CompositeNode(
        alg_name,
        [
            make_leaf(name=gec_name, alg=gec()),
            make_leaf(alg_name, alg=line_algorithms[alg_name])
        ],
        NodeLogic.LAZY_AND,
        forceOrder=True)


def default_lines_leaf_with_GEC(line_algorithms):
    track_mva_line = make_line_composite_node_with_gec("Hlt1TrackMVA",
                                                       line_algorithms)
    two_track_mva_line = make_line_composite_node_with_gec(
        "Hlt1TwoTrackMVA", line_algorithms)
    no_beam_line = make_line_composite_node_with_gec("Hlt1NoBeam",
                                                     line_algorithms)
    one_beam_line = make_line_composite_node_with_gec("Hlt1BeamOne",
                                                      line_algorithms)
    two_beam_line = make_line_composite_node_with_gec("Hlt1BeamTwo",
                                                      line_algorithms)
    both_beam_line = make_line_composite_node_with_gec("Hlt1BothBeams",
                                                       line_algorithms)
    velo_micro_bias_line = make_line_composite_node_with_gec(
        "Hlt1VeloMicroBias", line_algorithms)
    odin_lumi_line = make_line_composite_node_with_gec("Hlt1ODINLumi",
                                                       line_algorithms)
    odin_no_bias_line = make_line_composite_node_with_gec(
        "Hlt1ODINNoBias", line_algorithms)
    single_high_pt_muon_line = make_line_composite_node_with_gec(
        "Hlt1SingleHighPtMuon", line_algorithms)
    low_pt_muon_line = make_line_composite_node_with_gec(
        "Hlt1LowPtMuon", line_algorithms)
    d2kk_line = make_line_composite_node_with_gec("Hlt1D2KK", line_algorithms)
    d2kpi_line = make_line_composite_node_with_gec("Hlt1D2KPi",
                                                   line_algorithms)
    d2pipi_line = make_line_composite_node_with_gec("Hlt1D2PiPi",
                                                    line_algorithms)
    di_muon_high_mass_line = make_line_composite_node_with_gec(
        "Hlt1DiMuonHighMass", line_algorithms)
    di_muon_low_mass_line = make_line_composite_node_with_gec(
        "Hlt1DiMuonLowMass", line_algorithms)
    di_muon_soft_line = make_line_composite_node_with_gec(
        "Hlt1DiMuonSoft", line_algorithms)
    low_pt_di_muon_line = make_line_composite_node_with_gec(
        "Hlt1LowPtDiMuon", line_algorithms)
    track_muon_mva_line = make_line_composite_node_with_gec(
        "Hlt1TrackMuonMVA", line_algorithms)
    passthrough_with_gec_line = make_line_composite_node_with_gec(
        "Hlt1GECPassthrough", line_algorithms)
    passthrough_line = make_leaf(
        "Hlt1Passthrough", alg=line_algorithms["Hlt1Passthrough"])

    return CompositeNode(
        "AllLines",
        [
            track_mva_line, two_track_mva_line, no_beam_line, one_beam_line,
            two_beam_line, both_beam_line, velo_micro_bias_line,
            odin_lumi_line, odin_no_bias_line, single_high_pt_muon_line,
            low_pt_muon_line, d2kk_line, d2kpi_line, d2pipi_line,
            di_muon_high_mass_line, di_muon_low_mass_line, di_muon_soft_line,
            low_pt_di_muon_line, track_muon_mva_line,
            passthrough_with_gec_line, passthrough_line
        ],
        NodeLogic.NONLAZY_OR,
        forceOrder=False
    )


def default_lines_leaf_no_GEC(line_algorithms):
    track_mva_line = make_leaf(
        "Hlt1TrackMVA", alg=line_algorithms["Hlt1TrackMVA"])
    two_track_mva_line = make_leaf(
        "Hlt1TwoTrackMVA", alg=line_algorithms["Hlt1TwoTrackMVA"])
    no_beam_line = make_leaf("Hlt1NoBeam", alg=line_algorithms["Hlt1NoBeam"])
    one_beam_line = make_leaf(
        "Hlt1BeamOne", alg=line_algorithms["Hlt1BeamOne"])
    two_beam_line = make_leaf(
        "Hlt1BeamTwo", alg=line_algorithms["Hlt1BeamTwo"])
    both_beam_line = make_leaf(
        "Hlt1BothBeams", alg=line_algorithms["Hlt1BothBeams"])
    velo_micro_bias_line = make_leaf(
        "Hlt1VeloMicroBias", alg=line_algorithms["Hlt1VeloMicroBias"])
    odin_lumi_line = make_leaf(
        "Hlt1ODINLumi", alg=line_algorithms["Hlt1ODINLumi"])
    odin_no_bias_line = make_leaf(
        "Hlt1ODINNoBias", alg=line_algorithms["Hlt1ODINNoBias"])
    single_high_pt_muon_line = make_leaf(
        "Hlt1SingleHighPtMuon", alg=line_algorithms["Hlt1SingleHighPtMuon"])
    low_pt_muon_line = make_leaf(
        "Hlt1LowPtMuon", alg=line_algorithms["Hlt1LowPtMuon"])
    d2kk_line = make_leaf("Hlt1D2KK", alg=line_algorithms["Hlt1D2KK"])
    d2kpi_line = make_leaf("Hlt1D2KPi", alg=line_algorithms["Hlt1D2KPi"])
    d2pipi_line = make_leaf("Hlt1D2PiPi", alg=line_algorithms["Hlt1D2PiPi"])
    di_muon_high_mass_line = make_leaf(
        "Hlt1DiMuonHighMass", alg=line_algorithms["Hlt1DiMuonHighMass"])
    di_muon_low_mass_line = make_leaf(
        "Hlt1DiMuonLowMass", alg=line_algorithms["Hlt1DiMuonLowMass"])
    di_muon_soft_line = make_leaf(
        "Hlt1DiMuonSoft", alg=line_algorithms["Hlt1DiMuonSoft"])
    low_pt_di_muon_line = make_leaf(
        "Hlt1LowPtDiMuon", alg=line_algorithms["Hlt1LowPtDiMuon"])
    track_muon_mva_line = make_leaf(
        "Hlt1TrackMuonMVA", alg=line_algorithms["Hlt1TrackMuonMVA"])
    passthrough_line = make_leaf(
        "Hlt1Passthrough", alg=line_algorithms["Hlt1Passthrough"])

    return CompositeNode(
        "AllLines",
        [
            track_mva_line, two_track_mva_line, no_beam_line, one_beam_line,
            two_beam_line, both_beam_line, velo_micro_bias_line,
            odin_lumi_line, odin_no_bias_line, single_high_pt_muon_line,
            low_pt_muon_line, d2kk_line, d2kpi_line, d2pipi_line,
            di_muon_high_mass_line, di_muon_low_mass_line, di_muon_soft_line,
            low_pt_di_muon_line, track_muon_mva_line, passthrough_line
        ],
        NodeLogic.NONLAZY_OR,
        forceOrder=False
    )


def setup_hlt1_node(withMCChecking=False, EnableGEC=True):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()

    # All line algorithms that will be used.
    # We will need them in two places: The nodes, and the gather selection algorithm, which expects
    # a list of the active lines.
    line_algorithms = default_hlt1_lines(
        reconstructed_objects["velo_tracks"],
        reconstructed_objects["forward_tracks"],
        reconstructed_objects["secondary_vertices"])

    if EnableGEC:
        lines_leaf = default_lines_leaf_with_GEC(line_algorithms)
    else:
        lines_leaf = default_lines_leaf_no_GEC(line_algorithms)

    hlt1_node = CompositeNode(
        "Allen",
        [
            lines_leaf,
            make_leaf(
                name="dec_reporter",
                alg=make_dec_reporter(lines=line_algorithms.values()))
        ],
        NodeLogic.NONLAZY_AND,
        forceOrder=True)

    if not withMCChecking:
        return hlt1_node
    else:
        validation_node = validator_node(reconstructed_objects,
                                         line_algorithms)

        node = CompositeNode(
            "AllenWithValidators",
            [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            forceOrder=False)

        return node
