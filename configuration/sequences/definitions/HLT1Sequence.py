###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *


def make_selection_gatherer(lines, initialize_lists, layout_provider,
                            populate_odin_banks, **kwargs):
    return gather_selections_t(
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_mep_layout_t=layout_provider.host_mep_layout_t(),
        dev_mep_layout_t=layout_provider.dev_mep_layout_t(),
        dev_input_selections_t=tuple(line.dev_decisions_t() for line in lines),
        dev_input_selections_offsets_t=tuple(
            line.dev_decisions_offsets_t() for line in lines),
        dev_odin_raw_input_t=populate_odin_banks.dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=populate_odin_banks.dev_raw_offsets_t(),
        names_of_active_lines=",".join([line.name() for line in lines]),
        **kwargs)


def HLT1Sequence(layout_provider,
                 initialize_lists,
                 full_event_list,
                 velo_copy_track_hit_number,
                 velo_kalman_filter,
                 prefix_sum_offsets_velo_track_hit_number,
                 pv_beamline_multi_fitter,
                 prefix_sum_forward_tracks,
                 velo_consolidate_tracks,
                 prefix_sum_ut_tracks,
                 prefix_sum_ut_track_hit_number,
                 ut_consolidate_tracks,
                 prefix_sum_scifi_track_hit_number,
                 scifi_consolidate_tracks,
                 is_muon,
                 add_default_lines=True):

    velo_pv_ip = velo_pv_ip_t(
        host_number_of_reconstructed_velo_tracks_t=velo_copy_track_hit_number.
        host_number_of_reconstructed_velo_tracks_t(),
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_velo_kalman_beamline_states_t=velo_kalman_filter.
        dev_velo_kalman_beamline_states_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    kalman_velo_only = kalman_velo_only_t(
        name="kalman_velo_only",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_velo_track_hits_t=velo_consolidate_tracks.dev_velo_track_hits_t(),
        dev_offsets_ut_tracks_t=prefix_sum_ut_tracks.dev_output_buffer_t(),
        dev_offsets_ut_track_hit_number_t=prefix_sum_ut_track_hit_number.
        dev_output_buffer_t(),
        dev_ut_qop_t=ut_consolidate_tracks.dev_ut_qop_t(),
        dev_ut_track_velo_indices_t=ut_consolidate_tracks.
        dev_ut_track_velo_indices_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t(),
        dev_scifi_qop_t=scifi_consolidate_tracks.dev_scifi_qop_t(),
        dev_scifi_states_t=scifi_consolidate_tracks.dev_scifi_states_t(),
        dev_scifi_track_ut_indices_t=scifi_consolidate_tracks.
        dev_scifi_track_ut_indices_t(),
        dev_velo_pv_ip_t=velo_pv_ip.dev_velo_pv_ip_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t(),
        dev_is_muon_t=is_muon.dev_is_muon_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    filter_tracks = filter_tracks_t(
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t(),
        dev_scifi_qop_t=scifi_consolidate_tracks.dev_scifi_qop_t(),
        dev_scifi_states_t=scifi_consolidate_tracks.dev_scifi_states_t(),
        dev_scifi_track_ut_indices_t=scifi_consolidate_tracks.
        dev_scifi_track_ut_indices_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t(),
        dev_kalman_pv_ipchi2_t=kalman_velo_only.dev_kalman_pv_ipchi2_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    prefix_sum_secondary_vertices = host_prefix_sum_t(
        name="prefix_sum_secondary_vertices",
        dev_input_buffer_t=filter_tracks.dev_sv_atomics_t())

    fit_secondary_vertices = fit_secondary_vertices_t(
        name="fit_secondary_vertices",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t(),
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t(),
        dev_scifi_qop_t=scifi_consolidate_tracks.dev_scifi_qop_t(),
        dev_scifi_states_t=scifi_consolidate_tracks.dev_scifi_states_t(),
        dev_scifi_track_ut_indices_t=scifi_consolidate_tracks.
        dev_scifi_track_ut_indices_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t(),
        dev_kalman_pv_ipchi2_t=kalman_velo_only.dev_kalman_pv_ipchi2_t(),
        dev_svs_trk1_idx_t=filter_tracks.dev_svs_trk1_idx_t(),
        dev_svs_trk2_idx_t=filter_tracks.dev_svs_trk2_idx_t(),
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    odin_banks = data_provider_t(name="odin_banks", bank_type="ODIN")

    hlt1_sequence = Sequence(velo_pv_ip, kalman_velo_only, filter_tracks,
                             prefix_sum_secondary_vertices,
                             fit_secondary_vertices, odin_banks)

    if add_default_lines:
        track_mva_line = track_mva_line_t(
            name="track_mva_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            host_number_of_reconstructed_scifi_tracks_t=
            prefix_sum_forward_tracks.host_total_sum_holder_t(),
            dev_tracks_t=kalman_velo_only.dev_kf_tracks_t(),
            dev_event_list_t=initialize_lists.dev_event_list_t(),
            dev_track_offsets_t=prefix_sum_forward_tracks.
            dev_output_buffer_t())

        two_track_mva_line = two_track_mva_line_t(
            name="two_track_mva_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            host_number_of_svs_t=prefix_sum_secondary_vertices.
            host_total_sum_holder_t(),
            dev_svs_t=fit_secondary_vertices.dev_consolidated_svs_t(),
            dev_event_list_t=initialize_lists.dev_event_list_t(),
            dev_sv_offsets_t=prefix_sum_secondary_vertices.
            dev_output_buffer_t())

        no_beam_line = beam_crossing_line_t(
            name="no_beam_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            dev_mep_layout_t=layout_provider.dev_mep_layout_t(),
            dev_event_list_t=full_event_list.dev_event_list_t(),
            dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
            dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
            beam_crossing_type="0")

        beam_one_line = beam_crossing_line_t(
            name="beam_one_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            dev_mep_layout_t=layout_provider.dev_mep_layout_t(),
            dev_event_list_t=full_event_list.dev_event_list_t(),
            dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
            dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
            beam_crossing_type="1")

        beam_two_line = beam_crossing_line_t(
            name="beam_two_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            dev_mep_layout_t=layout_provider.dev_mep_layout_t(),
            dev_event_list_t=full_event_list.dev_event_list_t(),
            dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
            dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
            beam_crossing_type="2")

        both_beams_line = beam_crossing_line_t(
            name="both_beams_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            dev_mep_layout_t=layout_provider.dev_mep_layout_t(),
            dev_event_list_t=full_event_list.dev_event_list_t(),
            dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
            dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
            beam_crossing_type="3")

        velo_micro_bias_line = velo_micro_bias_line_t(
            name="velo_micro_bias_line",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
            dev_event_list_t=full_event_list.dev_event_list_t(),
            dev_offsets_velo_tracks_t=velo_copy_track_hit_number.
            dev_offsets_all_velo_tracks_t(),
            dev_offsets_velo_track_hit_number_t=
            prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t())

        lines = (track_mva_line, two_track_mva_line, no_beam_line,
                 beam_one_line, beam_two_line, both_beams_line,
                 velo_micro_bias_line)
        gatherer = make_selection_gatherer(
            lines,
            initialize_lists,
            layout_provider,
            odin_banks,
            name="gather_selections")

        dec_reporter = dec_reporter_t(
            name="dec_reporter",
            host_number_of_events_t=initialize_lists.host_number_of_events_t(),
            host_number_of_active_lines_t=gatherer.
            host_number_of_active_lines_t(),
            dev_number_of_active_lines_t=gatherer.
            dev_number_of_active_lines_t(),
            dev_selections_t=gatherer.dev_selections_t(),
            dev_selections_offsets_t=gatherer.dev_selections_offsets_t())

        return extend_sequence(
            extend_sequence(hlt1_sequence, *lines), gatherer, dec_reporter)

    return hlt1_sequence
