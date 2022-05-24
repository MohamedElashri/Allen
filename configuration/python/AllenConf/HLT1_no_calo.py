###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import initialize_number_of_events, mep_layout, line_maker, make_line_composite_node, make_gec, make_checkPV, make_lowmult
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line, make_kstopipi_line, make_two_track_line_ks
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line
from AllenConf.hlt1_muon_lines import make_single_high_pt_muon_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line, make_SMOG2_dimuon_highmass_line, make_SMOG2_ditrack_line, make_SMOG2_singletrack_line

from AllenConf.validators import rate_validation, long_parameters_for_validation, kalman_parameters_for_validation
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin
from AllenConf.persistency import make_gather_selections, make_sel_report_writer


def default_physics_lines(forward_tracks, long_track_particles,
                          secondary_vertices):
    lines = []
    lines.append(
        line_maker(
            make_kstopipi_line(
                forward_tracks, secondary_vertices, name="Hlt1KsToPiPi")))
    lines.append(
        line_maker(
            make_track_mva_line(
                forward_tracks, long_track_particles, name="Hlt1TrackMVA")))
    lines.append(
        line_maker(
            make_two_track_mva_line(
                forward_tracks, secondary_vertices, name="Hlt1TwoTrackMVA")))
    lines.append(
        line_maker(
            make_two_track_line_ks(
                forward_tracks, secondary_vertices, name="Hlt1TwoTrackKs")))
    lines.append(
        line_maker(
            make_single_high_pt_muon_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuon")))
    lines.append(
        line_maker(
            make_low_pt_muon_line(
                forward_tracks, long_track_particles, name="Hlt1LowPtMuon")))
    lines.append(
        line_maker(
            make_d2kk_line(
                forward_tracks, secondary_vertices, name="Hlt1D2KK")))
    lines.append(
        line_maker(
            make_d2kpi_line(
                forward_tracks, secondary_vertices, name="Hlt1D2KPi")))
    lines.append(
        line_maker(
            make_d2pipi_line(
                forward_tracks, secondary_vertices, name="Hlt1D2PiPi")))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks, secondary_vertices,
                name="Hlt1DiMuonHighMass")))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonLowMass",
                minHighMassTrackPt=500.,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=4.)))
    lines.append(
        line_maker(
            make_di_muon_soft_line(
                forward_tracks, secondary_vertices, name="Hlt1DiMuonSoft")))
    lines.append(
        line_maker(
            make_low_pt_di_muon_line(
                forward_tracks, secondary_vertices, name="Hlt1LowPtDiMuon")))
    lines.append(
        line_maker(
            make_track_muon_mva_line(
                forward_tracks, long_track_particles,
                name="Hlt1TrackMuonMVA")))
    return lines


def event_monitoring_lines():
    lines = []
    lines.append(
        line_maker(make_beam_line(name="Hlt1NoBeam", beam_crossing_type=0)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BeamOne", beam_crossing_type=1)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BeamTwo", beam_crossing_type=2)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BothBeams", beam_crossing_type=3)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINLumi", odin_event_type=0x8)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINNoBias", odin_event_type=0x4)))

    return lines


