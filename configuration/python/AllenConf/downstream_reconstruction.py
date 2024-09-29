###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

from AllenCore.algorithms import (
    downstream_find_hits_t, downstream_create_tracks_t,
    downstream_copy_hit_number_t, downstream_consolidate_t,
    downstream_make_particles_t, downstream_vertexing_t,
    downstream_busca_selector_t, downstream_make_secondary_vertices_t,
    downstream_composite_selector_t)
from AllenConf.utils import initialize_number_of_events, make_dummy
from AllenCore.generator import make_algorithm
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks, create_reduced_ut_container
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.muon_reconstruction import decode_muon, make_is_muon, fake_muon_id
from AllenConf.calo_reconstruction import decode_calo, make_ecal_clusters, make_is_electron
from AllenConf.secondary_vertex_reconstruction import make_lepton_id
from PyConf.tonic import configurable
from AllenConf.primary_vertex_reconstruction import make_pvs


@configurable
def make_downstream(decoded_ut,
                    scifi_seeds,
                    velo_scifi_matches,
                    pvs,
                    ghost_killer_threshold=0.5,
                    ttracks_probability_threshold=0.5,
                    require_four_ut_hits=True,
                    veto_used_scifi_seeds=True,
                    with_calo=True,
                    with_muon=True,
                    dev_used_ut_hits_offsets=None):

    number_of_events = initialize_number_of_events()

    # Filter used ut hits
    if dev_used_ut_hits_offsets is not None:
        ut_hits = create_reduced_ut_container(decoded_ut,
                                              dev_used_ut_hits_offsets)
    else:
        ut_hits = decoded_ut

    if veto_used_scifi_seeds:
        dev_matched_is_scifi_track_used = velo_scifi_matches[
            "dev_matched_is_scifi_track_used"]
    else:
        dev_matched_is_scifi_track_used = make_dummy().dev_bool_dummy_t

    downstream_find_hits = make_algorithm(
        downstream_find_hits_t,
        name='downstream_find_hits',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Matching
        dev_matched_is_scifi_track_used_t=dev_matched_is_scifi_track_used,
        # Scifi
        dev_offsets_seeding_t=scifi_seeds["dev_offsets_scifi_seeds"],
        dev_seeding_states_t=scifi_seeds["dev_seeding_states"],
        dev_seeding_qop_t=scifi_seeds["dev_seeding_qop"],
        dev_seeding_chi2Y_t=scifi_seeds["dev_seeding_chi2Y"],
        # UT
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        host_accumulated_number_of_ut_hits_t=ut_hits[
            "host_accumulated_number_of_ut_hits"],
        # Properties
        ttracks_probability_threshold=ttracks_probability_threshold,
        require_four_ut_hits=require_four_ut_hits,
        enable_constant_tolerance_window=False)

    downstream_create_tracks = make_algorithm(
        downstream_create_tracks_t,
        name='downstream_create_tracks',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # UT
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        # Find hits
        dev_findhits_num_selected_scifi_t=downstream_find_hits.
        dev_findhits_num_selected_scifi_t,
        dev_findhits_output_selected_scifi_offsets_t=downstream_find_hits.
        dev_findhits_output_selected_scifi_offsets_t,
        dev_findhits_output_t=downstream_find_hits.dev_findhits_output_t,
        dev_findhits_selected_scifi_tracks_t=downstream_find_hits.
        dev_findhits_selected_scifi_tracks_t,
        # Properties
        ghost_killer_threshold=ghost_killer_threshold)

    downstream_copy_track_hit_number = make_algorithm(
        downstream_copy_hit_number_t,
        name="downstream_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_downstream_tracks_t=downstream_create_tracks.
        host_number_of_downstream_tracks_t,
        dev_downstream_tracks_t=downstream_create_tracks.
        dev_downstream_tracks_t,
        dev_offsets_downstream_tracks_t=downstream_create_tracks.
        dev_offsets_downstream_tracks_t)

    downstream_consolidate_tracks = make_algorithm(
        downstream_consolidate_t,
        name="downstream_consolidate_tracks",
        # basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Host statistics
        host_number_of_hits_in_downstream_tracks_t=
        downstream_copy_track_hit_number.
        host_number_of_hits_in_downstream_tracks_t,
        host_number_of_downstream_tracks_t=downstream_create_tracks.
        host_number_of_downstream_tracks_t,
        dev_offsets_downstream_hit_numbers_t=downstream_copy_track_hit_number.
        dev_offsets_downstream_hit_numbers_t,
        dev_offsets_downstream_tracks_t=downstream_create_tracks.
        dev_offsets_downstream_tracks_t,
        dev_downstream_tracks_t=downstream_create_tracks.
        dev_downstream_tracks_t,
        # UT input
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        # Scifi input
        dev_scifi_tracks_view_t=scifi_seeds["dev_scifi_tracks_view"],
        dev_scifi_states_t=scifi_seeds["dev_seeding_states"])

    # Lepton ID
    if with_muon:
        muonID = make_is_muon(
            decoded_muon=decode_muon(),
            host_number_of_tracks=downstream_create_tracks.
            host_number_of_downstream_tracks_t,
            dev_multi_event_tracks_ptr=downstream_consolidate_tracks.
            dev_multi_event_downstream_tracks_view_ptr_t,
            dev_velo_states=downstream_consolidate_tracks.
            dev_downstream_track_states_view_t,
            dev_scifi_states=downstream_consolidate_tracks.
            dev_downstream_track_scifi_states_t,
            is_muon_name='is_muon_{hash}')
    else:
        muonID = fake_muon_id(host_number_of_tracks=downstream_create_tracks.
                              host_number_of_downstream_tracks_t)

    if with_calo:
        caloID = make_is_electron(
            decoded_calo=decode_calo(),
            host_number_of_tracks=downstream_create_tracks.
            host_number_of_downstream_tracks_t,
            dev_multi_event_tracks_ptr=downstream_consolidate_tracks.
            dev_multi_event_downstream_tracks_view_ptr_t,
            dev_velo_states=downstream_consolidate_tracks.
            dev_downstream_track_states_view_t,
            dev_scifi_states=downstream_consolidate_tracks.
            dev_downstream_track_scifi_states_t,
        )
        leptonID = make_lepton_id(
            host_number_of_tracks=downstream_create_tracks.
            host_number_of_downstream_tracks_t,
            dev_multi_event_tracks_ptr=downstream_consolidate_tracks.
            dev_multi_event_downstream_tracks_view_ptr_t,
            is_muon_result=muonID,
            is_electron_result=caloID,
        )
    else:
        leptonID = muonID["dev_lepton_id"]

    downstream_make_particles = make_algorithm(
        downstream_make_particles_t,
        name="downstream_make_particles",
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_downstream_tracks_t=downstream_create_tracks.
        host_number_of_downstream_tracks_t,
        # States
        dev_downstream_track_states_view_t=downstream_consolidate_tracks.
        dev_downstream_track_states_view_t,
        # Downstream consolidated tracks
        dev_offsets_downstream_tracks_t=downstream_create_tracks.
        dev_offsets_downstream_tracks_t,
        dev_multi_event_downstream_tracks_view_t=downstream_consolidate_tracks.
        dev_multi_event_downstream_tracks_view_t,
        # PVs
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        # Lepton ID
        dev_lepton_id_t=leptonID)

    output_map = {
        #
        # Forward previous outputs
        #
        "ut_hits":
        ut_hits,
        "decode_ut":
        decoded_ut,
        "scifi_seeds":
        scifi_seeds,
        "velo_scifi_matches":
        velo_scifi_matches,
        #
        # Algorithms, used for throughput tresting
        #
        "downstream_find_hits":
        downstream_find_hits,
        "downstream_create_tracks":
        downstream_create_tracks,
        "downstream_copy_track_hit_number":
        downstream_copy_track_hit_number,
        "downstream_consolidate_tracks":
        downstream_consolidate_tracks,
        "downstream_make_particles":
        downstream_make_particles,

        #
        # Downstream reconstruction output
        #
        "dev_downstream_tracks":
        downstream_create_tracks.dev_downstream_tracks_t,
        "dev_offsets_downstream_tracks":
        downstream_create_tracks.dev_offsets_downstream_tracks_t,
        "host_number_of_downstream_tracks":
        downstream_create_tracks.host_number_of_downstream_tracks_t,

        #
        # Downstream copy track hit number output
        #
        "dev_offsets_downstream_hit_numbers":
        downstream_copy_track_hit_number.dev_offsets_downstream_hit_numbers_t,

        #
        # Downstream ut tracks
        #
        "dev_downstream_track_states":
        downstream_consolidate_tracks.dev_downstream_track_states_t,
        "dev_downstream_track_hits":
        downstream_consolidate_tracks.dev_downstream_track_hits_t,
        "dev_downstream_track_qops":
        downstream_consolidate_tracks.dev_downstream_track_qops_t,
        "dev_downstream_track_ghost_probability":
        downstream_consolidate_tracks.dev_downstream_track_ghost_probability_t,
        "dev_downstream_track_scifi_idx":
        downstream_consolidate_tracks.dev_downstream_track_scifi_idx_t,
        "dev_downstream_hits_view":
        downstream_consolidate_tracks.dev_downstream_hits_view_t,
        "dev_downstream_ut_track_view":
        downstream_consolidate_tracks.dev_downstream_ut_track_view_t,
        "dev_downstream_ut_tracks_view":
        downstream_consolidate_tracks.dev_downstream_ut_tracks_view_t,
        "dev_multi_event_downstream_ut_tracks_view":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_ut_tracks_view_t,
        "dev_multi_event_downstream_ut_tracks_view_ptr":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_ut_tracks_view_ptr_t,

        #
        #  Downstream tracks
        #
        "dev_downstream_track_scifi_states":
        downstream_consolidate_tracks.dev_downstream_track_scifi_states_t,
        "dev_downstream_track_states_view":
        downstream_consolidate_tracks.dev_downstream_track_states_view_t,
        "dev_downstream_track_view":
        downstream_consolidate_tracks.dev_downstream_track_view_t,
        "dev_downstream_tracks_view":
        downstream_consolidate_tracks.dev_downstream_tracks_view_t,
        "dev_multi_event_downstream_tracks_view":
        downstream_consolidate_tracks.dev_multi_event_downstream_tracks_view_t,
        "dev_multi_event_downstream_tracks_view_ptr":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_tracks_view_ptr_t,
        #
        # Downstream track particles
        #
        "dev_downstream_track_particle_view":
        downstream_make_particles.dev_downstream_track_particle_view_t,
        "dev_downstream_track_particles_view":
        downstream_make_particles.dev_downstream_track_particles_view_t,
        "dev_multi_event_downstream_track_particles_view":
        downstream_make_particles.
        dev_multi_event_downstream_track_particles_view_t,
        "dev_multi_event_downstream_track_particles_view_ptr":
        downstream_make_particles.
        dev_multi_event_downstream_track_particles_view_ptr_t,
        "dev_downstream_particles_ip":
        downstream_make_particles.dev_downstream_particles_ip_t
    }

    return output_map


