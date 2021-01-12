###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.MuonSequence import MuonSequence
from definitions.HLT1Sequence import HLT1Sequence
from definitions.algorithms import compose_sequences

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
        NodeLogic.AND, [
            make_leaf(name=gec_name, alg=gec(**kwargs)),
            make_leaf(alg_name, alg=line_algorithms[alg_name])
        ],
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
