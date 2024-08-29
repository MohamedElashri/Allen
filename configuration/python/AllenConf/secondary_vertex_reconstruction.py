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
from AllenCore.algorithms import (
    velo_pv_ip_t, kalman_velo_only_t, make_lepton_id_t,
    make_long_track_particles_t, filter_tracks_t, fit_secondary_vertices_t,
    empty_lepton_id_t, sv_combiner_t, filter_svs_t, filter_two_svs_t,
    generic_sv_combiner_t, calc_max_combos_t, filter_sv_track_t,
    combine_sv_track_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenCore.generator import make_algorithm


def make_kalman_velo_only(long_tracks,
                          pvs,
                          is_muon_result,
                          is_electron_result=None):
    number_of_events = initialize_number_of_events()
    velo_tracks = long_tracks["velo_tracks"]
    velo_states = run_velo_kalman_filter(velo_tracks)

    velo_pv_ip = make_algorithm(
        velo_pv_ip_t,
        name='velo_pv_ip_{hash}',
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_kalman_beamline_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
    )

    kalman_velo_only = make_algorithm(
        kalman_velo_only_t,
        name='kalman_velo_only_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        dev_is_muon_t=is_muon_result["dev_is_muon"],
    )

    return {
        "long_tracks": long_tracks,
        "pvs": pvs,
        "dev_velo_pv_ip": velo_pv_ip.dev_velo_pv_ip_t,
        "dev_kf_tracks": kalman_velo_only.dev_kf_tracks_t,
        "dev_kalman_pv_ip": kalman_velo_only.dev_kalman_pv_ip_t,
        "dev_kalman_pv_tables": kalman_velo_only.dev_kalman_pv_tables_t,
        "dev_kalman_fit_results": kalman_velo_only.dev_kalman_fit_results_t,
        "dev_kalman_states_view": kalman_velo_only.dev_kalman_states_view_t
    }


def make_lepton_id(host_number_of_tracks, dev_multi_event_tracks_ptr,
                   is_muon_result, is_electron_result):
    number_of_events = initialize_number_of_events()
    if is_electron_result is not None:
        make_lepton_id = make_algorithm(
            make_lepton_id_t,
            name='make_lepton_id_{hash}',
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            host_number_of_scifi_tracks_t=host_number_of_tracks,
            dev_tracks_view_t=dev_multi_event_tracks_ptr,
            dev_is_muon_t=is_muon_result["dev_is_muon"],
            dev_is_electron_t=is_electron_result["dev_track_isElectron"])
        lepton_id = make_lepton_id.dev_lepton_id_t
    else:
        lepton_id = is_muon_result["dev_lepton_id"]

    return lepton_id


def make_basic_particles(
        kalman_velo_only,
        is_muon_result,
        make_long_track_particles_name='make_long_track_particles',
        is_electron_result=None):
    number_of_events = initialize_number_of_events()
    long_tracks = kalman_velo_only["long_tracks"]
    pvs = kalman_velo_only["pvs"]

    lepton_id = make_lepton_id(
        host_number_of_tracks=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_multi_event_tracks_ptr=long_tracks[
            "dev_multi_event_long_tracks_ptr"],
        is_muon_result=is_muon_result,
        is_electron_result=is_electron_result,
    )

    make_long_track_particles = make_algorithm(
        make_long_track_particles_t,
        name=str(make_long_track_particles_name),
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_multi_event_long_tracks_t=long_tracks[
            "dev_multi_event_long_tracks_ptr"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_kalman_states_view_t=kalman_velo_only["dev_kalman_states_view"],
        dev_kalman_pv_tables_t=kalman_velo_only["dev_kalman_pv_tables"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_lepton_id_t=lepton_id)
    return {
        "dev_multi_event_basic_particles":
        make_long_track_particles.dev_multi_event_basic_particles_view_t,
        "dev_multi_event_container_basic_particles":
        make_long_track_particles.dev_multi_event_container_basic_particles_t
    }


def fit_secondary_vertices(
        long_tracks,
        pvs,
        kalman_velo_only,
        long_track_particles,
        fit_secondary_vertices_name='fit_secondary_vertices',
        # Filter properties.
        track_min_pt_both=200.,
        track_min_pt_either=200.,
        track_min_ipchi2_both=4.,
        track_min_ipchi2_either=4.,
        track_min_ip_both=0.06,
        track_min_ip_either=0.06,
        track_max_chi2ndof=10.0,
        max_doca=1.,
        min_sum_pt=400.,
        require_os_pair=False,
        require_same_pv=True,
        require_muon=False,
        require_electron=False,
        require_lepton=False,
        max_assoc_ipchi2=16.):

    number_of_events = initialize_number_of_events()

    filter_tracks = make_algorithm(
        filter_tracks_t,
        name='filter_tracks_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_long_track_particles_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        track_min_pt_both=track_min_pt_both,
        track_min_pt_either=track_min_pt_either,
        track_min_ipchi2_both=track_min_ipchi2_both,
        track_min_ipchi2_either=track_min_ipchi2_either,
        track_min_ip_both=track_min_ip_both,
        track_min_ip_either=track_min_ip_either,
        track_max_chi2ndof=track_max_chi2ndof,
        doca_max=max_doca,
        sum_pt_min=min_sum_pt,
        require_os_pair=require_os_pair,
        require_same_pv=require_same_pv,
        require_muon=require_muon,
        require_electron=require_electron,
        require_lepton=require_lepton,
        max_assoc_ipchi2=max_assoc_ipchi2)

    fit_secondary_vertices = make_algorithm(
        fit_secondary_vertices_t,
        name=str(fit_secondary_vertices_name),
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_svs_t=filter_tracks.host_number_of_svs_t,
        dev_long_track_particles_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        dev_svs_trk1_idx_t=filter_tracks.dev_svs_trk1_idx_t,
        dev_svs_trk2_idx_t=filter_tracks.dev_svs_trk2_idx_t,
        dev_sv_offsets_t=filter_tracks.dev_sv_offsets_t,
        dev_sv_poca_t=filter_tracks.dev_sv_poca_t)

    return {
        "dev_consolidated_svs":
        fit_secondary_vertices.dev_consolidated_svs_t,
        "dev_kf_tracks":
        kalman_velo_only["dev_kf_tracks"],
        "host_number_of_svs":
        filter_tracks.host_number_of_svs_t,
        "dev_sv_offsets":
        filter_tracks.dev_sv_offsets_t,
        "dev_svs_trk1_idx":
        filter_tracks.dev_svs_trk1_idx_t,
        "dev_svs_trk2_idx":
        filter_tracks.dev_svs_trk2_idx_t,
        "dev_two_track_particles":
        fit_secondary_vertices.dev_two_track_composites_view_t,
        "dev_multi_event_composites":
        fit_secondary_vertices.dev_multi_event_composites_view_t,
        "dev_multi_event_composites_ptr":
        fit_secondary_vertices.dev_multi_event_composites_ptr_t,
    }


def make_sv_pairs(secondary_vertices):

    number_of_events = initialize_number_of_events()

    calc_max_combos = make_algorithm(
        calc_max_combos_t,
        name='calc_max_combos_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_input1_t=secondary_vertices["dev_multi_event_composites_ptr"],
        dev_input2_t=secondary_vertices["dev_multi_event_composites_ptr"])

    filter_svs = make_algorithm(
        filter_svs_t,
        name='filter_svs_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_max_combos_t=calc_max_combos.host_max_combos_t,
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_max_combo_offsets_t=calc_max_combos.dev_max_combo_offsets_t,
        dev_secondary_vertices_t=secondary_vertices[
            "dev_multi_event_composites"])

    combine_svs = make_algorithm(
        sv_combiner_t,
        name='svs_pair_candidate_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_combos_t=filter_svs.host_number_of_combos_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_combo_offsets_t=filter_svs.dev_combo_offsets_t,
        dev_max_combo_offsets_t=calc_max_combos.dev_max_combo_offsets_t,
        dev_secondary_vertices_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_child1_idx_t=filter_svs.dev_child1_idx_t,
        dev_child2_idx_t=filter_svs.dev_child2_idx_t)

    return {
        "host_number_of_sv_pairs": filter_svs.host_number_of_combos_t,
        "dev_multi_event_sv_combos_view":
        combine_svs.dev_multi_event_combos_view_t
    }


def make_generic_sv_pairs(
        secondary_vertices_1,
        secondary_vertices_2,
        # Filter Properties
        maxVertexChi2=10.,
        minMassV1=0.,
        maxMassV1=20000.,
        minPtV1=200.,
        minCosDiraV1=0.03,
        minEtaV1=2,
        maxEtaV1=5,
        minTrackPtV1=100.,
        minTrackPV1=1000.,
        minTrackIPChi2V1=-999.,
        minTrackIPV1=0.2,
        minMassV2=0.,
        maxMassV2=20000.,
        minPtV2=200.,
        minCosDiraV2=0.03,
        minEtaV2=2,
        maxEtaV2=5,
        minTrackPtV2=100.,
        minTrackPV2=1000.,
        minTrackIPChi2V2=-999.,
        minTrackIPV2=0.2):

    number_of_events = initialize_number_of_events()

    calc_max_combos = make_algorithm(
        calc_max_combos_t,
        name='calc_max_combos_two_svs_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_input1_t=secondary_vertices_1["dev_multi_event_composites_ptr"],
        dev_input2_t=secondary_vertices_2["dev_multi_event_composites_ptr"])

    filter_two_svs = make_algorithm(
        filter_two_svs_t,
        name='filter_two_svs_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_max_combos_t=calc_max_combos.host_max_combos_t,
        host_number_of_svs_1_t=secondary_vertices_1["host_number_of_svs"],
        host_number_of_svs_2_t=secondary_vertices_2["host_number_of_svs"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_max_combo_offsets_t=calc_max_combos.dev_max_combo_offsets_t,
        dev_secondary_vertices_1_t=secondary_vertices_1[
            "dev_multi_event_composites"],
        dev_secondary_vertices_2_t=secondary_vertices_2[
            "dev_multi_event_composites"],
        maxVertexChi2=maxVertexChi2,
        minMassV1=minMassV1,
        maxMassV1=maxMassV1,
        minPtV1=minPtV1,
        minCosDiraV1=minCosDiraV1,
        minEtaV1=minEtaV1,
        maxEtaV1=maxEtaV1,
        minTrackPtV1=minTrackPtV1,
        minTrackPV1=minTrackPV1,
        minTrackIPChi2V1=minTrackIPChi2V1,
        minTrackIPV1=minTrackIPV1,
        minMassV2=minMassV2,
        maxMassV2=maxMassV2,
        minPtV2=minPtV2,
        minCosDiraV2=minCosDiraV2,
        minEtaV2=minEtaV2,
        maxEtaV2=maxEtaV2,
        minTrackPtV2=minTrackPtV2,
        minTrackPV2=minTrackPV2,
        minTrackIPChi2V2=minTrackIPChi2V2,
        minTrackIPV2=minTrackIPV2)

    combine_svs = make_algorithm(
        generic_sv_combiner_t,
        name='generic_svs_pair_candidate_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_combos_t=filter_two_svs.host_total_combo_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_combo_offsets_t=filter_two_svs.dev_combo_offset_t,
        dev_max_combo_offsets_t=calc_max_combos.dev_max_combo_offsets_t,
        dev_secondary_vertices_1_t=secondary_vertices_1[
            "dev_multi_event_composites"],
        dev_secondary_vertices_2_t=secondary_vertices_2[
            "dev_multi_event_composites"],
        dev_child1_idx_t=filter_two_svs.dev_child1_idx_t,
        dev_child2_idx_t=filter_two_svs.dev_child2_idx_t)

    return {
        "host_number_of_sv_sv_combinations": filter_two_svs.host_total_combo_t,
        "dev_multi_event_sv_combos_view":
        combine_svs.dev_multi_event_combos_view_t
    }


def make_sv_track_pairs(secondary_vertices,
                        long_track_particles,
                        pvs,
                        min_track_ipchi2=24.,
                        max_track_ipchi2=1e16,
                        min_track_ip=0.15,
                        max_track_ip=1e16,
                        min_track_pt=100.,
                        sv_bpvip_min=0.032,
                        sv_bpvvdz_min=24.,
                        sv_bpvvdrho_min=3.,
                        sv_bpvdira_min=0.9999,
                        sv_vz_min=-180.,
                        sv_vz_max=650.,
                        sv_track_doca_max=0.15,
                        opening_angle_min=0.5e-3,
                        require_neutral_sv=True):

    number_of_events = initialize_number_of_events()

    filter_sv_track = make_algorithm(
        filter_sv_track_t,
        name='filter_sv_track_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_svs_t=secondary_vertices["dev_multi_event_composites"],
        dev_tracks_t=long_track_particles["dev_multi_event_basic_particles"],
        T_MIPCHI2_min=min_track_ipchi2,
        T_MIPCHI2_max=max_track_ipchi2,
        T_MIP_min=min_track_ip,
        T_MIP_max=max_track_ip,
        T_PT_min=min_track_pt,
        SV_VZ_min=sv_vz_min,
        SV_VZ_max=sv_vz_max,
        SV_BPVIP_min=sv_bpvip_min,
        SV_BPVVDZ_min=sv_bpvvdz_min,
        SV_BPVVDRHO_min=sv_bpvvdrho_min,
        SV_BPVDIRA_min=sv_bpvdira_min,
        SV_T_DOCA_max=sv_track_doca_max,
        opening_angle_min=opening_angle_min,
        require_os_pair=require_neutral_sv)

    combine_sv_track = make_algorithm(
        combine_sv_track_t,
        name='combine_sv_track_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_combinations_t=filter_sv_track.
        host_number_of_combinations_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_combination_offsets_t=filter_sv_track.dev_combination_offsets_t,
        dev_svs_t=secondary_vertices["dev_multi_event_composites"],
        dev_tracks_t=long_track_particles["dev_multi_event_basic_particles"],
        dev_sv_idx_t=filter_sv_track.dev_sv_idx_t,
        dev_track_idx_t=filter_sv_track.dev_track_idx_t,
        dev_pvs_t=pvs["dev_multi_final_vertices"],
        dev_npvs_t=pvs["dev_number_of_multi_final_vertices"])

    return {
        "dev_multi_event_composites":
        combine_sv_track.dev_multi_event_composites_view_t,
        "host_number_of_sv_track_combinations":
        filter_sv_track.host_number_of_combinations_t,
    }
