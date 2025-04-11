###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter, filter_tracks_for_material_interactions, make_velo_tracks_ACsplit
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks, create_reduced_ut_container, make_dummy_ut_hits
from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.downstream_reconstruction import make_downstream, fit_downstream_secondary_vertices
from AllenConf.muon_reconstruction import decode_muon, chi2muon, is_muon, fake_muon_id, make_muon_stubs, muonid_nn
from AllenConf.calo_reconstruction import decode_calo, make_track_matching, make_ecal_clusters, make_electronid_nn
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.secondary_vertex_reconstruction import (
    make_kalman_velo_only, make_basic_particles, fit_secondary_vertices,
    make_sv_track_pairs, make_sv_pairs, make_generic_sv_pairs,
    make_three_body_svs)
from AllenConf.jet_reconstruction import make_cone_jets
from AllenConf.validators import (
    velo_validation, veloUT_validation, seeding_validation,
    seeding_xz_validation, long_validation, muon_validation, pv_validation,
    kalman_validation, selreport_validation, data_quality_validation_long,
    data_quality_validation_occupancy, data_quality_validation_pv,
    data_quality_validation_velo, downstream_validation)
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.persistency import make_gather_selections, make_sel_report_writer
from AllenConf.filters import make_gec
from AllenConf.best_track_creator import best_track_creator
from AllenConf.enum_types import TrackingType
from AllenConf.secondary_vertex_reconstruction import make_kalman_long


