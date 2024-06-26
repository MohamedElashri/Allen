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
    mc_data_provider_t, host_velo_validator_t, host_velo_ut_validator_t,
    long_track_validator_t, muon_validator_t, host_pv_validator_t,
    host_rate_validator_t, host_routingbits_validator_t, kalman_validator_t,
    host_seeding_XZ_validator_t, host_seeding_validator_t,
    host_downstream_dump_t, downstream_validator_t, host_veloscifi_dump_t,
    host_data_provider_t, host_sel_report_validator_t,
    data_quality_validator_long_t, data_quality_validator_occupancy_t,
    data_quality_validator_pv_t, data_quality_validator_velo_t,
    host_unmatched_seeding_validator_t, downstream_composite_dumper_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenConf.persistency import make_dec_reporter, make_gather_selections, make_routingbits_writer, rb_map
from AllenCore.algorithms import seeding_copy_trackXZ_hit_number_t
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.muon_reconstruction import decode_muon
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.calo_reconstruction import decode_calo, make_ecal_clusters


def mc_data_provider():
    host_mc_particle_banks = make_algorithm(
        host_data_provider_t,
        name="host_mc_particle_banks",
        bank_type="tracks")
    host_mc_pv_banks = make_algorithm(
        host_data_provider_t, name="host_mc_pv_banks", bank_type="PVs")
    number_of_events = initialize_number_of_events()
    return make_algorithm(
        mc_data_provider_t,
        name="mc_data_provider",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_particle_banks_t=host_mc_particle_banks.host_raw_banks_t,
        host_mc_particle_offsets_t=host_mc_particle_banks.host_raw_offsets_t,
        host_mc_particle_sizes_t=host_mc_particle_banks.host_raw_sizes_t,
        host_mc_pv_banks_t=host_mc_pv_banks.host_raw_banks_t,
        host_mc_pv_offsets_t=host_mc_pv_banks.host_raw_offsets_t,
        host_mc_pv_sizes_t=host_mc_pv_banks.host_raw_sizes_t,
        host_bank_version_t=host_mc_particle_banks.host_raw_bank_version_t)


def velo_validation(velo_tracks, name="velo_validator"):
    number_of_events = initialize_number_of_events()
    mc_events = mc_data_provider()

    return make_algorithm(
        host_velo_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_events.host_mc_events_t)


def veloUT_validation(veloUT_tracks, name="veloUT_validator"):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()

    velo_tracks = veloUT_tracks["velo_tracks"]
    velo_states = veloUT_tracks["velo_states"]

    return make_algorithm(
        host_velo_ut_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        host_mc_events_t=mc_events.host_mc_events_t,
        dev_velo_kalman_endvelo_states_t=velo_states[
            "dev_velo_kalman_endvelo_states"],
        dev_offsets_ut_tracks_t=veloUT_tracks["dev_offsets_ut_tracks"],
        dev_offsets_ut_track_hit_number_t=veloUT_tracks[
            "dev_offsets_ut_track_hit_number"],
        dev_ut_track_hits_t=veloUT_tracks["dev_ut_track_hits"],
        dev_ut_track_velo_indices_t=veloUT_tracks["dev_ut_track_velo_indices"],
        dev_ut_qop_t=veloUT_tracks["dev_ut_qop"])


