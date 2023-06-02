###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    pv_beamline_extrapolate_t, pv_beamline_histo_t, pv_beamline_peak_t,
    pv_beamline_calculate_denom_t, pv_beamline_multi_fitter_t,
    pv_beamline_cleanup_t)
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_pvs(velo_tracks, velo_open=False):

    if not velo_open:
        pp_minNumTracksPerVertex = 4.
        maxChi2 = 12.
        maxTrackBlChi2 = 10.
        zmin = -541.
        zmax = 307.
        Nbins = 3392
        dz = 0.25
        SMOG2_pp_separation = -341.
        SMOG2_maxTrackZ0Err = 10.
        pp_maxTrackZ0Err = 1.5

    else:
        pp_minNumTracksPerVertex = 3.
        maxChi2 = 100.
        maxTrackBlChi2 = 300.
        zmin = -541.
        zmax = 307.
        Nbins = 3392
        dz = 0.25
        SMOG2_pp_separation = -341.
        SMOG2_maxTrackZ0Err = 10.
        pp_maxTrackZ0Err = 1.5

    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_velo_tracks = velo_tracks[
        "host_number_of_reconstructed_velo_tracks"]
    dev_offsets_all_velo_tracks = velo_tracks["dev_offsets_all_velo_tracks"]
    dev_offsets_velo_track_hit_number = velo_tracks[
        "dev_offsets_velo_track_hit_number"]
    dev_velo_track_hits = velo_tracks["dev_velo_track_hits"]

    velo_states = run_velo_kalman_filter(velo_tracks)

    pv_beamline_extrapolate = make_algorithm(
        pv_beamline_extrapolate_t,
        name="pv_beamline_extrapolate",
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"])

    pv_beamline_histo = make_algorithm(
        pv_beamline_histo_t,
        name="pv_beamline_histo_{hash}",
        host_number_of_events_t=host_number_of_events,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t,
        maxTrackBlChi2=maxTrackBlChi2,
        zmin=zmin,
        zmax=zmax,
        dz=dz,
        Nbins=Nbins,
        SMOG2_pp_separation=SMOG2_pp_separation,
        SMOG2_maxTrackZ0Err=SMOG2_maxTrackZ0Err,
        pp_maxTrackZ0Err=pp_maxTrackZ0Err)

    pv_beamline_peak = make_algorithm(
        pv_beamline_peak_t,
        name="pv_beamline_peak_{hash}",
        host_number_of_events_t=host_number_of_events,
        dev_zhisto_t=pv_beamline_histo.dev_zhisto_t,
        zmin=zmin,
        dz=dz,
        Nbins=Nbins,
        SMOG2_pp_separation=SMOG2_pp_separation,
        SMOG2_maxTrackZ0Err=SMOG2_maxTrackZ0Err,
        pp_maxTrackZ0Err=pp_maxTrackZ0Err)

    pv_beamline_calculate_denom = make_algorithm(
        pv_beamline_calculate_denom_t,
        name="pv_beamline_calculate_denom_{hash}",
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t,
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t,
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t)

    pv_beamline_multi_fitter = make_algorithm(
        pv_beamline_multi_fitter_t,
        name="pv_beamline_multi_fitter_{hash}",
        host_number_of_events_t=host_number_of_events,
        host_number_of_reconstructed_velo_tracks_t=
        host_number_of_reconstructed_velo_tracks,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t,
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t,
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t,
        dev_pvtracks_denom_t=pv_beamline_calculate_denom.dev_pvtracks_denom_t,
        maxChi2=maxChi2,
        pp_minNumTracksPerVertex=pp_minNumTracksPerVertex,
        zmin=zmin,
        zmax=zmax,
        SMOG2_pp_separation=SMOG2_pp_separation)

    pv_beamline_cleanup = make_algorithm(
        pv_beamline_cleanup_t,
        name="pv_beamline_cleanup_{hash}",
        host_number_of_events_t=host_number_of_events,
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t,
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t)

    return {
        "dev_number_of_zpeaks":
        pv_beamline_peak.dev_number_of_zpeaks_t,
        "dev_multi_final_vertices":
        pv_beamline_cleanup.dev_multi_final_vertices_t,
        "dev_number_of_multi_final_vertices":
        pv_beamline_cleanup.dev_number_of_multi_final_vertices_t,
        "pp_minNumTracksPerVertex":
        pp_minNumTracksPerVertex
    }


def pv_finder(velo_open=False):
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    pvs = make_pvs(velo_tracks, velo_open)
    alg = pvs["dev_multi_final_vertices"].producer
    return alg
