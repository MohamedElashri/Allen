###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.algorithms import *
from definitions.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from definitions.ut_reconstruction import decode_ut, make_ut_tracks
from definitions.scifi_reconstruction import decode_scifi, make_forward_tracks
from definitions.muon_reconstruction import decode_muon, is_muon
from definitions.primary_vertex_reconstruction import make_pvs
from definitions.secondary_vertex_reconstruction import make_kalman_velo_only, fit_secondary_vertices
from definitions.validators import (
    velo_validation, veloUT_validation, forward_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation)
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.persistency import make_gather_selections
from definitions.utils import gec


def hlt1_reconstruction():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    pvs = make_pvs(velo_tracks)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    forward_tracks = make_forward_tracks(decoded_scifi, ut_tracks)
    decoded_muon = decode_muon()
    muonID = is_muon(decoded_muon, forward_tracks)
    kalman_velo_only = make_kalman_velo_only(forward_tracks, pvs, muonID)
    secondary_vertices = fit_secondary_vertices(forward_tracks, pvs,
                                                kalman_velo_only)

    return {
        "velo_tracks": velo_tracks,
        "pvs": pvs,
        "ut_tracks": ut_tracks,
        "forward_tracks": forward_tracks,
        "muonID": muonID,
        "kalman_velo_only": kalman_velo_only,
        "secondary_vertices": secondary_vertices
    }


def make_composite_node_with_gec(alg_name, alg, gec_name="gec"):
    return CompositeNode(
        alg_name,
        [gec(), alg],
        NodeLogic.LAZY_AND,
        forceOrder=True)


def validator_node(reconstructed_objects, line_algorithms):
    return CompositeNode(
        "Validators", [
            make_composite_node_with_gec(
                "velo_validation",
                velo_validation(reconstructed_objects["velo_tracks"])),
            make_composite_node_with_gec(
                "veloUT_validation",
                veloUT_validation(reconstructed_objects["ut_tracks"])),
            make_composite_node_with_gec(
                "forward_validation",
                forward_validation(reconstructed_objects["forward_tracks"])),
            make_composite_node_with_gec(
                "muon_validation",
                muon_validation(reconstructed_objects["muonID"])),
            make_composite_node_with_gec(
                "pv_validation", pv_validation(reconstructed_objects["pvs"])),
            make_composite_node_with_gec(
                "kalman_validation",
                kalman_validation(reconstructed_objects["kalman_velo_only"])),
            rate_validation(
                    make_gather_selections(lines=line_algorithms.values())),
        ],
        NodeLogic.NONLAZY_AND,
        forceOrder=False)