@configurable
def fit_downstream_secondary_vertices(
        downstream_tracks,
        pvs,
        track_min_pt_both=136.1,
        track_min_pt_either=277.1,
        track_min_ip_both=64.,
        track_min_ip_either=64.,
        sum_pt_min=471.8,
        doca_max=19.1,
        min_vtx_z=54.5,
        max_vtx_z=2484.6,
        min_quality=0.1,
        dihadron=True,
):
    number_of_events = initialize_number_of_events()

    downstream_hadron_vertexing = make_algorithm(
        downstream_vertexing_t,
        name='downstream_vertexing',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_tracks_t=downstream_tracks[
            'host_number_of_downstream_tracks'],
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # Properties
        track_min_pt_both=track_min_pt_both,
        track_min_pt_either=track_min_pt_either,
        track_min_ip_both=track_min_ip_both,
        track_min_ip_either=track_min_ip_either,
        sum_pt_min=sum_pt_min,
        doca_max=doca_max,
        min_vtx_z=min_vtx_z,
        max_vtx_z=max_vtx_z,
        min_quality=min_quality,
        dihadron=dihadron,
    )

    downstream_combined_vertexing = make_algorithm(
        downstream_vertexing_t,
        name='downstream_leptonic_vertexing',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_tracks_t=downstream_tracks[
            'host_number_of_downstream_tracks'],
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # Properties
        track_min_pt_both=track_min_pt_both,
        track_min_pt_either=track_min_pt_either,
        track_min_ip_both=track_min_ip_both,
        track_min_ip_either=track_min_ip_either,
        sum_pt_min=sum_pt_min,
        doca_max=doca_max,
        min_vtx_z=min_vtx_z,
        max_vtx_z=max_vtx_z,
        min_quality=min_quality,
        combined_container=True)

    downstream_same_sign_vertexing = make_algorithm(
        downstream_vertexing_t,
        name='downstream_same_sign_vertexing',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_tracks_t=downstream_tracks[
            'host_number_of_downstream_tracks'],
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # Properties
        track_min_pt_both=track_min_pt_both,
        track_min_pt_either=track_min_pt_either,
        track_min_ip_both=track_min_ip_both,
        track_min_ip_either=track_min_ip_either,
        sum_pt_min=sum_pt_min,
        doca_max=doca_max,
        min_vtx_z=min_vtx_z,
        max_vtx_z=max_vtx_z,
        min_quality=min_quality,
        combined_container=True,
        same_sign_reco=True)

    downstream_make_secondary_vertices = make_algorithm(
        downstream_make_secondary_vertices_t,
        name='downstream_make_secondary_vertices',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_secondary_vertices_t=
        downstream_hadron_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # PVs
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        # SVs
        dev_downstream_secondary_vertices_t=downstream_hadron_vertexing.
        dev_downstream_secondary_vertices_t,
        dev_offsets_downstream_secondary_vertices_t=downstream_hadron_vertexing
        .dev_offsets_downstream_secondary_vertices_t)

    downstream_make_combined_secondary_vertices = make_algorithm(
        downstream_make_secondary_vertices_t,
        name='downstream_make_combined_secondary_vertices',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_secondary_vertices_t=
        downstream_combined_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # PVs
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        # SVs
        dev_downstream_secondary_vertices_t=downstream_combined_vertexing.
        dev_downstream_secondary_vertices_t,
        dev_offsets_downstream_secondary_vertices_t=downstream_combined_vertexing
        .dev_offsets_downstream_secondary_vertices_t)

    downstream_make_same_sign_secondary_vertices = make_algorithm(
        downstream_make_secondary_vertices_t,
        name='downstream_make_same_sign_secondary_vertices',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Downstream tracks
        host_number_of_downstream_secondary_vertices_t=
        downstream_same_sign_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        dev_multi_event_downstream_track_particles_view_t=downstream_tracks[
            'dev_multi_event_downstream_track_particles_view'],
        # PVs
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        # SVs
        dev_downstream_secondary_vertices_t=downstream_same_sign_vertexing.
        dev_downstream_secondary_vertices_t,
        dev_offsets_downstream_secondary_vertices_t=
        downstream_same_sign_vertexing.
        dev_offsets_downstream_secondary_vertices_t)

    downstream_composite_selector = make_algorithm(
        downstream_composite_selector_t,
        name='downstream_composite_selector',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Size
        host_number_of_downstream_secondary_vertices_t=
        downstream_hadron_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        # Composite
        dev_multi_event_composites_view_t=downstream_make_secondary_vertices.
        dev_multi_event_composites_view_t,
    )

    downstream_busca_combined_selector = make_algorithm(
        downstream_busca_selector_t,
        name='downstream_busca_combined_selector',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Size
        host_number_of_downstream_secondary_vertices_t=
        downstream_combined_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        # Composite
        dev_multi_event_composites_view_t=
        downstream_make_combined_secondary_vertices.
        dev_multi_event_composites_view_t,
    )

    downstream_busca_same_sign_selector = make_algorithm(
        downstream_busca_selector_t,
        name='downstream_busca_same_sign_selector',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        # Size
        host_number_of_downstream_secondary_vertices_t=
        downstream_same_sign_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        # Composite
        dev_multi_event_composites_view_t=
        downstream_make_same_sign_secondary_vertices.
        dev_multi_event_composites_view_t,
    )

    return {
        #
        # Algorithms
        #
        "downstream_vertexing":
        downstream_hadron_vertexing,
        "downstream_make_secondary_vertices":
        downstream_make_secondary_vertices,
        "downstream_composite_selector":
        downstream_composite_selector,
        #
        # Standard outputs
        #
        "host_number_of_svs":
        downstream_hadron_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        "host_number_of_combined_svs":
        downstream_combined_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        "host_number_of_same_sign_svs":
        downstream_same_sign_vertexing.
        host_number_of_downstream_secondary_vertices_t,
        "dev_sv_offsets":
        downstream_hadron_vertexing.
        dev_offsets_downstream_secondary_vertices_t,
        "dev_two_track_particles":
        downstream_make_secondary_vertices.dev_two_track_composites_view_t,
        "dev_multi_event_composites":
        downstream_make_secondary_vertices.dev_multi_event_composites_view_t,
        "dev_multi_event_combined_composites":
        downstream_make_combined_secondary_vertices.
        dev_multi_event_composites_view_t,
        "dev_multi_event_same_sign_composites":
        downstream_make_same_sign_secondary_vertices.
        dev_multi_event_composites_view_t,
        "dev_multi_event_composites_ptr":
        downstream_make_secondary_vertices.dev_multi_event_composites_ptr_t,
        #
        # Extra
        #
        "dev_downstream_secondary_vertices_ip":
        downstream_make_secondary_vertices.
        dev_downstream_secondary_vertices_ip_t,
        #
        # Selection
        #
        "dev_downstream_mva_ks":
        downstream_composite_selector.dev_downstream_mva_ks_t,
        "dev_downstream_mva_l0":
        downstream_composite_selector.dev_downstream_mva_l0_t,
        "dev_downstream_mva_detached_ks":
        downstream_composite_selector.dev_downstream_mva_detached_ks_t,
        "dev_downstream_mva_detached_l0":
        downstream_composite_selector.dev_downstream_mva_detached_l0_t,
        "dev_downstream_mva_combined_busca":
        downstream_busca_combined_selector.dev_downstream_mva_busca_t,
        "dev_downstream_mva_same_sign_busca":
        downstream_busca_same_sign_selector.dev_downstream_mva_busca_t
    }


def make_downstream_objects():

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
    decoded_ut = decode_ut()
    # ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    matched_tracks = make_velo_scifi_matches(velo_tracks, velo_kalman_filter,
                                             seeding_tracks)
    pvs = make_pvs(velo_tracks=velo_tracks)
    downstream_tracks = make_downstream(
        decoded_ut,
        seeding_tracks,
        matched_tracks,
        # , ut_tracks=ut_tracks
        pvs=pvs)
    downstream_secondary_vertices = fit_downstream_secondary_vertices(
        downstream_tracks, pvs)

    return {
        "downstream_tracks": downstream_tracks,
        "downstream_secondary_vertices": downstream_secondary_vertices,
    }


def downstream_track_reconstruction(
        output_name="dev_downstream_track_particles_view"):

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
    decoded_ut = decode_ut()
    # ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    matched_tracks = make_velo_scifi_matches(velo_tracks, velo_kalman_filter,
                                             seeding_tracks)
    pvs = make_pvs(velo_tracks=velo_tracks)
    downstream_tracks = make_downstream(
        decoded_ut, seeding_tracks, matched_tracks, pvs=pvs)
    downstream_tracks.update(
        fit_downstream_secondary_vertices(downstream_tracks, pvs))

    return downstream_tracks[output_name]
