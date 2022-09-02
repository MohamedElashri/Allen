###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.muon_reconstruction import decode_muon, is_muon, fake_muon_id
from AllenConf.calo_reconstruction import decode_calo, make_track_matching, make_ecal_clusters
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.secondary_vertex_reconstruction import make_kalman_velo_only, make_basic_particles, fit_secondary_vertices
from AllenConf.validators import (
    velo_validation, veloUT_validation, seeding_validation, long_validation,
    muon_validation, pv_validation, kalman_validation, selreport_validation)
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.persistency import make_gather_selections, make_sel_report_writer
from AllenConf.utils import make_gec


def hlt1_reconstruction(matching=False,
                        with_calo=True,
                        with_ut=True,
                        with_muon=True):
    decoded_velo = decode_velo()
    decoded_scifi = decode_scifi()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_states = run_velo_kalman_filter(velo_tracks)
    pvs = make_pvs(velo_tracks)

    output = {
        "velo_tracks": velo_tracks,
        "velo_states": velo_states,
        "pvs": pvs
    }

    if matching:
        decoded_scifi = decode_scifi()
        seed_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
        seed_tracks = make_seeding_tracks(decoded_scifi, seed_xz_tracks)
        long_tracks = make_velo_scifi_matches(velo_tracks, velo_states,
                                              seed_tracks)
        output.update({"seeding_tracks": seed_tracks})
    else:
        if with_ut:
            decoded_ut = decode_ut()
            ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
            input_tracks = ut_tracks
            output.update({"ut_tracks": input_tracks})

        else:
            input_tracks = velo_tracks
        decoded_scifi = decode_scifi()
        long_tracks = make_forward_tracks(
            decoded_scifi, input_tracks, with_ut=with_ut)

    if with_muon:
        decoded_muon = decode_muon()
        muonID = is_muon(decoded_muon, long_tracks)
    else:
        muonID = fake_muon_id(long_tracks)
    kalman_velo_only = make_kalman_velo_only(long_tracks, pvs, muonID)

    output.update({
        "long_tracks": long_tracks,
        "muonID": muonID,
        "kalman_velo_only": kalman_velo_only
    })

    if with_calo:
        decoded_calo = decode_calo()
        ecal_clusters = make_ecal_clusters(decoded_calo)

        calo_matching_objects = make_track_matching(decoded_calo, velo_tracks,
                                                    velo_states, long_tracks,
                                                    kalman_velo_only)
        long_track_particles = make_basic_particles(kalman_velo_only, muonID,
                                                    calo_matching_objects)
        output.update({
            "decoded_calo": decoded_calo,
            "calo_matching_objects": calo_matching_objects,
            "ecal_clusters": ecal_clusters
        })
    else:
        long_track_particles = make_basic_particles(kalman_velo_only, muonID)

    secondary_vertices = fit_secondary_vertices(
        long_tracks, pvs, kalman_velo_only, long_track_particles)

    output.update({
        "long_track_particles": long_track_particles,
        "secondary_vertices": secondary_vertices
    })

    return output


def make_composite_node_with_gec(alg_name,
                                 alg,
                                 with_scifi,
                                 with_ut,
                                 gec_name="gec"):
    return CompositeNode(
        alg_name, [make_gec(count_scifi=with_scifi, count_ut=with_ut), alg],
        NodeLogic.LAZY_AND,
        force_order=True)


def validator_node(reconstructed_objects, line_algorithms, matching, with_ut,
                   with_muon):

    validators = [
        make_composite_node_with_gec(
            "velo_validation",
            velo_validation(reconstructed_objects["velo_tracks"]),
            with_scifi=True,
            with_ut=with_ut)
    ]

    if matching:
        validators += [
            make_composite_node_with_gec(
                "seeding_validation",
                seeding_validation(reconstructed_objects["seeding_tracks"]),
                with_scifi=True,
                with_ut=with_ut)
        ]
    elif not matching and with_ut:
        validators += [
            make_composite_node_with_gec(
                "veloUT_validation",
                veloUT_validation(reconstructed_objects["ut_tracks"]),
                with_scifi=True,
                with_ut=with_ut)
        ]

    validators += [
        make_composite_node_with_gec(
            "long_validation",
            long_validation(reconstructed_objects["long_tracks"]),
            with_scifi=True,
            with_ut=with_ut)
    ]

    if with_muon:
        validators += make_composite_node_with_gec(
            "muon_validation",
            muon_validation(reconstructed_objects["muonID"]),
            with_scifi=True,
            with_ut=with_ut),

    validators += [
        make_composite_node_with_gec(
            "pv_validation",
            pv_validation(reconstructed_objects["pvs"]),
            with_scifi=True,
            with_ut=with_ut),
        make_composite_node_with_gec(
            "kalman_validation",
            kalman_validation(reconstructed_objects["kalman_velo_only"]),
            with_scifi=True,
            with_ut=with_ut),
        selreport_validation(
            make_sel_report_writer(
                lines=line_algorithms,
                long_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"]
            ), make_gather_selections(lines=line_algorithms))
    ]

    return CompositeNode(
        "Validators", validators, NodeLogic.NONLAZY_AND, force_order=False)
