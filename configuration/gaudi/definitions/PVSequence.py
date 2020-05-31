###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from PyConf.components import Algorithm
from algorithms import *
from VeloSequence import initialize_lists, make_velo_tracks


def run_velo_kalman_filter(**kwargs):
    velo_tracks = make_velo_tracks(**kwargs)
    host_number_of_reconstructed_velo_tracks = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]

    initalized_lists = initialize_lists(**kwargs)
    host_number_of_events = initalized_lists[
        "host_number_of_events"]
    dev_velo_states = velo_tracks["dev_velo_states"]
    dev_offsets_all_velo_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    dev_velo_track_hits = velo_tracks["dev_velo_track_hits"]

    velo_kalman_filter = Algorithm(
        velo_kalman_filter_t,
        name="velo_kalman_filter",
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        host_number_of_events_t=host_number_of_events,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_velo_track_hits_t=dev_velo_track_hits,
        dev_velo_states_t=dev_velo_states)

    return {
        "dev_velo_kalman_beamline_states":
        velo_kalman_filter.dev_velo_kalman_beamline_states_t
    }


def make_pvs(**kwargs):
    initalized_lists = initialize_lists(**kwargs)
    host_number_of_events = initalized_lists[
        "host_number_of_events"]
    dev_event_list = initalized_lists["dev_event_list"]

    velo_tracks = make_velo_tracks(**kwargs)
    host_number_of_reconstructed_velo_tracks = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_velo_states = velo_tracks["dev_velo_states"]
    dev_offsets_all_velo_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    dev_velo_track_hits = velo_tracks["dev_velo_track_hits"]

    velo_kalman_filter = run_velo_kalman_filter(**kwargs)

    pv_beamline_extrapolate = Algorithm(
        pv_beamline_extrapolate_t,
        name="pv_beamline_extrapolate",
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        host_number_of_events_t=host_number_of_events,
        dev_velo_kalman_beamline_states_t=velo_kalman_filter[
            "dev_velo_kalman_beamline_states"],
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number)

    pv_beamline_histo = Algorithm(
        pv_beamline_histo_t,
        name="pv_beamline_histo",
        host_number_of_events_t=host_number_of_events,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t)

    pv_beamline_peak = Algorithm(
        pv_beamline_peak_t,
        name="pv_beamline_peak",
        host_number_of_events_t=host_number_of_events,
        dev_zhisto_t=pv_beamline_histo.dev_zhisto_t)

    pv_beamline_calculate_denom = Algorithm(
        pv_beamline_calculate_denom_t,
        name="pv_beamline_calculate_denom",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t,
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t,
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t)

    pv_beamline_multi_fitter = Algorithm(
        pv_beamline_multi_fitter_t,
        name="pv_beamline_multi_fitter",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_offsets_all_velo_tracks_t=dev_offsets_all_velo_tracks,
        dev_offsets_velo_track_hit_number_t=dev_offsets_velo_track_hit_number,
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t,
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t,
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t,
        dev_pvtracks_denom_t=pv_beamline_calculate_denom.dev_pvtracks_denom_t,
        dev_pvtrack_z_t=pv_beamline_extrapolate.dev_pvtrack_z_t)

    pv_beamline_cleanup = Algorithm(
        pv_beamline_cleanup_t,
        name="pv_beamline_cleanup",
        host_number_of_events_t=host_number_of_events,
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t,
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t)

    return {
        "dev_multi_final_vertices":
        pv_beamline_cleanup_t.dev_multi_final_vertices_t,
        "dev_number_of_multi_final_vertices":
        pv_beamline_cleanup_t.dev_number_of_multi_final_vertices_t,
        "dev_multi_fit_vertices":
        pv_beamline_multi_fitter.dev_multi_fit_vertices_t,
        "dev_number_of_multi_fit_vertices":
        pv_beamline_multi_fitter.dev_number_of_multi_fit_vertices_t
    }