def hlt1_reconstruction(algorithm_name='',
                        tracking_type=TrackingType.FORWARD,
                        with_calo=True,
                        with_ut=True,
                        with_muon=True,
                        velo_open=False,
                        enableDownstream=False,
                        with_rich=False,
                        with_AC_split=False,
                        with_fullKF=False,
                        track_max_chi2ndof=10.0):
    decoded_velo = decode_velo()
    decoded_scifi = decode_scifi()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_states = run_velo_kalman_filter(velo_tracks)
    material_interaction_tracks = filter_tracks_for_material_interactions(
        velo_tracks,
        velo_states,
        beam_r_distance=18.0 if velo_open else 3.5,
        close_doca=0.3)
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
        long_tracks = best_track_creator(
            with_ut,
            tracking_type=tracking_type,
            algorithm_name=algorithm_name)

        if with_ut and enableDownstream:
            # Downstream tracking
            downstream_tracks = make_downstream(
                decoded_ut=long_tracks["ut_hits"],
                scifi_seeds=long_tracks["seeding_tracks"],
                velo_scifi_matches=long_tracks['matched_tracks'],
                pvs=pvs,
                dev_used_ut_hits_offsets=long_tracks[
                    "dev_used_ut_hits_offsets"])
            output.update({"downstream_tracks": downstream_tracks})

        output.update({
            "seeding_tracks": long_tracks["seeding_tracks"],
            "forward_tracks": long_tracks["forward_tracks"]
        })
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
            ut_hits=decode_ut() if with_ut else None,
            matching_consolidate_tracks_name=algorithm_name +
            'matching_consolidate_tracks_matching')
        output.update({"seeding_tracks": seed_tracks})
        if with_ut and enableDownstream:
            decoded_ut = decode_ut()
            downstream_tracks = make_downstream(
                decoded_ut=decoded_ut,
                scifi_seeds=seed_tracks,
                velo_scifi_matches=long_tracks,
                pvs=pvs,
                dev_used_ut_hits_offsets=long_tracks[
                    'dev_used_ut_hits_offsets'])
            output.update({"downstream_tracks": downstream_tracks})

    elif tracking_type == TrackingType.FORWARD:
        if with_ut:
            ut_hits = decode_ut()
            ut_tracks = make_ut_tracks(ut_hits, velo_tracks)
            input_tracks = ut_tracks
            output.update({"ut_tracks": input_tracks})
        else:
            ut_hits = make_dummy_ut_hits()
            input_tracks = velo_tracks
        decoded_scifi = decode_scifi()
        long_tracks = make_forward_tracks(
            decoded_scifi,
            input_tracks,
            ut_hits,
            velo_tracks["dev_accepted_velo_tracks"],
            with_ut=with_ut,
            scifi_consolidate_tracks_name=algorithm_name +
            'scifi_consolidate_tracks_forward')
    else:
        raise Exception("Tracking type not supported")
    if with_muon:
        decoded_muon = decode_muon()
        muonID = is_muon(
            decoded_muon, long_tracks, is_muon_name=algorithm_name + 'is_muon')
        # Replace long tracks with those containing muon hits.
        long_tracks = muonID["long_tracks"]
        # chi2Corr = chi2muon(long_tracks, muonID)
        muonid_extra = muonid_nn(long_tracks, muonID, decoded_muon)
        muonID.update(muonid_extra)
    else:
        muonID = fake_muon_id(host_number_of_tracks=long_tracks[
            'host_number_of_reconstructed_scifi_tracks'])

    output.update({
        "long_tracks": long_tracks,
        "muonID": muonID,
    })

    if with_fullKF:
        kalman_long_tracks = make_kalman_long(long_tracks, pvs, muonID)
        KF_long_track = kalman_long_tracks
        output.update({"kalman_long_track": kalman_long_tracks})
    else:
        kalman_velo_only = make_kalman_velo_only(long_tracks, pvs, muonID)
        output.update({"kalman_velo_only": kalman_velo_only})
        KF_long_track = kalman_velo_only

    if with_calo:
        decoded_calo = decode_calo()

        calo_matching_objects = make_track_matching(
            decoded_calo, velo_tracks, velo_states, long_tracks, KF_long_track)
        electronid_nn = make_electronid_nn(long_tracks, calo_matching_objects)

        ecal_clusters = make_ecal_clusters(
            decoded_calo,
            calo_matching_objects=calo_matching_objects,
            calo_find_clusters_name=algorithm_name + 'calo_find_clusters')

        long_track_particles = make_basic_particles(
            KF_long_track,
            muonID,
            make_long_track_particles_name=algorithm_name +
            'make_long_track_particles',
            # is_electron_result=calo_matching_objects)
            is_electron_result=electronid_nn)
        jets = make_cone_jets(
            long_tracks, long_track_particles, ecal_clusters, n_max_jets=4)
        output.update({
            "decoded_calo": decoded_calo,
            "calo_matching_objects": calo_matching_objects,
            "ecal_clusters": ecal_clusters,
            "electronid_nn": electronid_nn,
            "jets": jets
        })
    else:
        long_track_particles = make_basic_particles(
            KF_long_track,
            muonID,
            make_long_track_particles_name=algorithm_name +
            'make_long_track_particles_no_calo')

    # Dihadron SVs are constructed from displaced tracks and have no requirement
    # on lepton ID.
    dihadrons = fit_secondary_vertices(
        long_tracks,
        pvs,
        KF_long_track,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_dihadron_secondary_vertices',
        track_min_ipchi2_both=-999.,
        track_min_ipchi2_either=-999.,
        track_min_ip_both=0.06,
        track_min_ip_either=0.06,
        track_max_chi2ndof=track_max_chi2ndof)

    # Dihadron SVs constructed with IP > 0 (no IP cut)
    dihadrons_noipcut = fit_secondary_vertices(
        long_tracks,
        pvs,
        KF_long_track,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_dihadrons_noipcut_secondary_vertices',
        track_min_ipchi2_both=4.,
        track_min_ipchi2_either=4.,
        track_min_ip_both=0.,
        track_min_ip_either=0.,
        require_same_pv=True,
        require_os_pair=True,
        track_min_pt_both=450.,
        track_min_pt_either=450.,
        min_sum_pt=900.)

    # Make prompt SVs with a relatively tight pT cut.
    prompt_dihadrons = fit_secondary_vertices(
        long_tracks,
        pvs,
        KF_long_track,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_prompt_dihadron_secondary_vertices',
        track_min_ipchi2_both=-999.,
        track_min_ipchi2_either=-999.,
        track_min_ip_both=-999.,
        track_min_ip_either=-999.,
        track_max_chi2ndof=track_max_chi2ndof,
        require_same_pv=True,
        require_os_pair=True,
        max_doca=0.1,
        track_min_pt_both=700.,
        track_min_pt_either=1100.)

    # Dileptons SV reconstruction should be independent of PV reconstruction to
    # avoid lifetime biases.
    dileptons = fit_secondary_vertices(
        long_tracks,
        pvs,
        KF_long_track,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_dilepton_secondary_vertices',
        track_min_ipchi2_both=-999.,
        track_min_ipchi2_either=-999.,
        track_min_ip_both=-999.,
        track_min_ip_either=-999.,
        track_max_chi2ndof=track_max_chi2ndof,
        require_same_pv=False,
        require_lepton=True)

    # V0s are highly displaced and have opposite-sign charged tracks.
    v0s = fit_secondary_vertices(
        long_tracks,
        pvs,
        KF_long_track,
        long_track_particles,
        fit_secondary_vertices_name=algorithm_name +
        'fit_v0_secondary_vertices',
        track_min_ipchi2_both=12.,
        track_min_ipchi2_either=32.,
        track_min_ip_both=0.08,
        track_min_ip_either=0.2,
        track_min_pt_both=80.,
        track_min_pt_either=450.,
        track_max_chi2ndof=track_max_chi2ndof,
        max_doca=0.5,
        require_os_pair=True)

    v0_track_pairs = make_sv_track_pairs(v0s, long_track_particles, pvs)
    lambda_track_from_c = make_sv_track_pairs(
        v0s,
        long_track_particles,
        pvs,
        min_track_ipchi2=12,
        min_track_ip=0.08,
        min_track_pt=700,
        sv_track_doca_max=0.1,
        sv_bpvdira_min=0.99999,
        sv_bpvvdrho_min=2,
        sv_bpvvdz_min=12,
        sv_bpvip_min=0.0)

    v0_twotrack_pairs = make_sv_track_pairs(
        v0_track_pairs,
        long_track_particles,
        pvs,
        min_track_ip=0.06,
        min_track_ipchi2=6,
        min_track_pt=280,
        sv_bpvip_min=0.012,
        sv_bpvvdz_min=12,
        sv_bpvvdrho_min=0.7,
        sv_bpvdira_min=0.9997,
        sv_vz_min=-200,
        require_neutral_sv=False)

    # D* -> D0(-> K pi) pi
    dstars = make_sv_track_pairs(
        dihadrons,
        long_track_particles,
        pvs,
        min_track_ipchi2=0.,
        min_track_ip=0.,
        max_track_ipchi2=4,
        min_track_pt=150.,
        sv_track_doca_max=0.2,
        sv_vz_min=-200,
        sv_vz_max=650,
        sv_bpvip_min=0.,
        sv_bpvvdz_min=0.,
        sv_bpvdira_min=0.9997,
        sv_bpvvdrho_min=0.)

    three_body_svs = make_three_body_svs(dihadrons, long_track_particles, pvs)

    # Tau -> phi(-> KK) + third track
    phi_plus_track = make_sv_track_pairs(
        dihadrons_noipcut,
        long_track_particles,
        pvs,
        min_track_ipchi2=4.,
        min_track_ip=0.,
        min_track_pt=300.,
        sv_track_doca_max=0.2,
        sv_vz_min=-200,
        sv_vz_max=650,
        sv_bpvip_min=0.,
        sv_bpvvdz_min=0.,
        sv_bpvvdrho_min=0.,
        sv_bpvdira_min=0.9986)

    v0_pairs = make_sv_pairs(v0s)

    v0_hh_pairs = make_generic_sv_pairs(
        v0s,
        dihadrons,
        maxVertexChi2=10.,
        minMassV1=450.,
        maxMassV1=550.,
        minPtV1=900.,
        minCosDiraV1=0.9999,
        minEtaV1=2,
        maxEtaV1=5,
        minTrackPtV1=250.,
        minTrackPV1=2500.,
        minTrackIPChi2V1=-999.,
        minTrackIPV1=0.25,
        minMassV2=250.,
        maxMassV2=1700.,
        minPtV2=750.,
        minCosDiraV2=0.999,
        minEtaV2=2,
        maxEtaV2=5,
        minTrackPtV2=250.,
        minTrackPV2=2500.,
        minTrackIPChi2V2=-999.,
        minTrackIPV2=0.06)

    output.update({
        "long_track_particles": long_track_particles,
        "dihadron_secondary_vertices": dihadrons,
        "prompt_dihadron_secondary_vertices": prompt_dihadrons,
        "dilepton_secondary_vertices": dileptons,
        "v0_secondary_vertices": v0s,
        "lambda_track_from_c": lambda_track_from_c,
        "v0_sv_twotrack_pairs": v0_twotrack_pairs,
        "dstars": dstars,
        "v0_pairs": v0_pairs,
        "v0_hh_pairs": v0_hh_pairs,
        "three_body_svs": three_body_svs,
        "phi_plus_track": phi_plus_track,
        "dihadrons_noipcut": dihadrons_noipcut,
    })

    if 'downstream_tracks' in output:
        v0s_dd = fit_downstream_secondary_vertices(
            output['downstream_tracks'], pvs, dihadron=True)
        downstream_combined_hadronic_and_leptonic_secondary_vertices = fit_downstream_secondary_vertices(
            output['downstream_tracks'],
            pvs,
            dihadron=False,
            hadronic_and_leptonic_combined=True)
        downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices = fit_downstream_secondary_vertices(
            output['downstream_tracks'],
            pvs,
            dihadron=False,
            hadronic_and_leptonic_combined=True,
            same_sign_reco=True)
        v0dd_pairs = make_generic_sv_pairs(
            v0s_dd,
            v0s_dd,
            maxVertexChi2=20.,
            minMassV1=350.,
            maxMassV1=650.,
            minPtV1=750.,
            minCosDiraV1=0.0,
            minEtaV1=2,
            maxEtaV1=5,
            minTrackPtV1=300.,
            minTrackPV1=3000.,
            minTrackIPChi2V1=-999.,
            minTrackIPV1=80,
            minMassV2=350.,
            maxMassV2=650.,
            minPtV2=750.,
            minCosDiraV2=0.0,
            minEtaV2=2,
            maxEtaV2=5,
            minTrackPtV2=300.,
            minTrackPV2=3000.,
            minTrackIPChi2V2=-999.,
            minTrackIPV2=80)
        v0dd_hh_pairs = make_generic_sv_pairs(
            v0s_dd,
            dihadrons,
            maxVertexChi2=10.,
            minMassV1=410.,
            maxMassV1=530.,
            minPtV1=1000.,
            minCosDiraV1=0.999,
            minEtaV1=2,
            maxEtaV1=5,
            minTrackPtV1=300.,
            minTrackPV1=3000.,
            minTrackIPChi2V1=-999.,
            minTrackIPV1=0.25,
            minMassV2=250.,
            maxMassV2=1700.,
            minPtV2=750.,
            minCosDiraV2=0.999,
            minEtaV2=2,
            maxEtaV2=5,
            minTrackPtV2=250.,
            minTrackPV2=2500.,
            minTrackIPChi2V2=-999.,
            minTrackIPV2=0.06)
        output.update({
            'downstream_secondary_vertices':
            v0s_dd,
            'downstream_sv_pairs':
            v0dd_pairs,
            "downstream_combined_hadronic_and_leptonic_secondary_vertices":
            downstream_combined_hadronic_and_leptonic_secondary_vertices,
            "downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices":
            downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices,
            'v0dd_hh_pairs':
            v0dd_hh_pairs
        })

    if with_rich:
        from AllenConf.rich_reconstruction import decode_rich
        output.update({"decoded_rich": decode_rich()})

    if with_AC_split:
        velo_tracks_A_side, velo_tracks_C_side = make_velo_tracks_ACsplit(
            decoded_velo)
        velo_states_A_side = run_velo_kalman_filter(
            velo_tracks_A_side, name="_A_side")
        velo_states_C_side = run_velo_kalman_filter(
            velo_tracks_C_side, name="_C_side")
        pvs_A_side = make_pvs(velo_tracks_A_side, pv_name="_A_side")
        pvs_C_side = make_pvs(velo_tracks_C_side, pv_name="_C_side")
        output.update({
            "velo_tracks_A_side": velo_tracks_A_side,
            "velo_tracks_C_side": velo_tracks_C_side,
            "velo_states_A_side": velo_states_A_side,
            "velo_states_C_side": velo_states_C_side,
            "pvs_A_side": pvs_A_side,
            "pvs_C_side": pvs_C_side,
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


def make_dq_node(reconstructed_matching,
                 reconstructed_forward,
                 methods=["forward", "matching", "occupancy", "pv", "velo"],
                 prefilters=[]):
    # N.B. if more 'methods' are added to the ODQV later, make sure to update Allen/Dumpers/BinaryDumpers/tests/qmtest/lhcb_ODQV.qmt line 35

    nodes = [
        data_quality_node(
            reconstructed_forward if method == "forward" else
            reconstructed_matching, method, prefilters) for method in methods
    ]

    return CompositeNode(
        "AllenWithDataQuality",
        nodes,
        NodeLogic.NONLAZY_AND,
        force_order=False)


def data_quality_node(reconstructed_objects=None, method="", prefilters=[]):

    validators = []
    if method in ["forward", "matching"]:
        validators = [
            CompositeNode(
                f"data_quality_validation_{method}",
                prefilters + [
                    data_quality_validation_long(
                        reconstructed_objects["long_tracks"],
                        reconstructed_objects["long_track_particles"],
                        f"data_quality_validation_{method}")
                ],
                NodeLogic.LAZY_AND,
                force_order=True)
        ]
    elif method == "occupancy":
        validators = [
            CompositeNode(
                f"data_quality_validation_{method}",
                prefilters + [
                    data_quality_validation_occupancy(
                        f"data_quality_validation_{method}")
                ],
                NodeLogic.LAZY_AND,
                force_order=True)
        ]
    elif method == "pv":
        validators = [
            CompositeNode(
                f"data_quality_validation_{method}",
                prefilters + [
                    data_quality_validation_pv(
                        reconstructed_objects["long_tracks"],
                        f"data_quality_validation_{method}")
                ],
                NodeLogic.LAZY_AND,
                force_order=True)
        ]
    elif method == "velo":
        validators = [
            CompositeNode(
                f"data_quality_validation_{method}",
                prefilters + [
                    data_quality_validation_velo(
                        reconstructed_objects["long_tracks"],
                        f"data_quality_validation_{method}")
                ],
                NodeLogic.LAZY_AND,
                force_order=True)
        ]
    else:
        print(
            f"WARNING : validator with method {method} is not implimented. See file {__file__}"
        )
    return CompositeNode(
        f"DQ_Validators_{method}",
        validators,
        NodeLogic.NONLAZY_AND,
        force_order=False)


def validator_node(reconstructed_objects,
                   line_algorithms,
                   matching,
                   with_ut,
                   with_muon,
                   with_AC_split,
                   with_fullKF,
                   prefilters=[]):

    validators = [velo_validation(reconstructed_objects["velo_tracks"])]

    if matching:
        validators += [
            seeding_validation(reconstructed_objects["seeding_tracks"])
        ]
        validators += [seeding_xz_validation()]
    elif not matching and with_ut:
        validators += [veloUT_validation(reconstructed_objects["ut_tracks"])]

    if 'downstream_tracks' in reconstructed_objects:
        validators += [
            downstream_validation(reconstructed_objects["downstream_tracks"])
        ]

    if "forward_tracks" in reconstructed_objects:
        validators += [
            long_validation(
                reconstructed_objects["forward_tracks"],
                name="forward_validator")
        ]
    validators += [long_validation(reconstructed_objects["long_tracks"])]

    if with_muon:
        validators += [muon_validation(reconstructed_objects["muonID"])]

    kf_var = "kalman_long_track" if with_fullKF else "kalman_velo_only"
    validators += [
        pv_validation(reconstructed_objects["pvs"]),
        kalman_validation(reconstructed_objects[kf_var]),
        selreport_validation(
            make_sel_report_writer(lines=line_algorithms),
            make_gather_selections(lines=line_algorithms))
    ]

    if with_AC_split:
        validators += [
            make_composite_node_with_gec(
                "velo_validation_A_side",
                velo_validation(
                    reconstructed_objects["velo_tracks_A_side"],
                    name="velo_validator_A_side"),
                with_scifi=True,
                with_ut=with_ut)
        ]
        validators += [
            make_composite_node_with_gec(
                "velo_validation_C_side",
                velo_validation(
                    reconstructed_objects["velo_tracks_C_side"],
                    name="velo_validator_C_side"),
                with_scifi=True,
                with_ut=with_ut)
        ]
        validators += [
            make_composite_node_with_gec(
                "pv_validation_A_side",
                pv_validation(
                    reconstructed_objects["pvs_A_side"],
                    name="pv_validator_A_side"),
                with_scifi=True,
                with_ut=with_ut)
        ]
        validators += [
            make_composite_node_with_gec(
                "pv_validation_C_side",
                pv_validation(
                    reconstructed_objects["pvs_C_side"],
                    name="pv_validator_C_side"),
                with_scifi=True,
                with_ut=with_ut)
        ]

    return CompositeNode(
        "Validators",
        prefilters + validators,
        NodeLogic.NONLAZY_AND,
        force_order=True)
