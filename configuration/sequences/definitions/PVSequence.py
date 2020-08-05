###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *


def PVSequence(initialize_lists, velo_copy_track_hit_number,
               velo_consolidate_tracks,
               prefix_sum_offsets_velo_track_hit_number,
               velo_kalman_filter):

    pv_beamline_extrapolate = pv_beamline_extrapolate_t(
        name="pv_beamline_extrapolate",
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_velo_kalman_beamline_states_t=velo_kalman_filter.
        dev_velo_kalman_beamline_states_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t())

    pv_beamline_histo = pv_beamline_histo_t(
        name="pv_beamline_histo",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t())

    pv_beamline_peak = pv_beamline_peak_t(
        name="pv_beamline_peak",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_zhisto_t=pv_beamline_histo.dev_zhisto_t())

    pv_beamline_calculate_denom = pv_beamline_calculate_denom_t(
        name="pv_beamline_calculate_denom",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t(),
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t(),
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t())

    pv_beamline_multi_fitter = pv_beamline_multi_fitter_t(
        name="pv_beamline_multi_fitter",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_pvtracks_t=pv_beamline_extrapolate.dev_pvtracks_t(),
        dev_zpeaks_t=pv_beamline_peak.dev_zpeaks_t(),
        dev_number_of_zpeaks_t=pv_beamline_peak.dev_number_of_zpeaks_t(),
        dev_pvtracks_denom_t=pv_beamline_calculate_denom.
        dev_pvtracks_denom_t(),
        dev_pvtrack_z_t=pv_beamline_extrapolate.dev_pvtrack_z_t())

    pv_beamline_cleanup = pv_beamline_cleanup_t(
        name="pv_beamline_cleanup",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t())

    pv_sequence = Sequence(velo_kalman_filter, pv_beamline_extrapolate,
                           pv_beamline_histo, pv_beamline_peak,
                           pv_beamline_calculate_denom,
                           pv_beamline_multi_fitter, pv_beamline_cleanup)

    return pv_sequence
