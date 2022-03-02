###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import initialize_number_of_events, mep_layout, line_maker, make_line_composite_node, make_gec, make_checkPV, make_lowocc
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line, make_kstopipi_line, make_two_track_line_ks
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line, make_two_ks_line
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line
from AllenConf.hlt1_muon_lines import make_single_high_pt_muon_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line, make_SMOG2_dimuon_highmass_line, make_SMOG2_ditrack_line, make_SMOG2_singletrack_line

from AllenConf.validators import rate_validation
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin
from AllenConf.persistency import make_gather_selections, make_global_decision, make_sel_report_writer



def default_physics_lines(forward_tracks,
                          long_track_particles,
                          secondary_vertices,
                          prefilter_suffix=''):
    lines = []
    lines.append(
        line_maker(
            make_kstopipi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1KsToPiPi" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_track_mva_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1TrackMVA" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_two_track_mva_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1TwoTrackMVA" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_two_track_line_ks(
                forward_tracks,
                secondary_vertices,
                name="Hlt1TwoTrackKs" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_single_high_pt_muon_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuon" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_low_pt_muon_line(
                forward_tracks,
                long_track_particles,
                kalman_velo_only,
                name="Hlt1LowPtMuon" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_d2kk_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2KK" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_d2kpi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2KPi" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_d2pipi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2PiPi" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonHighMass" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_two_ks_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1TwoKs" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonLowMass" + prefilter_suffix,
                minHighMassTrackPt=500.,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=4.)))
    lines.append(
        line_maker(
            make_di_muon_soft_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonSoft" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_low_pt_di_muon_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1LowPtDiMuon" + prefilter_suffix)))
    lines.append(
        line_maker(
            make_track_muon_mva_line(
                forward_tracks,
                long_track_particles
                name="Hlt1TrackMuonMVA" + prefilter_suffix)))
    return lines


def default_monitoring_lines(velo_tracks, prefilter_suffix=''):
    lines = []
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1NoBeam" + prefilter_suffix,
                beam_crossing_type=0 )))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BeamOne" + prefilter_suffix,
                beam_crossing_type=1)))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BeamTwo" + prefilter_suffix,
                beam_crossing_type=2)))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BothBeams" + prefilter_suffix,
                beam_crossing_type=3)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINLumi" + prefilter_suffix,
                odin_event_type=0x8)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINNoBias" + prefilter_suffix,
                odin_event_type=0x4)))

    return lines


def default_smog2_lines(velo_tracks,
                        velo_states,
                        forward_tracks,
                        kalman_velo_only,
                        secondary_vertices,
                        prefilter_suffix=''):

    smog2_lines = []
    smog2_lines.append(
        line_maker(
            make_SMOG2_minimum_bias_line(
                velo_tracks,
                velo_states,
                name="HLT1_SMOG2_MinimumBiasLine" + prefilter_suffix)))

    smog2_lines.append(
        line_maker(
            make_SMOG2_dimuon_highmass_line(
                secondary_vertices,
                name="HLT1_SMOG2_DiMuonHighMassLine" + prefilter_suffix)))

    smog2_lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                m1="139.57f",
                m2="493.67f",
                mMother="1864.83f",
                name="HLT1_SMOG2_D2Kpi" + prefilter_suffix)))

    smog2_lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                m1="938.27f",
                m2="938.27f",
                mMother="2983.6",
                name="HLT1_SMOG2_eta2pp" + prefilter_suffix)))

    smog2_lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                minTrackPt=800,
                name="HLT1_SMOG2_2BodyGeneric" + prefilter_suffix)))

    smog2_lines.append(
        line_maker(
            make_SMOG2_singletrack_line(
                forward_tracks,
                kalman_velo_only,
                name="HLT1_SMOG2_SingleTrack" + prefilter_suffix)))

    return smog2_lines


def setup_hlt1_node(withMCChecking=False, EnableGEC=True, withSMOG2=False):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()

    pp_prefilters, physics_lines, prefilter_suffix = [], [], ''
    if EnableGEC:
        gec = make_gec()
        pp_prefilters += [gec]
        prefilter_suffix += '_gec'

    pp_checkPV = make_checkPV(
        reconstructed_objects['pvs'],
        name='pp_checkPV',
        minZ='-300',  #mm
        maxZ='+300'   #mm
    )

    pp_prefilters    += [pp_checkPV]
    prefilter_suffix += '_pp_checkPV'

    with line_maker.bind(prefilter=pp_prefilters):
        physics_lines = default_physics_lines(
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"],
            reconstructed_objects["secondary_vertices"])

    monitoring_lines = default_monitoring_lines(
        reconstructed_objects["velo_tracks"],
        reconstructed_objects["forward_tracks"],
        reconstructed_objects["long_track_particles"])

    with line_maker.bind(prefilter=None):
        physics_lines += [ line_maker( make_passthrough_line()) ]

    if EnableGEC:
        with line_maker.bind(prefilter=gec):
            physics_lines += [line_maker( make_passthrough_line(name="Hlt1Passthrough_gec") )]


    if EnableGEC:
        with line_maker.bind(prefilter = gec):
            monitoring_lines.append(
                line_maker(
                    make_velo_micro_bias_line(
                        reconstructed_objects["velo_tracks"],
                        name="Hlt1VeloMicroBias_gec") ))
            monitoring_lines.append(
                line_maker(
                    make_rich_1_line(
                        hlt1_reconstruction(), name="Hlt1RICH1Alignment_gec")))
            monitoring_lines.append(
                line_maker(
                    make_rich_2_line(
                        hlt1_reconstruction(), name="HLt1RICH2Alignment_gec")))

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:
        SMOG2_prefilters, SMOG2_lines, prefilter_suffix = [], [], ''

        lowOcc_5 = make_lowocc(
            reconstructed_objects['velo_tracks'], minTracks='1', maxTracks='5')
        with line_maker.bind(prefilter=lowOcc_5):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1PassThrough_LowOcc5"))]

        if EnableGEC:
            SMOG2_prefilters += [gec]
            prefilter_suffix += '_gec'

        SMOG2_prefilters += [
            make_checkPV(
                reconstructed_objects['pvs'],
                name='check_SMOG2_PV',
                minZ='-550',  #mm
                maxZ='-300'  #mm
            )
        ]

        prefilter_suffix += '_SMOG2_checkPV'

        with line_maker.bind(prefilter=SMOG2_prefilters):
            SMOG2_lines += default_smog2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["velo_states"],
                reconstructed_objects["forward_tracks"],
                reconstructed_objects["kalman_velo_only"],
                reconstructed_objects["secondary_vertices"],
                prefilter_suffix=prefilter_suffix)

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            make_global_decision(lines=line_algorithms),
            rate_validation(lines=line_algorithms),
            *make_sel_report_writer(
                lines=line_algorithms,
                forward_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"])
            ["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if not withMCChecking:
        return hlt1_node
    else:
        validation_node = validator_node(reconstructed_objects,
                                         line_algorithms)

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        return node
