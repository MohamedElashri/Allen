###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter, filter_tracks_for_material_interactions
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.muon_reconstruction import decode_muon, is_muon, fake_muon_id, make_muon_stubs
from AllenConf.calo_reconstruction import decode_calo, make_track_matching, make_ecal_clusters
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.secondary_vertex_reconstruction import make_kalman_velo_only, make_basic_particles, fit_secondary_vertices, make_sv_pairs
from AllenConf.validators import (
    velo_validation, veloUT_validation, seeding_validation, long_validation,
    muon_validation, pv_validation, kalman_validation, selreport_validation)
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.persistency import make_gather_selections, make_sel_report_writer
from AllenConf.utils import make_gec
from AllenConf.best_track_creator import best_track_creator
from AllenConf.enum_types import TrackingType


def hlt1_reconstruction(algorithm_name='',
                        tracking_type=TrackingType.FORWARD,
                        with_calo=True,
                        with_ut=True,
                        with_muon=True,
                        velo_open=False):
    decoded_velo = decode_velo()
    decoded_scifi = decode_scifi()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_states = run_velo_kalman_filter(velo_tracks)
    material_interaction_tracks = filter_tracks_for_material_interactions(
        velo_tracks, velo_states, beam_r_distance=18.0, close_doca=0.5)
    pvs = make_pvs(velo_tracks, velo_open)
    muon_stubs = make_muon_stubs()

    output = {
        "velo_tracks": velo_tracks,
        "velo_states": velo_states,
        "material_interaction_tracks": material_interaction_tracks,
        "pvs": pvs,
        "muon_stubs": muon_stubs,
    }

    if algorithm_name != '':
        algorithm_name = algorithm_name + '_'

    if tracking_type in (TrackingType.FORWARD_THEN_MATCHING,
                         TrackingType.MATCHING_THEN_FORWARD):
        if with_ut:
            decoded_ut = decode_ut()
            ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
            input_tracks = ut_tracks
            output.update({"ut_tracks": input_tracks})
        long_tracks = best_track_creator(
            with_ut,
            tracking_type=tracking_type,
            algorithm_name=algorithm_name)
        output.update({"seeding_tracks": long_tracks["seeding_tracks"]})
    elif tracking_type == TrackingType.MATCHING:
        decoded_scifi = decode_scifi()
        seed_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
        seed_tracks = make_seeding_tracks(
            decoded_scifi,
            seed_xz_tracks,
            scifi_consolidate_seeds_name=algorithm_name +
            'scifi_consolidate_seeds_matching')
        long_tracks = make_velo_scifi_matches(
            velo_tracks,
            velo_states,
            seed_tracks,
            matching_consolidate_tracks_name=algorithm_name +
            'matching_consolidate_tracks_matching')
        output.update({"seeding_tracks": seed_tracks})
    elif tracking_type == TrackingType.FORWARD:
        if with_ut:
            decoded_ut = decode_ut()
            ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
            input_tracks = ut_tracks
            output.update({"ut_tracks": input_tracks})
        else:
            input_tracks = velo_tracks
        decoded_scifi = decode_scifi()
        long_tracks = make_forward_tracks(
            decoded_scifi,
            input_tracks,
            velo_tracks["dev_accepted_velo_tracks"],
            with_ut=with_ut,
            scifi_consolidate_tracks_name=algorithm_name +
            'scifi_consolidate_tracks_forward')
    else:
        raise Exception("Tracking type not supported")

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
        long_track_particles = make_basic_particles(
            kalman_velo_only,
            muonID,
            make_long_track_particles_name=algorithm_name +
            'make_long_track_particles',
            is_electron_result=calo_matching_objects)
        output.update({
            "decoded_calo": decoded_calo,
            "calo_matching_objects": calo_matching_objects,
            "ecal_clusters": ecal_clusters
        })
    else:
        long_track_particles = make_basic_particles(
            kalman_velo_only,
            muonID,
            make_long_track_particles_name=algorithm_name +
            'make_long_track_particles_no_calo')

    # Dihadron SVs are constructed from displaced tracks and have no requirement
    # on lepton ID.
    dihadrons = fit_secondary_vertices(
        long_tracks,
        pvs,
        kalman_velo_only,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_dihadron_secondary_vertices')

    # Dileptons SV reconstruction should be independent of PV reconstruction to
    # avoid lifetime biases.
    dileptons = fit_secondary_vertices(
        long_tracks,
        pvs,
        kalman_velo_only,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_dilepton_secondary_vertices',
        track_min_ipchi2_both=-999.,
        track_min_ipchi2_either=-999.,
        track_min_ip_both=-999.,
        track_min_ip_either=-999.,
        require_same_pv=False,
        require_lepton=True)

    # V0s are highly displaced and have opposite-sign charged tracks.
    v0s = fit_secondary_vertices(
        long_tracks,
        pvs,
        kalman_velo_only,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_v0_secondary_vertices',
        track_min_ipchi2_both=12.,
        track_min_ipchi2_either=32.,
        track_min_ip_both=0.08,
        track_min_ip_either=0.2,
        track_min_pt_both=80.,
        track_min_pt_either=450.,
        max_doca=0.5,
        require_os_pair=True)

    v0_pairs = make_sv_pairs(v0s)

    output.update({
        "long_track_particles": long_track_particles,
        "dihadron_secondary_vertices": dihadrons,
        "dilepton_secondary_vertices": dileptons,
        "v0_secondary_vertices": v0s,
        "v0_pairs": v0_pairs
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
            make_sel_report_writer(lines=line_algorithms),
            make_gather_selections(lines=line_algorithms))
    ]

    return CompositeNode(
        "Validators", validators, NodeLogic.NONLAZY_AND, force_order=False)
