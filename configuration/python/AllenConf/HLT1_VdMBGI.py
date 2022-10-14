###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import (line_maker, make_gec, make_checkPV,
                             make_checkCylPV, make_lowmult)
from AllenConf.odin import make_bxtype, odin_error_filter
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_monitoring_lines import (
    make_beam_line, make_velo_clusters_micro_bias_line,
    make_calo_digits_minADC_line)
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_gather_selections, make_sel_report_writer, make_global_decision, make_routingbits_writer
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenCore.generator import is_allen_standalone
from AllenConf.HLT1 import (event_monitoring_lines, alignment_monitoring_lines,
                            default_smog2_lines)


def default_bgi_activity_lines(decoded_velo, decoded_calo, prefilter=[]):
    """
    Detector activity lines for BGI data collection.
    """
    bx_NoBB = make_bxtype("BX_NoBeamBeam", bx_type=3, invert=True)
    lines = [
        line_maker(
            make_velo_clusters_micro_bias_line(
                decoded_velo,
                name="Hlt1BGIVeloClustersMicroBias",
                min_velo_clusters=1),
            prefilter=prefilter + [bx_NoBB]),
        line_maker(
            make_calo_digits_minADC_line(
                decoded_calo, name="Hlt1BGICaloDigits"),
            prefilter=prefilter + [bx_NoBB])
    ]
    return lines


def default_bgi_pvs_lines(pvs, prefilter=[]):
    """
    Primary vertex lines for various bunch crossing types composed from
    new PV filters and beam crossing lines.
    """
    mm = 1.0  # from SystemOfUnits.h
    max_cyl_rad_sq = (3 * mm)**2
    bx_NoBB = make_bxtype("BX_NoBeamBeam", bx_type=3, invert=True)
    pvs_z_all = make_checkCylPV(
        pvs,
        name="BGIPVsCylAll",
        minZ=-2000.,
        maxZ=2000.,
        max_rho_sq=max_cyl_rad_sq,
        min_nTracks=10.)
    lines = []
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylNoBeam",
                beam_crossing_type=0,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylBeamOne",
                beam_crossing_type=1,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylBeamTwo",
                beam_crossing_type=2,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all])
    ]

    pvs_z_up = make_checkCylPV(
        pvs,
        name="BGIPVsCylUp",
        minZ=-2000.,
        maxZ=-250.,
        max_rho_sq=max_cyl_rad_sq,
        min_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylUpBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_up])
    ]

    pvs_z_down = make_checkCylPV(
        pvs,
        name="BGIPVsCylDown",
        minZ=250.,
        maxZ=2000.,
        max_rho_sq=max_cyl_rad_sq,
        min_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylDownBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_down])
    ]

    pvs_z_ir = make_checkCylPV(
        pvs,
        name="BGIPVsCylIR",
        minZ=-250.,
        maxZ=250.,
        max_rho_sq=max_cyl_rad_sq,
        min_nTracks=28.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylIRBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_ir])
    ]

    return lines


def setup_hlt1_node(withMCChecking=False,
                    EnableGEC=False,
                    withSMOG2=True,
                    enableRateValidator=True,
                    with_ut=True,
                    with_lumi=True,
                    with_odin_filter=True,
                    with_calo=True,
                    with_muon=True,
                    matching=False):

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(
        with_calo=with_calo,
        matching=matching,
        with_ut=with_ut,
        with_muon=with_muon)
    decoded_velo = decode_velo()
    decoded_calo = decode_calo()

    gec = [make_gec(count_ut=with_ut)] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []
    prefilters = gec + odin_err_filter

    physics_lines = default_bgi_activity_lines(decoded_velo, decoded_calo,
                                               prefilters)
    physics_lines += default_bgi_pvs_lines(reconstructed_objects["pvs"],
                                           prefilters)

    lumiline_name = "Hlt1ODINLumi"
    with line_maker.bind(prefilter=odin_err_filter):
        monitoring_lines = event_monitoring_lines(with_lumi, lumiline_name)
        physics_lines += [line_maker(make_passthrough_line())]

    if EnableGEC:
        with line_maker.bind(prefilter=prefilters):
            physics_lines += [
                line_maker(make_passthrough_line(name="Hlt1GECPassthrough"))
            ]

    with line_maker.bind(prefilter=prefilters):
        monitoring_lines += alignment_monitoring_lines(reconstructed_objects,
                                                       with_muon)

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:
        SMOG2_prefilters, SMOG2_lines = [], []

        lowMult_5 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            name="LowMult_5",
            minTracks=1,
            maxTracks=5)
        with line_maker.bind(prefilter=prefilters + [lowMult_5]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1GECPassThrough_LowMult5"))
            ]

        bx_BE = make_bxtype("BX_BeamEmpty", bx_type=1)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE]):
            SMOG2_lines += [
                line_maker(make_passthrough_line(name="Hlt1_BESMOG2_NoBias"))
            ]

        lowMult_10 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            name="LowMult_10",
            minTracks=1,
            maxTracks=10)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE, lowMult_10]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1_BESMOG2_LowMult10"))
            ]

        if EnableGEC:
            SMOG2_prefilters += gec

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
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

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1Passthrough_PV_in_SMOG2"))
            ]

            SMOG2_lines += default_smog2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["long_tracks"],
                reconstructed_objects["long_track_particles"],
                reconstructed_objects["secondary_vertices"], with_muon)

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections = make_gather_selections(lines=line_algorithms)
    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            make_global_decision(lines=line_algorithms),
            make_routingbits_writer(lines=line_algorithms),
            *make_sel_report_writer(
                lines=line_algorithms,
                long_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"])
            ["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if with_lumi:
        lumi_with_prefilter = CompositeNode(
            "LumiWithPrefilter",
            odin_err_filter + [
                lumi_reconstruction(
                    gather_selections=gather_selections,
                    lines=line_algorithms,
                    lumiline_name=lumiline_name,
                    with_muon=with_muon)
            ],
            NodeLogic.LAZY_AND,
            force_order=True)

        hlt1_node = CompositeNode(
            "AllenWithLumi", [hlt1_node, lumi_with_prefilter],
            NodeLogic.NONLAZY_AND,
            force_order=False)

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
        validation_node = validator_node(reconstructed_objects,
                                         line_algorithms, matching, with_ut,
                                         with_muon)
        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)
        return node
