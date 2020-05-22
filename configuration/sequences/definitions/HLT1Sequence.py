from definitions.algorithms import *


def HLT1Sequence(initialize_lists,
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
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_velo_kalman_beamline_states_t=velo_kalman_filter.
        dev_velo_kalman_beamline_states_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=
        prefix_sum_offsets_velo_track_hit_number.dev_output_buffer_t(),
        dev_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_multi_fit_vertices_t(),
        dev_number_of_multi_fit_vertices_t=pv_beamline_multi_fitter.
        dev_number_of_multi_fit_vertices_t())

    kalman_velo_only = kalman_velo_only_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
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
        dev_is_muon_t=is_muon.dev_is_muon_t())

    filter_tracks = filter_tracks_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
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
        dev_kalman_pv_ipchi2_t=kalman_velo_only.dev_kalman_pv_ipchi2_t())

    prefix_sum_secondary_vertices = host_prefix_sum_t(
        name="prefix_sum_secondary_vertices",
        dev_input_buffer_t=filter_tracks.dev_sv_atomics_t())

    fit_secondary_vertices = fit_secondary_vertices_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
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
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t())

    odin_banks = data_provider_t(name="populate_odin_banks", bank_type="ODIN")

    run_hlt1 = run_hlt1_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t(),
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t(),
        dev_consolidated_svs_t=fit_secondary_vertices.dev_consolidated_svs_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t(),
        dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
        dev_offsets_all_velo_tracks_t=velo_copy_track_hit_number.
        dev_offsets_all_velo_tracks_t())

    prepare_raw_banks = prepare_raw_banks_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t(),
        host_number_of_svs_t=prefix_sum_secondary_vertices.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
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
        dev_offsets_scifi_track_hit_number_t=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t(),
        dev_scifi_qop_t=scifi_consolidate_tracks.dev_scifi_qop_t(),
        dev_scifi_states_t=scifi_consolidate_tracks.dev_scifi_states_t(),
        dev_scifi_track_ut_indices_t=scifi_consolidate_tracks.
        dev_scifi_track_ut_indices_t(),
        dev_ut_track_hits_t=ut_consolidate_tracks.dev_ut_track_hits_t(),
        dev_scifi_track_hits_t=scifi_consolidate_tracks.
        dev_scifi_track_hits_t(),
        dev_kf_tracks_t=kalman_velo_only.dev_kf_tracks_t(),
        dev_consolidated_svs_t=fit_secondary_vertices.dev_consolidated_svs_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_sv_offsets_t=prefix_sum_secondary_vertices.dev_output_buffer_t(),
        dev_sel_results_t=run_hlt1.dev_sel_results_t(),
        dev_sel_results_offsets_t=run_hlt1.dev_sel_results_offsets_t())

    prefix_sum_sel_reps = host_prefix_sum_t(
        name="prefix_sum_sel_reps",
        dev_input_buffer_t=prepare_raw_banks.dev_sel_rep_sizes_t())

    package_sel_reports = package_sel_reports_t(
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        host_number_of_sel_rep_words_t=prefix_sum_sel_reps.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_sel_rb_hits_t=prepare_raw_banks.dev_sel_rb_hits_t(),
        dev_sel_rb_stdinfo_t=prepare_raw_banks.dev_sel_rb_stdinfo_t(),
        dev_sel_rb_objtyp_t=prepare_raw_banks.dev_sel_rb_objtyp_t(),
        dev_sel_rb_substr_t=prepare_raw_banks.dev_sel_rb_substr_t(),
        dev_sel_rep_offsets_t=prefix_sum_sel_reps.dev_output_buffer_t())

    hlt1_sequence = Sequence(
        velo_pv_ip, kalman_velo_only, filter_tracks,
        prefix_sum_secondary_vertices, fit_secondary_vertices, odin_banks,
        run_hlt1, prepare_raw_banks, prefix_sum_sel_reps, package_sel_reports)

    if add_default_lines:
        ErrorEvent_line = ErrorEvent_t()
        PassThrough_line = PassThrough_t()
        NoBeams_line = NoBeams_t()
        BeamOne_line = BeamOne_t()
        BeamTwo_line = BeamTwo_t()
        BothBeams_line = BothBeams_t()
        ODINNoBias_line = ODINNoBias_t()
        ODINLumi_line = ODINLumi_t()
        GECPassthrough_line = GECPassthrough_t()
        VeloMicroBias_line = VeloMicroBias_t()
        TrackMVA_line = TrackMVA_t()
        TrackMuonMVA_line = TrackMuonMVA_t()
        SingleHighPtMuon_line = SingleHighPtMuon_t()
        LowPtMuon_line = LowPtMuon_t()
        TwoTrackMVA_line = TwoTrackMVA_t()
        DiMuonHighMass_line = DiMuonHighMass_t()
        DiMuonLowMass_line = DiMuonLowMass_t()
        LowPtDiMuon_line = LowPtDiMuon_t()
        DisplacedDiMuon_line = DisplacedDiMuon_t()
        DiMuonSoft_line = DiMuonSoft_t()
        D2KPi_line = D2KPi_t()
        D2PiPi_line = D2PiPi_t()
        D2KK_line = D2KK_t()

        return extend_sequence(
            hlt1_sequence, ErrorEvent_line, PassThrough_line, NoBeams_line,
            BeamOne_line, BeamTwo_line, BothBeams_line, ODINNoBias_line,
            ODINLumi_line, GECPassthrough_line, VeloMicroBias_line,
            TrackMVA_line, TrackMuonMVA_line, SingleHighPtMuon_line,
            LowPtMuon_line, TwoTrackMVA_line, DiMuonHighMass_line,
            DiMuonLowMass_line, LowPtDiMuon_line, DiMuonSoft_line, D2KPi_line,
            D2PiPi_line, D2KK_line)

    return hlt1_sequence
