from definitions.algorithms import *


def HLT1Sequence():
    # Needed for aligning selections with Moore.
    velo_pv_ip = velo_pv_ip_t()

    kalman_velo_only = kalman_velo_only_t()

    filter_tracks = filter_tracks_t()
    fit_secondary_vertices = fit_secondary_vertices_t()
    prefix_sum_secondary_vertices = host_prefix_sum_t(
        "prefix_sum_secondary_vertices",
        host_total_sum_holder_t="host_number_of_svs_t",
        dev_input_buffer_t=filter_tracks.dev_sv_atomics_t(),
        dev_output_buffer_t="dev_sv_offsets_t")

    run_hlt1 = run_hlt1_t()
    run_postscale = run_postscale_t()
    prepare_decisions = prepare_decisions_t()
    prepare_raw_banks = prepare_raw_banks_t()

    prefix_sum_sel_reps = host_prefix_sum_t(
        "prefix_sum_sel_reps",
        host_total_sum_holder_t="host_number_of_sel_rep_words_t",
        dev_input_buffer_t=prepare_raw_banks.dev_sel_rep_sizes_t(),
        dev_output_buffer_t="dev_sel_rep_offsets_t")

    package_sel_reports = package_sel_reports_t()

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

    hlt1_sequence = Sequence(
        velo_pv_ip, kalman_velo_only, filter_tracks,
        prefix_sum_secondary_vertices, fit_secondary_vertices, run_hlt1,
        run_postscale, prepare_decisions, prepare_raw_banks,
        prefix_sum_sel_reps, package_sel_reports, ErrorEvent_line,
        PassThrough_line, NoBeams_line, BeamOne_line, BeamTwo_line,
        BothBeams_line, ODINNoBias_line, ODINLumi_line, GECPassthrough_line,
        VeloMicroBias_line, TrackMVA_line, TrackMuonMVA_line,
        SingleHighPtMuon_line, LowPtMuon_line, TwoTrackMVA_line,
        DiMuonHighMass_line, DiMuonLowMass_line, LowPtDiMuon_line,
        DiMuonSoft_line, D2KPi_line, D2PiPi_line, D2KK_line)

    return hlt1_sequence