def long_validation(long_tracks, name="long_validator"):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()

    velo_kalman_filter = long_tracks["velo_kalman_filter"]

    return make_algorithm(
        long_track_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        host_number_of_reconstructed_long_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        dev_multi_event_long_tracks_view_t=long_tracks[
            "dev_multi_event_long_tracks_view"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"])


def downstream_validation(downstream_tracks, name="downstream_validator"):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        downstream_validator_t,
        name=name,
        # Basic
        host_mc_events_t=mc_events.host_mc_events_t,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Downstream output
        host_number_of_downstream_tracks_t=downstream_tracks[
            'host_number_of_downstream_tracks'],
        dev_offsets_downstream_tracks_t=downstream_tracks[
            'dev_offsets_downstream_tracks'],
        dev_multi_event_downstream_tracks_view_t=downstream_tracks[
            'dev_multi_event_downstream_tracks_view'],
        dev_downstream_track_states_view_t=downstream_tracks[
            'dev_downstream_track_states_view'])


def seeding_xz_validation(name="seed_xz_validator"):
    mc_events = mc_data_provider()
    decoded_scifi = decode_scifi()
    seeding_tracks = make_seeding_XZ_tracks(decoded_scifi)

    number_of_events = initialize_number_of_events()

    seeding_copy_trackXZ_hit_number = make_algorithm(
        seeding_copy_trackXZ_hit_number_t,
        name="seeding_copy_trackXZ_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_seeding_tracksXZ_t=seeding_tracks["seed_xz_tracks"],
        dev_seed_xz_number_of_tracks_t=seeding_tracks[
            "seed_xz_number_of_tracks"],
        dev_event_list_t=number_of_events["dev_number_of_events"])

    return make_algorithm(
        host_seeding_XZ_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_scifi_seedsXZ_t=seeding_copy_trackXZ_hit_number.
        dev_offsets_scifi_seedsXZ_t,
        dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
        dev_scifi_hit_count_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_offsets_scifi_seedXZ_hit_number_t=seeding_copy_trackXZ_hit_number.
        dev_offsets_scifi_seedXZ_hit_number_t,
        dev_scifi_seedsXZ_t=seeding_tracks["seed_xz_tracks"],
        host_mc_events_t=mc_events.host_mc_events_t)


def seeding_validation(seeding_tracks, name="seed_validator"):
    mc_events = mc_data_provider()
    #decoded_scifi = decode_scifi("v6")
    #seeding_tracks = make_seeding_tracks(decoded_scifi)

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_seeding_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_scifi_seeds_t=seeding_tracks["dev_offsets_scifi_seeds"],
        dev_scifi_hits_t=seeding_tracks["dev_seeding_track_hits"],
        dev_offsets_scifi_seed_hit_number_t=seeding_tracks[
            "dev_offsets_scifi_seed_hit_number"],
        dev_scifi_seeds_t=seeding_tracks["seed_tracks"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"],
        host_mc_events_t=mc_events.host_mc_events_t)


def seeding_unmatched_validation(seeding_tracks,
                                 velo_scifi_matches,
                                 name="unmached_seed_validator"):
    mc_events = mc_data_provider()
    #decoded_scifi = decode_scifi("v6")
    #seeding_tracks = make_seeding_tracks(decoded_scifi)

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_unmatched_seeding_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_scifi_seeds_t=seeding_tracks["dev_offsets_scifi_seeds"],
        dev_scifi_hits_t=seeding_tracks["dev_seeding_track_hits"],
        dev_offsets_scifi_seed_hit_number_t=seeding_tracks[
            "dev_offsets_scifi_seed_hit_number"],
        dev_scifi_seeds_t=seeding_tracks["seed_tracks"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"],
        dev_matched_is_scifi_track_used_t=velo_scifi_matches[
            "dev_matched_is_scifi_track_used"],
        host_mc_events_t=mc_events.host_mc_events_t)


def downstream_dump(downstream_tracks,
                    dump_scifi=True,
                    dump_ut_hits=False,
                    dump_downstream=False,
                    dump_mcps=False,
                    output_folder='dump_output'):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()
    ut_hits = downstream_tracks['decode_ut']
    velo_scifi_matches = downstream_tracks['velo_scifi_matches']
    seeding_tracks = downstream_tracks['scifi_seeds']
    return make_algorithm(
        host_downstream_dump_t,
        name='DownstreamDump',
        # Basic
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        # UT
        dev_ut_hits_t=ut_hits['dev_ut_hits'],
        dev_ut_hit_offsets_t=ut_hits['dev_ut_hit_offsets'],
        # Scifi
        dev_seeding_qop_t=seeding_tracks["dev_seeding_qop"],
        # dev_seeding_chi2X_t=seeding_tracks["dev_seeding_chi2X"],
        dev_seeding_chi2Y_t=seeding_tracks["dev_seeding_chi2Y"],
        # dev_seeding_nY_t=seeding_tracks["dev_seeding_nY"],
        dev_offsets_scifi_seeds_t=seeding_tracks["dev_offsets_scifi_seeds"],
        dev_scifi_hits_t=seeding_tracks["dev_seeding_track_hits"],
        dev_offsets_scifi_seed_hit_number_t=seeding_tracks[
            "dev_offsets_scifi_seed_hit_number"],
        dev_scifi_seeds_t=seeding_tracks["seed_tracks"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"],
        # VeloScifi
        dev_matched_is_scifi_track_used_t=velo_scifi_matches[
            "dev_matched_is_scifi_track_used"],
        # Downstream
        dev_offsets_downstream_hit_numbers_t=downstream_tracks[
            'dev_offsets_downstream_hit_numbers'],
        dev_offsets_downstream_tracks_t=downstream_tracks[
            'dev_offsets_downstream_tracks'],
        dev_downstream_track_scifi_idx_t=downstream_tracks[
            'dev_downstream_track_scifi_idx'],
        dev_downstream_track_hits_t=downstream_tracks[
            'dev_downstream_track_hits'],
        dev_downstream_track_states_t=downstream_tracks[
            'dev_downstream_track_states'],
        dump_scifi=dump_scifi,
        dump_ut_hits=dump_ut_hits,
        dump_downstream=dump_downstream,
        dump_mcps=dump_mcps,
        output_folder=output_folder)


def velo_scifi_dump(matched_tracks, name="veloscifi_dump"):
    mc_events = mc_data_provider()

    velo_tracks = matched_tracks["velo_tracks"]
    velo_kalman_filter = matched_tracks["velo_kalman_filter"]
    seeding_tracks = matched_tracks["seeding_tracks"]

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_veloscifi_dump_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        dev_velo_kalman_states_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states"],
        dev_ut_number_of_selected_velo_tracks_t=matched_tracks[
            "dev_ut_number_of_selected_velo_tracks"],
        dev_ut_selected_velo_tracks_t=matched_tracks[
            "dev_ut_selected_velo_tracks"],
        dev_offsets_scifi_seeds_t=seeding_tracks["dev_offsets_scifi_seeds"],
        dev_scifi_hits_t=seeding_tracks["dev_seeding_track_hits"],
        dev_offsets_scifi_seed_hit_number_t=seeding_tracks[
            "dev_offsets_scifi_seed_hit_number"],
        dev_scifi_seeds_t=seeding_tracks["seed_tracks"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"])


def muon_validation(muonID, name="muon_validator"):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()

    long_tracks = muonID["long_tracks"]
    velo_kalman_filter = long_tracks["velo_kalman_filter"]

    return make_algorithm(
        muon_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        host_number_of_reconstructed_long_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        dev_multi_event_long_tracks_view_t=long_tracks[
            "dev_multi_event_long_tracks_view"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_is_muon_t=muonID["dev_is_muon"])


def pv_validation(pvs, name="pv_validator"):
    mc_events = mc_data_provider()

    return make_algorithm(
        host_pv_validator_t,
        name=name,
        host_mc_events_t=mc_events.host_mc_events_t,
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        pp_minNumTracksPerVertex=pvs["pp_minNumTracksPerVertex"])


def rate_validation(lines, name="rate_validator"):
    number_of_events = initialize_number_of_events()
    dec_reporter = make_dec_reporter(lines)
    gather_selections = make_gather_selections(lines)

    return make_algorithm(
        host_rate_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_names_of_lines_t=gather_selections.host_names_of_active_lines_t,
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        host_dec_reports_t=dec_reporter.host_dec_reports_t)


def routingbits_validation(lines, name="routingbits_validator"):
    number_of_events = initialize_number_of_events()
    dec_reporter = make_dec_reporter(lines)
    gather_selections = make_gather_selections(lines)
    routingbits_writer = make_routingbits_writer(lines)

    return make_algorithm(
        host_routingbits_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_names_of_lines_t=gather_selections.host_names_of_active_lines_t,
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        host_dec_reports_t=dec_reporter.host_dec_reports_t,
        host_routingbits_t=routingbits_writer.host_routingbits_t,
        routingbit_map=str(rb_map))


def kalman_validation(kalman_velo_only, name="kalman_validator"):
    number_of_events = initialize_number_of_events()
    mc_events = mc_data_provider()

    long_tracks = kalman_velo_only["long_tracks"]
    velo_kalman_filter = long_tracks["velo_kalman_filter"]
    pvs = kalman_velo_only["pvs"]

    return make_algorithm(
        kalman_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        host_number_of_reconstructed_long_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        dev_multi_event_long_tracks_view_t=long_tracks[
            "dev_multi_event_long_tracks_view"],
        dev_kf_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"])


def selreport_validation(make_selreports,
                         gather_selections,
                         name="selreport_validator"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        host_sel_report_validator_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_names_of_lines_t=gather_selections.host_names_of_active_lines_t,
        dev_sel_reports_t=make_selreports["dev_sel_reports"],
        dev_sel_report_offsets_t=make_selreports["dev_selrep_offsets"])


def data_quality_validation_long(long_tracks,
                                 long_track_particles,
                                 name="data_quality_validator"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        data_quality_validator_long_t,
        name=name,
        enable_tupling=True,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_offsets_long_tracks_t=long_tracks["dev_offsets_long_tracks"],
        host_number_of_reconstructed_long_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"])


def data_quality_validation_velo(long_tracks, name="data_quality_validator"):
    number_of_events = initialize_number_of_events()

    velo_tracks = long_tracks["velo_tracks"]
    velo_kalman_filter = long_tracks["velo_kalman_filter"]

    return make_algorithm(
        data_quality_validator_velo_t,
        name=name,
        enable_tupling=True,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_velo_track_hits_t=velo_tracks["dev_velo_track_hits"],
        dev_velo_kalman_states_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states"])


def data_quality_validation_pv(long_tracks, name="data_quality_validator"):
    number_of_events = initialize_number_of_events()

    velo_tracks = long_tracks["velo_tracks"]
    pvs = make_pvs(velo_tracks)

    return make_algorithm(
        data_quality_validator_pv_t,
        name=name,
        enable_tupling=True,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_multi_fit_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_fit_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
    )


def data_quality_validation_occupancy(name="data_quality_validator"):
    number_of_events = initialize_number_of_events()

    decoded_scifi = decode_scifi()
    decoded_muon = decode_muon()
    decoded_calo = decode_calo()
    ecal_clusters = make_ecal_clusters(decoded_calo)

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)

    return make_algorithm(
        data_quality_validator_occupancy_t,
        name=name,
        enable_tupling=True,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_velo_offsets_estimated_input_size_t=decoded_velo[
            "dev_offsets_estimated_input_size"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_ecal_clusters_offsets_t=ecal_clusters["dev_ecal_cluster_offsets"])


def dump_downstream_secondary_vertices(
        downstream_tracks,
        downstream_secondary_vertices,
        name="dump_downstream_secondary_vertices"):
    mc_events = mc_data_provider()
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        downstream_composite_dumper_t,
        name=name,
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_mc_events_t=mc_events.host_mc_events_t,
        # Long tracks
        host_number_of_vertices_t=downstream_secondary_vertices[
            "host_number_of_svs"],
        dev_offset_vertices_t=downstream_secondary_vertices["dev_sv_offsets"],
        dev_multi_event_composites_view_t=downstream_secondary_vertices[
            "dev_multi_event_composites"],
        # Extras
        dev_downstream_mva_ks_t=downstream_secondary_vertices[
            "dev_downstream_mva_ks"],
        dev_downstream_mva_l0_t=downstream_secondary_vertices[
            "dev_downstream_mva_l0"],
        dev_downstream_mva_detached_ks_t=downstream_secondary_vertices[
            "dev_downstream_mva_detached_ks"],
        dev_downstream_mva_detached_l0_t=downstream_secondary_vertices[
            "dev_downstream_mva_detached_l0"],
    )
