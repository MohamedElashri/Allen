###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks
from AllenConf.muon_reconstruction import decode_muon, is_muon
from AllenConf.calo_reconstruction import decode_calo, make_track_matching, make_ecal_clusters
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.secondary_vertex_reconstruction import make_kalman_velo_only, make_basic_particles, fit_secondary_vertices
from AllenConf.validators import (
    velo_validation, veloUT_validation, forward_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation, selreport_validation)
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.persistency import make_gather_selections, make_sel_report_writer
from AllenConf.utils import gec


def hlt1_reconstruction(add_electron_id=False):
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_states = run_velo_kalman_filter(velo_tracks)
    pvs = make_pvs(velo_tracks)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    forward_tracks = make_forward_tracks(decoded_scifi, ut_tracks)
    decoded_muon = decode_muon()
    muonID = is_muon(decoded_muon, forward_tracks)
    kalman_velo_only = make_kalman_velo_only(forward_tracks, pvs, muonID)
    decoded_calo = decode_calo()
    ecal_clusters = make_ecal_clusters(decoded_calo)

    calo_matching_objects = make_track_matching(
        decoded_calo, velo_tracks, velo_states, ut_tracks, forward_tracks,
        kalman_velo_only)

    if add_electron_id:
        long_track_particles = make_basic_particles(kalman_velo_only, muonID,
                                                    calo_matching_objects)
    else:
        long_track_particles = make_basic_particles(kalman_velo_only, muonID)
    secondary_vertices = fit_secondary_vertices(
        forward_tracks, pvs, kalman_velo_only, long_track_particles)
    return {
        "velo_tracks": velo_tracks,
        "pvs": pvs,
        "ut_tracks": ut_tracks,
        "forward_tracks": forward_tracks,
        "muonID": muonID,
        "kalman_velo_only": kalman_velo_only,
        "long_track_particles": long_track_particles,
        "secondary_vertices": secondary_vertices,
        "calo_matching_objects": calo_matching_objects,
        "ecal_clusters": ecal_clusters
    }


def make_composite_node_with_gec(alg_name, alg, gec_name="gec"):
    return CompositeNode(
        alg_name, [gec(), alg], NodeLogic.LAZY_AND, force_order=True)


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
            selreport_validation(
                make_sel_report_writer(
                    lines=line_algorithms,
                    forward_tracks=reconstructed_objects[
                        "long_track_particles"],
                    secondary_vertices=reconstructed_objects[
                        "secondary_vertices"]),
                make_gather_selections(lines=line_algorithms),
            )
        ],
        NodeLogic.NONLAZY_AND,
        force_order=False)