def alignment_monitoring_lines(velo_tracks, forward_tracks,
                               long_track_particles):

    lines = []
    lines.append(
        line_maker(
            make_velo_micro_bias_line(velo_tracks, name="Hlt1VeloMicroBias")))
    lines.append(
        line_maker(
            make_rich_1_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1RICH1Alignment")))
    lines.append(
        line_maker(
            make_rich_2_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1RICH2Alignment")))

    return lines


def default_smog2_lines(velo_tracks, forward_tracks, long_track_particles,
                        secondary_vertices):

    lines = []

    lines.append(
        line_maker(
            make_SMOG2_dimuon_highmass_line(
                secondary_vertices, name="Hlt1_SMOG2_DiMuonHighMass")))

    lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                m1=139.57,
                m2=493.68,
                mMother=1864.83,
                mWindow=150.,
                name="Hlt1_SMOG2_D2Kpi")))

    lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                m1=938.27,
                m2=938.27,
                mMother=2983.6,
                mWindow=150.,
                name="Hlt1_SMOG2_eta2pp")))

    lines.append(
        line_maker(
            make_SMOG2_ditrack_line(
                secondary_vertices,
                minTrackPt=800.,
                name="Hlt1_SMOG2_2BodyGeneric")))

    lines.append(
        line_maker(
            make_SMOG2_singletrack_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1_SMOG2_SingleTrack")))

    return lines


def setup_hlt1_node(withMCChecking=False,
                    EnableGEC=True,
                    withSMOG2=False,
                    enableRateValidator=False):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(add_electron_id=False)

    gec = make_gec()
    with line_maker.bind(prefilter=gec if EnableGEC else None):
        physics_lines = default_physics_lines(
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"],
            reconstructed_objects["secondary_vertices"])

    with line_maker.bind(prefilter=None):
        monitoring_lines = event_monitoring_lines()
        physics_lines += [line_maker(make_passthrough_line())]

    if EnableGEC:
        with line_maker.bind(prefilter=gec):
            physics_lines += [
                line_maker(make_passthrough_line(name="Hlt1GECPassthrough"))
            ]

    with line_maker.bind(prefilter=gec):
        monitoring_lines += alignment_monitoring_lines(
            reconstructed_objects["velo_tracks"],
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"])

    # List of line algorithms,
    #   required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # List of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:
        SMOG2_prefilters, SMOG2_lines = [], []

        lowMult_5 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            name="LowMult_5",
            minTracks=1,
            maxTracks=5)
        with line_maker.bind(prefilter=[gec, lowMult_5]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1GECPassThrough_LowMult5"))
            ]

        bx_BE = make_bxtype("BX_BeamEmpty", bx_type=1)
        with line_maker.bind(prefilter=bx_BE):
            SMOG2_lines += [
                line_maker(make_passthrough_line(name="Hlt1_BESMOG2_NoBias"))
            ]

        lowMult_10 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            name="LowMult_10",
            minTracks=1,
            maxTracks=10)
        with line_maker.bind(prefilter=[bx_BE, lowMult_10]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1_BESMOG2_LowMult10"))
            ]

        if EnableGEC:
            SMOG2_prefilters += [gec]

        with line_maker.bind(prefilter=SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_SMOG2_minimum_bias_line(
                        reconstructed_objects["velo_tracks"],
                        reconstructed_objects["velo_states"],
                        name="Hlt1_SMOG2_MinimumBias"))
            ]

        SMOG2_prefilters += [
            make_checkPV(
                reconstructed_objects['pvs'],
                name='check_SMOG2_PV',
                minZ=-550,
                maxZ=-300)
        ]

        with line_maker.bind(prefilter=SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1Passthrough_PV_in_SMOG2"))
            ]

            SMOG2_lines += default_smog2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["forward_tracks"],
                reconstructed_objects["long_track_particles"],
                reconstructed_objects["secondary_vertices"])

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections_node = CompositeNode(
        "RunAllLines",
        [lines, make_gather_selections(lines=line_algorithms)],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_node = CompositeNode(
        "Allen", [
            gather_selections_node,
            *make_sel_report_writer(
                lines=line_algorithms,
                forward_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"])
            ["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if enableRateValidator:
        hlt1_node = CompositeNode(
            "AllenRateValidation", [
                hlt1_node,
                rate_validation(lines=line_algorithms),
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)

    if not withMCChecking:
        return hlt1_node
    else:
        copied_parameters = {
            "long":
            long_parameters_for_validation(
                reconstructed_objects["forward_tracks"]),
            "kalman":
            kalman_parameters_for_validation(
                reconstructed_objects["kalman_velo_only"])
        }
        validation_node = validator_node(reconstructed_objects,
                                         copied_parameters, line_algorithms)

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        return node
