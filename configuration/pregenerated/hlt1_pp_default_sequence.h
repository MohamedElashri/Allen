#pragma once

#include <tuple>
#include "ConfiguredInputAggregates.h"
#include "..//device/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"
#include "..//device/selections/lines/muon/include/LowPtDiMuonLine.cuh"
#include "..//device/muon/is_muon/include/IsMuon.cuh"
#include "..//device/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"
#include "..//host/init_event_list/include/HostInitEventList.h"
#include "..//device/muon/decoding/include/MuonCalculateSRQSize.cuh"
#include "..//device/selections/lines/inclusive_hadron/include/TwoTrackMVALine.cuh"
#include "..//device/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"
#include "..//device/selections/lines/calibration/include/D2KPiLine.cuh"
#include "..//device/associate/include/VeloPVIP.cuh"
#include "..//host/data_provider/include/DataProvider.h"
#include "..//device/SciFi/looking_forward/include/LFTripletSeeding.cuh"
#include "..//device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"
#include "..//device/UT/compassUT/include/CompassUT.cuh"
#include "..//device/SciFi/looking_forward/include/LFCreateTracks.cuh"
#include "..//device/velo/search_by_triplet/include/SearchByTriplet.cuh"
#include "..//device/velo/mask_clustering/include/MaskedVeloClustering.cuh"
#include "..//device/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"
#include "..//device/UT/consolidate/include/UTCopyTrackHitNumber.cuh"
#include "..//device/SciFi/consolidate/include/ConsolidateSciFi.cuh"
#include "..//device/UT/compassUT/include/SearchWindows.cuh"
#include "..//device/selections/lines/calibration/include/PassthroughLine.cuh"
#include "..//device/selections/Hlt1/include/GatherSelections.cuh"
#include "..//device/muon/decoding/include/MuonPopulateTileAndTDC.cuh"
#include "..//device/vertex_fit/two_track_catboost/include/TwoTrackPreprocess.cuh"
#include "..//device/selections/lines/monitoring/include/ODINEventTypeLine.cuh"
#include "..//device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"
#include "..//device/selections/lines/monitoring/include/VeloMicroBiasLine.cuh"
#include "..//device/SciFi/looking_forward/include/LFQualityFilterLength.cuh"
#include "..//device/PV/beamlinePV/include/pv_beamline_histo.cuh"
#include "..//device/kalman/ParKalman/include/ParKalmanVeloOnly.cuh"
#include "..//device/selections/lines/inclusive_hadron/include/TwoTrackCatBoostLine.cuh"
#include "..//device/SciFi/preprocessing/include/SciFiRawBankDecoderV4.cuh"
#include "..//device/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"
#include "..//device/PV/beamlinePV/include/pv_beamline_cleanup.cuh"
#include "..//device/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"
#include "..//host/global_event_cut/include/HostGlobalEventCut.h"
#include "..//device/selections/lines/muon/include/SingleHighPtMuonLine.cuh"
#include "..//device/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"
#include "..//device/selections/lines/muon/include/DiMuonMassLine.cuh"
#include "..//device/selections/lines/inclusive_hadron/include/TrackMVALine.cuh"
#include "..//host/data_provider/include/HostDataProvider.h"
#include "..//device/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"
#include "..//device/selections/lines/muon/include/TrackMuonMVALine.cuh"
#include "..//host/data_provider/include/LayoutProvider.h"
#include "..//device/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"
#include "..//device/SciFi/preprocessing/include/SciFiCalculateClusterCountV4.cuh"
#include "..//device/selections/lines/charm/include/D2PiPiLine.cuh"
#include "..//device/selections/Hlt1/include/DecReporter.cuh"
#include "..//device/selections/lines/charm/include/D2KKLine.cuh"
#include "..//device/UT/UTDecoding/include/UTPreDecode.cuh"
#include "..//device/vertex_fit/vertex_fitter/include/VertexFitter.cuh"
#include "..//device/vertex_fit/two_track_catboost/include/TwoTrackEvaluator.cuh"
#include "..//device/UT/consolidate/include/ConsolidateUT.cuh"
#include "..//host/init_event_list/include/HostInitNumberOfEvents.h"
#include "..//device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"
#include "..//device/SciFi/looking_forward/include/LFQualityFilter.cuh"
#include "..//device/velo/mask_clustering/include/EstimateInputSize.cuh"
#include "..//device/SciFi/preprocessing/include/SciFiPreDecodeV4.cuh"
#include "..//device/UT/UTDecoding/include/UTFindPermutation.cuh"
#include "..//device/selections/lines/monitoring/include/BeamCrossingLine.cuh"
#include "..//device/muon/decoding/include/MuonPopulateHits.cuh"
#include "..//device/vertex_fit/vertex_fitter/include/FilterTracks.cuh"
#include "..//device/UT/compassUT/include/UTSelectVeloTracks.cuh"
#include "..//device/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"
#include "..//device/selections/lines/muon/include/DiMuonSoftLine.cuh"
#include "..//device/selections/lines/muon/include/LowPtMuonLine.cuh"
#include "..//device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"
#include "..//device/PV/beamlinePV/include/pv_beamline_peak.cuh"
#include "..//device/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"
#include "..//host/prefix_sum/include/HostPrefixSum.h"

struct initialize_event_lists__host_event_list_output_t : host_init_event_list::Parameters::host_event_list_output_t {
  using type = host_init_event_list::Parameters::host_event_list_output_t::type;
  using deps = host_init_event_list::Parameters::host_event_list_output_t::deps;
};
struct initialize_event_lists__dev_event_list_output_t
  : host_init_event_list::Parameters::dev_event_list_output_t,
    velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
    velo_estimate_input_size::Parameters::dev_event_list_t,
    velo_masked_clustering::Parameters::dev_event_list_t,
    velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
    velo_search_by_triplet::Parameters::dev_event_list_t,
    velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
    beam_crossing_line::Parameters::dev_event_list_t,
    velo_micro_bias_line::Parameters::dev_event_list_t,
    odin_event_type_line::Parameters::dev_event_list_t,
    passthrough_line::Parameters::dev_event_list_t {
  using type = host_init_event_list::Parameters::dev_event_list_output_t::type;
  using deps = host_init_event_list::Parameters::dev_event_list_output_t::deps;
};
struct mep_layout__host_mep_layout_t : layout_provider::Parameters::host_mep_layout_t {
  using type = layout_provider::Parameters::host_mep_layout_t::type;
  using deps = layout_provider::Parameters::host_mep_layout_t::deps;
};
struct mep_layout__dev_mep_layout_t : layout_provider::Parameters::dev_mep_layout_t,
                                      track_mva_line::Parameters::dev_mep_layout_t,
                                      two_track_mva_line::Parameters::dev_mep_layout_t,
                                      two_track_catboost_line::Parameters::dev_mep_layout_t,
                                      single_high_pt_muon_line::Parameters::dev_mep_layout_t,
                                      low_pt_muon_line::Parameters::dev_mep_layout_t,
                                      d2kk_line::Parameters::dev_mep_layout_t,
                                      d2kpi_line::Parameters::dev_mep_layout_t,
                                      d2pipi_line::Parameters::dev_mep_layout_t,
                                      di_muon_mass_line::Parameters::dev_mep_layout_t,
                                      di_muon_soft_line::Parameters::dev_mep_layout_t,
                                      low_pt_di_muon_line::Parameters::dev_mep_layout_t,
                                      track_muon_mva_line::Parameters::dev_mep_layout_t,
                                      passthrough_line::Parameters::dev_mep_layout_t,
                                      beam_crossing_line::Parameters::dev_mep_layout_t,
                                      velo_micro_bias_line::Parameters::dev_mep_layout_t,
                                      odin_event_type_line::Parameters::dev_mep_layout_t,
                                      gather_selections::Parameters::dev_mep_layout_t {
  using type = layout_provider::Parameters::dev_mep_layout_t::type;
  using deps = layout_provider::Parameters::dev_mep_layout_t::deps;
};
struct initialize_number_of_events__host_number_of_events_t
  : host_init_number_of_events::Parameters::host_number_of_events_t,
    ut_calculate_number_of_hits::Parameters::host_number_of_events_t,
    ut_pre_decode::Parameters::host_number_of_events_t,
    ut_find_permutation::Parameters::host_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::host_number_of_events_t,
    scifi_calculate_cluster_count_v4::Parameters::host_number_of_events_t,
    scifi_pre_decode_v4::Parameters::host_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::host_number_of_events_t,
    muon_calculate_srq_size::Parameters::host_number_of_events_t,
    muon_populate_tile_and_tdc::Parameters::host_number_of_events_t,
    muon_add_coords_crossing_maps::Parameters::host_number_of_events_t,
    muon_populate_hits::Parameters::host_number_of_events_t,
    velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
    velo_estimate_input_size::Parameters::host_number_of_events_t,
    velo_masked_clustering::Parameters::host_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
    velo_search_by_triplet::Parameters::host_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
    velo_copy_track_hit_number::Parameters::host_number_of_events_t,
    velo_consolidate_tracks::Parameters::host_number_of_events_t,
    velo_kalman_filter::Parameters::host_number_of_events_t,
    ut_select_velo_tracks::Parameters::host_number_of_events_t,
    pv_beamline_extrapolate::Parameters::host_number_of_events_t,
    pv_beamline_histo::Parameters::host_number_of_events_t,
    ut_search_windows::Parameters::host_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_events_t,
    compass_ut::Parameters::host_number_of_events_t,
    ut_copy_track_hit_number::Parameters::host_number_of_events_t,
    ut_consolidate_tracks::Parameters::host_number_of_events_t,
    lf_search_initial_windows::Parameters::host_number_of_events_t,
    pv_beamline_peak::Parameters::host_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_events_t,
    pv_beamline_cleanup::Parameters::host_number_of_events_t,
    velo_pv_ip::Parameters::host_number_of_events_t,
    lf_triplet_seeding::Parameters::host_number_of_events_t,
    lf_create_tracks::Parameters::host_number_of_events_t,
    lf_quality_filter_length::Parameters::host_number_of_events_t,
    lf_quality_filter::Parameters::host_number_of_events_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_events_t,
    scifi_consolidate_tracks::Parameters::host_number_of_events_t,
    is_muon::Parameters::host_number_of_events_t,
    kalman_velo_only::Parameters::host_number_of_events_t,
    FilterTracks::Parameters::host_number_of_events_t,
    VertexFit::Parameters::host_number_of_events_t,
    two_track_preprocess::Parameters::host_number_of_selected_events_t,
    track_mva_line::Parameters::host_number_of_events_t,
    two_track_mva_line::Parameters::host_number_of_events_t,
    two_track_catboost_line::Parameters::host_number_of_events_t,
    single_high_pt_muon_line::Parameters::host_number_of_events_t,
    low_pt_muon_line::Parameters::host_number_of_events_t,
    d2kk_line::Parameters::host_number_of_events_t,
    d2kpi_line::Parameters::host_number_of_events_t,
    d2pipi_line::Parameters::host_number_of_events_t,
    di_muon_mass_line::Parameters::host_number_of_events_t,
    di_muon_soft_line::Parameters::host_number_of_events_t,
    low_pt_di_muon_line::Parameters::host_number_of_events_t,
    track_muon_mva_line::Parameters::host_number_of_events_t,
    passthrough_line::Parameters::host_number_of_events_t,
    beam_crossing_line::Parameters::host_number_of_events_t,
    velo_micro_bias_line::Parameters::host_number_of_events_t,
    odin_event_type_line::Parameters::host_number_of_events_t,
    gather_selections::Parameters::host_number_of_events_t,
    dec_reporter::Parameters::host_number_of_events_t {
  using type = host_init_number_of_events::Parameters::host_number_of_events_t::type;
  using deps = host_init_number_of_events::Parameters::host_number_of_events_t::deps;
};
struct initialize_number_of_events__dev_number_of_events_t
  : host_init_number_of_events::Parameters::dev_number_of_events_t,
    ut_pre_decode::Parameters::dev_number_of_events_t,
    ut_find_permutation::Parameters::dev_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::dev_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::dev_number_of_events_t,
    muon_populate_hits::Parameters::dev_number_of_events_t,
    velo_masked_clustering::Parameters::dev_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
    velo_search_by_triplet::Parameters::dev_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
    velo_consolidate_tracks::Parameters::dev_number_of_events_t,
    velo_kalman_filter::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks::Parameters::dev_number_of_events_t,
    pv_beamline_extrapolate::Parameters::dev_number_of_events_t,
    pv_beamline_histo::Parameters::dev_number_of_events_t,
    ut_search_windows::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_number_of_events_t,
    compass_ut::Parameters::dev_number_of_events_t,
    ut_consolidate_tracks::Parameters::dev_number_of_events_t,
    lf_search_initial_windows::Parameters::dev_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::dev_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::dev_number_of_events_t,
    velo_pv_ip::Parameters::dev_number_of_events_t,
    lf_triplet_seeding::Parameters::dev_number_of_events_t,
    lf_create_tracks::Parameters::dev_number_of_events_t,
    lf_quality_filter_length::Parameters::dev_number_of_events_t,
    lf_quality_filter::Parameters::dev_number_of_events_t,
    scifi_consolidate_tracks::Parameters::dev_number_of_events_t,
    is_muon::Parameters::dev_number_of_events_t,
    kalman_velo_only::Parameters::dev_number_of_events_t,
    FilterTracks::Parameters::dev_number_of_events_t,
    VertexFit::Parameters::dev_number_of_events_t,
    passthrough_line::Parameters::dev_number_of_events_t,
    velo_micro_bias_line::Parameters::dev_number_of_events_t {
  using type = host_init_number_of_events::Parameters::dev_number_of_events_t::type;
  using deps = host_init_number_of_events::Parameters::dev_number_of_events_t::deps;
};
struct host_scifi_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                            host_global_event_cut::Parameters::host_scifi_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  using deps = host_data_provider::Parameters::host_raw_banks_t::deps;
};
struct host_scifi_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                              host_global_event_cut::Parameters::host_scifi_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  using deps = host_data_provider::Parameters::host_raw_offsets_t::deps;
};
struct host_scifi_banks__host_raw_bank_version_t : host_data_provider::Parameters::host_raw_bank_version_t,
                                                   host_global_event_cut::Parameters::host_ut_raw_bank_version_t {
  using type = host_data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = host_data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct host_ut_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                         host_global_event_cut::Parameters::host_ut_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  using deps = host_data_provider::Parameters::host_raw_banks_t::deps;
};
struct host_ut_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                           host_global_event_cut::Parameters::host_ut_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  using deps = host_data_provider::Parameters::host_raw_offsets_t::deps;
};
struct host_ut_banks__host_raw_bank_version_t : host_data_provider::Parameters::host_raw_bank_version_t {
  using type = host_data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = host_data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct gec__host_event_list_output_t : host_global_event_cut::Parameters::host_event_list_output_t {
  using type = host_global_event_cut::Parameters::host_event_list_output_t::type;
  using deps = host_global_event_cut::Parameters::host_event_list_output_t::deps;
};
struct gec__host_number_of_events_t : host_global_event_cut::Parameters::host_number_of_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_events_t::type;
  using deps = host_global_event_cut::Parameters::host_number_of_events_t::deps;
};
struct gec__host_number_of_selected_events_t : host_global_event_cut::Parameters::host_number_of_selected_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_selected_events_t::type;
  using deps = host_global_event_cut::Parameters::host_number_of_selected_events_t::deps;
};
struct gec__dev_number_of_events_t : host_global_event_cut::Parameters::dev_number_of_events_t {
  using type = host_global_event_cut::Parameters::dev_number_of_events_t::type;
  using deps = host_global_event_cut::Parameters::dev_number_of_events_t::deps;
};
struct gec__dev_event_list_output_t : host_global_event_cut::Parameters::dev_event_list_output_t,
                                      ut_calculate_number_of_hits::Parameters::dev_event_list_t,
                                      ut_pre_decode::Parameters::dev_event_list_t,
                                      ut_find_permutation::Parameters::dev_event_list_t,
                                      ut_decode_raw_banks_in_order::Parameters::dev_event_list_t,
                                      scifi_calculate_cluster_count_v4::Parameters::dev_event_list_t,
                                      scifi_pre_decode_v4::Parameters::dev_event_list_t,
                                      scifi_raw_bank_decoder_v4::Parameters::dev_event_list_t,
                                      muon_calculate_srq_size::Parameters::dev_event_list_t,
                                      muon_populate_tile_and_tdc::Parameters::dev_event_list_t,
                                      muon_add_coords_crossing_maps::Parameters::dev_event_list_t,
                                      muon_populate_hits::Parameters::dev_event_list_t,
                                      velo_consolidate_tracks::Parameters::dev_event_list_t,
                                      velo_kalman_filter::Parameters::dev_event_list_t,
                                      ut_select_velo_tracks::Parameters::dev_event_list_t,
                                      pv_beamline_extrapolate::Parameters::dev_event_list_t,
                                      pv_beamline_histo::Parameters::dev_event_list_t,
                                      ut_search_windows::Parameters::dev_event_list_t,
                                      ut_select_velo_tracks_with_windows::Parameters::dev_event_list_t,
                                      compass_ut::Parameters::dev_event_list_t,
                                      ut_consolidate_tracks::Parameters::dev_event_list_t,
                                      lf_search_initial_windows::Parameters::dev_event_list_t,
                                      pv_beamline_peak::Parameters::dev_event_list_t,
                                      pv_beamline_calculate_denom::Parameters::dev_event_list_t,
                                      pv_beamline_multi_fitter::Parameters::dev_event_list_t,
                                      pv_beamline_cleanup::Parameters::dev_event_list_t,
                                      velo_pv_ip::Parameters::dev_event_list_t,
                                      lf_triplet_seeding::Parameters::dev_event_list_t,
                                      lf_create_tracks::Parameters::dev_event_list_t,
                                      lf_quality_filter_length::Parameters::dev_event_list_t,
                                      lf_quality_filter::Parameters::dev_event_list_t,
                                      scifi_consolidate_tracks::Parameters::dev_event_list_t,
                                      is_muon::Parameters::dev_event_list_t,
                                      kalman_velo_only::Parameters::dev_event_list_t,
                                      FilterTracks::Parameters::dev_event_list_t,
                                      VertexFit::Parameters::dev_event_list_t,
                                      two_track_preprocess::Parameters::dev_event_list_t,
                                      track_mva_line::Parameters::dev_event_list_t,
                                      two_track_mva_line::Parameters::dev_event_list_t,
                                      two_track_catboost_line::Parameters::dev_event_list_t,
                                      single_high_pt_muon_line::Parameters::dev_event_list_t,
                                      low_pt_muon_line::Parameters::dev_event_list_t,
                                      d2kk_line::Parameters::dev_event_list_t,
                                      d2kpi_line::Parameters::dev_event_list_t,
                                      d2pipi_line::Parameters::dev_event_list_t,
                                      di_muon_mass_line::Parameters::dev_event_list_t,
                                      di_muon_soft_line::Parameters::dev_event_list_t,
                                      low_pt_di_muon_line::Parameters::dev_event_list_t,
                                      track_muon_mva_line::Parameters::dev_event_list_t,
                                      passthrough_line::Parameters::dev_event_list_t {
  using type = host_global_event_cut::Parameters::dev_event_list_output_t::type;
  using deps = host_global_event_cut::Parameters::dev_event_list_output_t::deps;
};
struct ut_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                   ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_t,
                                   ut_pre_decode::Parameters::dev_ut_raw_input_t,
                                   ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct ut_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                     ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_pre_decode::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct ut_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t,
                                           ut_calculate_number_of_hits::Parameters::host_raw_bank_version_t,
                                           ut_pre_decode::Parameters::host_raw_bank_version_t,
                                           ut_decode_raw_banks_in_order::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct ut_calculate_number_of_hits__dev_ut_hit_sizes_t : ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t,
                                                         host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t::type;
  using deps = ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t::deps;
};
struct prefix_sum_ut_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_pre_decode::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_find_permutation::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_decode_raw_banks_in_order::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_ut_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_ut_hits__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_ut_hits__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                 ut_pre_decode::Parameters::dev_ut_hit_offsets_t,
                                                 ut_find_permutation::Parameters::dev_ut_hit_offsets_t,
                                                 ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_offsets_t,
                                                 ut_search_windows::Parameters::dev_ut_hit_offsets_t,
                                                 compass_ut::Parameters::dev_ut_hit_offsets_t,
                                                 ut_consolidate_tracks::Parameters::dev_ut_hit_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct ut_pre_decode__dev_ut_pre_decoded_hits_t : ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_find_permutation::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_decode_raw_banks_in_order::Parameters::dev_ut_pre_decoded_hits_t {
  using type = ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t::type;
  using deps = ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t::deps;
};
struct ut_pre_decode__dev_ut_hit_count_t : ut_pre_decode::Parameters::dev_ut_hit_count_t {
  using type = ut_pre_decode::Parameters::dev_ut_hit_count_t::type;
  using deps = ut_pre_decode::Parameters::dev_ut_hit_count_t::deps;
};
struct ut_find_permutation__dev_ut_hit_permutations_t
  : ut_find_permutation::Parameters::dev_ut_hit_permutations_t,
    ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_permutations_t {
  using type = ut_find_permutation::Parameters::dev_ut_hit_permutations_t::type;
  using deps = ut_find_permutation::Parameters::dev_ut_hit_permutations_t::deps;
};
struct ut_decode_raw_banks_in_order__dev_ut_hits_t : ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t,
                                                     ut_search_windows::Parameters::dev_ut_hits_t,
                                                     compass_ut::Parameters::dev_ut_hits_t,
                                                     ut_consolidate_tracks::Parameters::dev_ut_hits_t {
  using type = ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t::type;
  using deps = ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t::deps;
};
struct scifi_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                      scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct scifi_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                        scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct scifi_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct scifi_calculate_cluster_count__dev_scifi_hit_count_t
  : scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t::type;
  using deps = scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t::deps;
};
struct prefix_sum_scifi_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_pre_decode_v4::Parameters::host_accumulated_number_of_scifi_hits_t,
    scifi_raw_bank_decoder_v4::Parameters::host_accumulated_number_of_scifi_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_scifi_hits__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_scifi_hits__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                    scifi_pre_decode_v4::Parameters::dev_scifi_hit_offsets_t,
                                                    scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_search_initial_windows::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_triplet_seeding::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_create_tracks::Parameters::dev_scifi_hit_offsets_t,
                                                    lf_quality_filter::Parameters::dev_scifi_hit_offsets_t,
                                                    scifi_consolidate_tracks::Parameters::dev_scifi_hit_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct scifi_pre_decode__dev_cluster_references_t : scifi_pre_decode_v4::Parameters::dev_cluster_references_t,
                                                    scifi_raw_bank_decoder_v4::Parameters::dev_cluster_references_t {
  using type = scifi_pre_decode_v4::Parameters::dev_cluster_references_t::type;
  using deps = scifi_pre_decode_v4::Parameters::dev_cluster_references_t::deps;
};
struct scifi_raw_bank_decoder__dev_scifi_hits_t : scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t,
                                                  lf_search_initial_windows::Parameters::dev_scifi_hits_t,
                                                  lf_triplet_seeding::Parameters::dev_scifi_hits_t,
                                                  lf_create_tracks::Parameters::dev_scifi_hits_t,
                                                  lf_quality_filter::Parameters::dev_scifi_hits_t,
                                                  scifi_consolidate_tracks::Parameters::dev_scifi_hits_t {
  using type = scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t::type;
  using deps = scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t::deps;
};
struct muon_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     muon_calculate_srq_size::Parameters::dev_muon_raw_t,
                                     muon_populate_tile_and_tdc::Parameters::dev_muon_raw_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct muon_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       muon_calculate_srq_size::Parameters::dev_muon_raw_offsets_t,
                                       muon_populate_tile_and_tdc::Parameters::dev_muon_raw_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct muon_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct muon_calculate_srq_size__dev_muon_raw_to_hits_t
  : muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_tile_and_tdc::Parameters::dev_muon_raw_to_hits_t,
    muon_add_coords_crossing_maps::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_hits::Parameters::dev_muon_raw_to_hits_t {
  using type = muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t::type;
  using deps = muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t::deps;
};
struct muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t
  : muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t::type;
  using deps = muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t::deps;
};
struct muon_srq_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_tile_and_tdc::Parameters::host_muon_total_number_of_tiles_t,
    muon_add_coords_crossing_maps::Parameters::host_muon_total_number_of_tiles_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct muon_srq_prefix_sum__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct muon_srq_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_tile_and_tdc::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_populate_hits::Parameters::dev_storage_station_region_quarter_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct muon_populate_tile_and_tdc__dev_storage_tile_id_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_tile_id_t,
    muon_populate_hits::Parameters::dev_storage_tile_id_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t::type;
  using deps = muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t::deps;
};
struct muon_populate_tile_and_tdc__dev_storage_tdc_value_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t,
    muon_populate_hits::Parameters::dev_storage_tdc_value_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t::type;
  using deps = muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t::deps;
};
struct muon_populate_tile_and_tdc__dev_atomics_muon_t : muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t::type;
  using deps = muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t::deps;
};
struct muon_add_coords_crossing_maps__dev_atomics_index_insert_t
  : muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t::type;
  using deps = muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t::deps;
};
struct muon_add_coords_crossing_maps__dev_muon_compact_hit_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t,
    muon_populate_hits::Parameters::dev_muon_compact_hit_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t::type;
  using deps = muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t::deps;
};
struct muon_add_coords_crossing_maps__dev_muon_tile_used_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t::type;
  using deps = muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t::deps;
};
struct muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t
  : muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t::type;
  using deps = muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t::deps;
};
struct muon_station_ocurrence_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_hits::Parameters::host_muon_total_number_of_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct muon_station_ocurrence_prefix_sum__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct muon_station_ocurrence_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_hits::Parameters::dev_station_ocurrences_offset_t,
    is_muon::Parameters::dev_station_ocurrences_offset_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct muon_populate_hits__dev_permutation_station_t : muon_populate_hits::Parameters::dev_permutation_station_t {
  using type = muon_populate_hits::Parameters::dev_permutation_station_t::type;
  using deps = muon_populate_hits::Parameters::dev_permutation_station_t::deps;
};
struct muon_populate_hits__dev_muon_hits_t : muon_populate_hits::Parameters::dev_muon_hits_t,
                                             is_muon::Parameters::dev_muon_hits_t {
  using type = muon_populate_hits::Parameters::dev_muon_hits_t::type;
  using deps = muon_populate_hits::Parameters::dev_muon_hits_t::deps;
};
struct velo_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
                                     velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
                                     velo_masked_clustering::Parameters::dev_velo_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct velo_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct velo_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct velo_calculate_number_of_candidates__dev_number_of_candidates_t
  : velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::type;
  using deps = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::deps;
};
struct prefix_sum_offsets_velo_candidates__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_candidates__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_candidates__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
    velo_masked_clustering::Parameters::dev_candidates_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_estimate_input_size__dev_estimated_input_size_t
  : velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::deps;
};
struct velo_estimate_input_size__dev_module_candidate_num_t
  : velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
    velo_masked_clustering::Parameters::dev_module_candidate_num_t {
  using type = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::deps;
};
struct velo_estimate_input_size__dev_cluster_candidates_t
  : velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
    velo_masked_clustering::Parameters::dev_cluster_candidates_t {
  using type = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::type;
  using deps = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
    velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
    velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_estimated_input_size__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
    velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
    velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
    velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
    velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_masked_clustering__dev_module_cluster_num_t
  : velo_masked_clustering::Parameters::dev_module_cluster_num_t,
    velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
    velo_search_by_triplet::Parameters::dev_module_cluster_num_t {
  using type = velo_masked_clustering::Parameters::dev_module_cluster_num_t::type;
  using deps = velo_masked_clustering::Parameters::dev_module_cluster_num_t::deps;
};
struct velo_masked_clustering__dev_velo_cluster_container_t
  : velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
    velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t {
  using type = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::type;
  using deps = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::deps;
};
struct velo_masked_clustering__dev_velo_clusters_t : velo_masked_clustering::Parameters::dev_velo_clusters_t,
                                                     velo_calculate_phi_and_sort::Parameters::dev_velo_clusters_t,
                                                     velo_search_by_triplet::Parameters::dev_velo_clusters_t {
  using type = velo_masked_clustering::Parameters::dev_velo_clusters_t::type;
  using deps = velo_masked_clustering::Parameters::dev_velo_clusters_t::deps;
};
struct velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t
  : velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
    velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
    velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
    velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::deps;
};
struct velo_calculate_phi_and_sort__dev_hit_permutation_t
  : velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::deps;
};
struct velo_calculate_phi_and_sort__dev_hit_phi_t : velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
                                                    velo_search_by_triplet::Parameters::dev_hit_phi_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::type;
  using deps = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::deps;
};
struct velo_search_by_triplet__dev_tracks_t : velo_search_by_triplet::Parameters::dev_tracks_t,
                                              velo_copy_track_hit_number::Parameters::dev_tracks_t,
                                              velo_consolidate_tracks::Parameters::dev_tracks_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracks_t::deps;
};
struct velo_search_by_triplet__dev_tracklets_t : velo_search_by_triplet::Parameters::dev_tracklets_t {
  using type = velo_search_by_triplet::Parameters::dev_tracklets_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracklets_t::deps;
};
struct velo_search_by_triplet__dev_tracks_to_follow_t : velo_search_by_triplet::Parameters::dev_tracks_to_follow_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::deps;
};
struct velo_search_by_triplet__dev_three_hit_tracks_t
  : velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
    velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t {
  using type = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::deps;
};
struct velo_search_by_triplet__dev_hit_used_t : velo_search_by_triplet::Parameters::dev_hit_used_t,
                                                velo_three_hit_tracks_filter::Parameters::dev_hit_used_t {
  using type = velo_search_by_triplet::Parameters::dev_hit_used_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_hit_used_t::deps;
};
struct velo_search_by_triplet__dev_atomics_velo_t : velo_search_by_triplet::Parameters::dev_atomics_velo_t,
                                                    velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t {
  using type = velo_search_by_triplet::Parameters::dev_atomics_velo_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_atomics_velo_t::deps;
};
struct velo_search_by_triplet__dev_rel_indices_t : velo_search_by_triplet::Parameters::dev_rel_indices_t {
  using type = velo_search_by_triplet::Parameters::dev_rel_indices_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_rel_indices_t::deps;
};
struct velo_search_by_triplet__dev_number_of_velo_tracks_t
  : velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::type;
  using deps = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::deps;
};
struct velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
    velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::type;
  using deps = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::deps;
};
struct velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::type;
  using deps = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_kalman_filter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_search_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_pv_ip::Parameters::host_number_of_reconstructed_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::type;
  using deps = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::deps;
};
struct velo_copy_track_hit_number__dev_velo_track_hit_number_t
  : velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::type;
  using deps = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::deps;
};
struct velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
    velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    velo_kalman_filter::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_histo::Parameters::dev_offsets_all_velo_tracks_t,
    ut_search_windows::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_all_velo_tracks_t,
    compass_ut::Parameters::dev_offsets_all_velo_tracks_t,
    lf_search_initial_windows::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_all_velo_tracks_t,
    velo_pv_ip::Parameters::dev_offsets_all_velo_tracks_t,
    lf_triplet_seeding::Parameters::dev_offsets_all_velo_tracks_t,
    lf_create_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    kalman_velo_only::Parameters::dev_offsets_all_velo_tracks_t,
    two_track_preprocess::Parameters::dev_offsets_all_velo_tracks_t,
    velo_micro_bias_line::Parameters::dev_offsets_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::type;
  using deps = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t
  : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_kalman_filter::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_histo::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_search_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    compass_ut::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_search_initial_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_pv_ip::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_create_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    kalman_velo_only::Parameters::dev_offsets_velo_track_hit_number_t,
    two_track_preprocess::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_micro_bias_line::Parameters::dev_offsets_velo_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct velo_consolidate_tracks__dev_accepted_velo_tracks_t
  : velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_accepted_velo_tracks_t {
  using type = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::type;
  using deps = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::deps;
};
struct velo_consolidate_tracks__dev_velo_track_hits_t : velo_consolidate_tracks::Parameters::dev_velo_track_hits_t,
                                                        velo_kalman_filter::Parameters::dev_velo_track_hits_t,
                                                        ut_select_velo_tracks::Parameters::dev_velo_track_hits_t,
                                                        kalman_velo_only::Parameters::dev_velo_track_hits_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::type;
  using deps = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::deps;
};
struct velo_kalman_filter__dev_velo_kalman_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t,
    ut_select_velo_tracks::Parameters::dev_velo_states_t,
    pv_beamline_extrapolate::Parameters::dev_velo_kalman_beamline_states_t,
    velo_pv_ip::Parameters::dev_velo_kalman_beamline_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t::type;
  using deps = velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t::deps;
};
struct velo_kalman_filter__dev_velo_kalman_endvelo_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t,
    ut_search_windows::Parameters::dev_velo_states_t,
    lf_search_initial_windows::Parameters::dev_velo_states_t,
    lf_triplet_seeding::Parameters::dev_velo_states_t,
    lf_create_tracks::Parameters::dev_velo_states_t,
    scifi_consolidate_tracks::Parameters::dev_velo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t::type;
  using deps = velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t::deps;
};
struct velo_kalman_filter__dev_velo_lmsfit_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t,
    compass_ut::Parameters::dev_velo_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t::type;
  using deps = velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t::deps;
};
struct ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t::type;
  using deps = ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t::deps;
};
struct ut_select_velo_tracks__dev_ut_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t::type;
  using deps = ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t::deps;
};
struct pv_beamline_extrapolate__dev_pvtracks_t : pv_beamline_extrapolate::Parameters::dev_pvtracks_t,
                                                 pv_beamline_histo::Parameters::dev_pvtracks_t,
                                                 pv_beamline_calculate_denom::Parameters::dev_pvtracks_t,
                                                 pv_beamline_multi_fitter::Parameters::dev_pvtracks_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtracks_t::type;
  using deps = pv_beamline_extrapolate::Parameters::dev_pvtracks_t::deps;
};
struct pv_beamline_extrapolate__dev_pvtrack_z_t : pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_pvtrack_z_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t::type;
  using deps = pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t::deps;
};
struct pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t
  : pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t::type;
  using deps = pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t::deps;
};
struct pv_beamline_histo__dev_zhisto_t : pv_beamline_histo::Parameters::dev_zhisto_t,
                                         pv_beamline_peak::Parameters::dev_zhisto_t {
  using type = pv_beamline_histo::Parameters::dev_zhisto_t::type;
  using deps = pv_beamline_histo::Parameters::dev_zhisto_t::deps;
};
struct ut_search_windows__dev_ut_windows_layers_t
  : ut_search_windows::Parameters::dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_windows_layers_t,
    compass_ut::Parameters::dev_ut_windows_layers_t {
  using type = ut_search_windows::Parameters::dev_ut_windows_layers_t::type;
  using deps = ut_search_windows::Parameters::dev_ut_windows_layers_t::deps;
};
struct ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t {
  using type =
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t::type;
  using deps =
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t::deps;
};
struct ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_selected_velo_tracks_with_windows_t {
  using type = ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t::type;
  using deps = ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t::deps;
};
struct compass_ut__dev_ut_tracks_t : compass_ut::Parameters::dev_ut_tracks_t,
                                     ut_copy_track_hit_number::Parameters::dev_ut_tracks_t,
                                     ut_consolidate_tracks::Parameters::dev_ut_tracks_t {
  using type = compass_ut::Parameters::dev_ut_tracks_t::type;
  using deps = compass_ut::Parameters::dev_ut_tracks_t::deps;
};
struct compass_ut__dev_atomics_ut_t : compass_ut::Parameters::dev_atomics_ut_t,
                                      host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = compass_ut::Parameters::dev_atomics_ut_t::type;
  using deps = compass_ut::Parameters::dev_atomics_ut_t::deps;
};
struct prefix_sum_ut_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_copy_track_hit_number::Parameters::host_number_of_reconstructed_ut_tracks_t,
    ut_consolidate_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_search_initial_windows::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_triplet_seeding::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_create_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_quality_filter_length::Parameters::host_number_of_reconstructed_ut_tracks_t,
    lf_quality_filter::Parameters::host_number_of_reconstructed_ut_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_ut_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_ut_tracks__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                   ut_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
                                                   ut_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_search_initial_windows::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_triplet_seeding::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_create_tracks::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_quality_filter_length::Parameters::dev_offsets_ut_tracks_t,
                                                   lf_quality_filter::Parameters::dev_offsets_ut_tracks_t,
                                                   scifi_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
                                                   scifi_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t,
                                                   kalman_velo_only::Parameters::dev_offsets_ut_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct ut_copy_track_hit_number__dev_ut_track_hit_number_t
  : ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t::type;
  using deps = ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t::deps;
};
struct prefix_sum_ut_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_ut_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_ut_track_hit_number__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_ut_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    ut_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_search_initial_windows::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_triplet_seeding::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_create_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_quality_filter_length::Parameters::dev_offsets_ut_track_hit_number_t,
    lf_quality_filter::Parameters::dev_offsets_ut_track_hit_number_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
    kalman_velo_only::Parameters::dev_offsets_ut_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct ut_consolidate_tracks__dev_ut_track_hits_t : ut_consolidate_tracks::Parameters::dev_ut_track_hits_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_hits_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_track_hits_t::deps;
};
struct ut_consolidate_tracks__dev_ut_qop_t : ut_consolidate_tracks::Parameters::dev_ut_qop_t,
                                             lf_search_initial_windows::Parameters::dev_ut_qop_t,
                                             lf_triplet_seeding::Parameters::dev_ut_qop_t,
                                             lf_create_tracks::Parameters::dev_ut_qop_t,
                                             scifi_consolidate_tracks::Parameters::dev_ut_qop_t,
                                             kalman_velo_only::Parameters::dev_ut_qop_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_qop_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_qop_t::deps;
};
struct ut_consolidate_tracks__dev_ut_x_t : ut_consolidate_tracks::Parameters::dev_ut_x_t,
                                           lf_search_initial_windows::Parameters::dev_ut_x_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_x_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_x_t::deps;
};
struct ut_consolidate_tracks__dev_ut_tx_t : ut_consolidate_tracks::Parameters::dev_ut_tx_t,
                                            lf_search_initial_windows::Parameters::dev_ut_tx_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_tx_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_tx_t::deps;
};
struct ut_consolidate_tracks__dev_ut_z_t : ut_consolidate_tracks::Parameters::dev_ut_z_t,
                                           lf_search_initial_windows::Parameters::dev_ut_z_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_z_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_z_t::deps;
};
struct ut_consolidate_tracks__dev_ut_track_velo_indices_t
  : ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
    lf_search_initial_windows::Parameters::dev_ut_track_velo_indices_t,
    lf_triplet_seeding::Parameters::dev_ut_track_velo_indices_t,
    lf_create_tracks::Parameters::dev_ut_track_velo_indices_t,
    scifi_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
    kalman_velo_only::Parameters::dev_ut_track_velo_indices_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t::type;
  using deps = ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t::deps;
};
struct lf_search_initial_windows__dev_scifi_lf_initial_windows_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_initial_windows_t,
    lf_create_tracks::Parameters::dev_scifi_lf_initial_windows_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t::type;
  using deps = lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t::deps;
};
struct lf_search_initial_windows__dev_ut_states_t : lf_search_initial_windows::Parameters::dev_ut_states_t,
                                                    lf_triplet_seeding::Parameters::dev_ut_states_t,
                                                    lf_create_tracks::Parameters::dev_ut_states_t,
                                                    lf_quality_filter::Parameters::dev_ut_states_t {
  using type = lf_search_initial_windows::Parameters::dev_ut_states_t::type;
  using deps = lf_search_initial_windows::Parameters::dev_ut_states_t::deps;
};
struct lf_search_initial_windows__dev_scifi_lf_process_track_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_process_track_t,
    lf_create_tracks::Parameters::dev_scifi_lf_process_track_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t::type;
  using deps = lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t::deps;
};
struct pv_beamline_peak__dev_zpeaks_t : pv_beamline_peak::Parameters::dev_zpeaks_t,
                                        pv_beamline_calculate_denom::Parameters::dev_zpeaks_t,
                                        pv_beamline_multi_fitter::Parameters::dev_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_zpeaks_t::type;
  using deps = pv_beamline_peak::Parameters::dev_zpeaks_t::deps;
};
struct pv_beamline_peak__dev_number_of_zpeaks_t : pv_beamline_peak::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_calculate_denom::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_number_of_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_number_of_zpeaks_t::type;
  using deps = pv_beamline_peak::Parameters::dev_number_of_zpeaks_t::deps;
};
struct pv_beamline_calculate_denom__dev_pvtracks_denom_t
  : pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t,
    pv_beamline_multi_fitter::Parameters::dev_pvtracks_denom_t {
  using type = pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t::type;
  using deps = pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t::deps;
};
struct pv_beamline_multi_fitter__dev_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t::type;
  using deps = pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t::deps;
};
struct pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_number_of_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t::type;
  using deps = pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t::deps;
};
struct pv_beamline_cleanup__dev_multi_final_vertices_t : pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t,
                                                         velo_pv_ip::Parameters::dev_multi_final_vertices_t,
                                                         kalman_velo_only::Parameters::dev_multi_final_vertices_t,
                                                         FilterTracks::Parameters::dev_multi_final_vertices_t,
                                                         VertexFit::Parameters::dev_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t::type;
  using deps = pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t::deps;
};
struct pv_beamline_cleanup__dev_number_of_multi_final_vertices_t
  : pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t,
    velo_pv_ip::Parameters::dev_number_of_multi_final_vertices_t,
    kalman_velo_only::Parameters::dev_number_of_multi_final_vertices_t,
    FilterTracks::Parameters::dev_number_of_multi_final_vertices_t,
    VertexFit::Parameters::dev_number_of_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t::type;
  using deps = pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t::deps;
};
struct velo_pv_ip__dev_velo_pv_ip_t : velo_pv_ip::Parameters::dev_velo_pv_ip_t,
                                      kalman_velo_only::Parameters::dev_velo_pv_ip_t {
  using type = velo_pv_ip::Parameters::dev_velo_pv_ip_t::type;
  using deps = velo_pv_ip::Parameters::dev_velo_pv_ip_t::deps;
};
struct lf_triplet_seeding__dev_scifi_lf_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t::type;
  using deps = lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t::deps;
};
struct lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_number_of_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t::type;
  using deps = lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t::deps;
};
struct lf_create_tracks__dev_scifi_lf_tracks_t : lf_create_tracks::Parameters::dev_scifi_lf_tracks_t,
                                                 lf_quality_filter_length::Parameters::dev_scifi_lf_tracks_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_tracks_t::type;
  using deps = lf_create_tracks::Parameters::dev_scifi_lf_tracks_t::deps;
};
struct lf_create_tracks__dev_scifi_lf_atomics_t : lf_create_tracks::Parameters::dev_scifi_lf_atomics_t,
                                                  lf_quality_filter_length::Parameters::dev_scifi_lf_atomics_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_atomics_t::type;
  using deps = lf_create_tracks::Parameters::dev_scifi_lf_atomics_t::deps;
};
struct lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t
  : lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t::type;
  using deps = lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t::deps;
};
struct lf_create_tracks__dev_scifi_lf_parametrization_t
  : lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t,
    lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t::type;
  using deps = lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t::deps;
};
struct lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_tracks_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t::type;
  using deps = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t::deps;
};
struct lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_atomics_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t::type;
  using deps = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t::deps;
};
struct lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t,
    lf_quality_filter::Parameters::dev_scifi_lf_parametrization_length_filter_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t::type;
  using deps = lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t::deps;
};
struct lf_quality_filter__dev_lf_quality_of_tracks_t : lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t {
  using type = lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t::type;
  using deps = lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t::deps;
};
struct lf_quality_filter__dev_atomics_scifi_t : lf_quality_filter::Parameters::dev_atomics_scifi_t,
                                                host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = lf_quality_filter::Parameters::dev_atomics_scifi_t::type;
  using deps = lf_quality_filter::Parameters::dev_atomics_scifi_t::deps;
};
struct lf_quality_filter__dev_scifi_tracks_t : lf_quality_filter::Parameters::dev_scifi_tracks_t,
                                               scifi_copy_track_hit_number::Parameters::dev_scifi_tracks_t,
                                               scifi_consolidate_tracks::Parameters::dev_scifi_tracks_t {
  using type = lf_quality_filter::Parameters::dev_scifi_tracks_t::type;
  using deps = lf_quality_filter::Parameters::dev_scifi_tracks_t::deps;
};
struct lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t
  : lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t::type;
  using deps = lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t::deps;
};
struct lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t
  : lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks::Parameters::dev_scifi_lf_parametrization_consolidate_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t::type;
  using deps = lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t::deps;
};
struct prefix_sum_forward_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    scifi_consolidate_tracks::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    is_muon::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    kalman_velo_only::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    track_mva_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    single_high_pt_muon_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    low_pt_muon_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    track_muon_mva_line::Parameters::host_number_of_reconstructed_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_forward_tracks__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_forward_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_copy_track_hit_number::Parameters::dev_offsets_forward_tracks_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_forward_tracks_t,
    is_muon::Parameters::dev_offsets_forward_tracks_t,
    kalman_velo_only::Parameters::dev_offsets_forward_tracks_t,
    FilterTracks::Parameters::dev_offsets_forward_tracks_t,
    VertexFit::Parameters::dev_offsets_forward_tracks_t,
    track_mva_line::Parameters::dev_track_offsets_t,
    single_high_pt_muon_line::Parameters::dev_track_offsets_t,
    low_pt_muon_line::Parameters::dev_track_offsets_t,
    track_muon_mva_line::Parameters::dev_track_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct scifi_copy_track_hit_number__dev_scifi_track_hit_number_t
  : scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t::type;
  using deps = scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t::deps;
};
struct prefix_sum_scifi_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_scifi_track_hit_number__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_scifi_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_scifi_track_hit_number_t,
    is_muon::Parameters::dev_offsets_scifi_track_hit_number,
    kalman_velo_only::Parameters::dev_offsets_scifi_track_hit_number_t,
    FilterTracks::Parameters::dev_offsets_scifi_track_hit_number_t,
    VertexFit::Parameters::dev_offsets_scifi_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct scifi_consolidate_tracks__dev_scifi_track_hits_t : scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t::type;
  using deps = scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t::deps;
};
struct scifi_consolidate_tracks__dev_scifi_qop_t : scifi_consolidate_tracks::Parameters::dev_scifi_qop_t,
                                                   is_muon::Parameters::dev_scifi_qop_t,
                                                   kalman_velo_only::Parameters::dev_scifi_qop_t,
                                                   FilterTracks::Parameters::dev_scifi_qop_t,
                                                   VertexFit::Parameters::dev_scifi_qop_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_qop_t::type;
  using deps = scifi_consolidate_tracks::Parameters::dev_scifi_qop_t::deps;
};
struct scifi_consolidate_tracks__dev_scifi_states_t : scifi_consolidate_tracks::Parameters::dev_scifi_states_t,
                                                      is_muon::Parameters::dev_scifi_states_t,
                                                      kalman_velo_only::Parameters::dev_scifi_states_t,
                                                      FilterTracks::Parameters::dev_scifi_states_t,
                                                      VertexFit::Parameters::dev_scifi_states_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_states_t::type;
  using deps = scifi_consolidate_tracks::Parameters::dev_scifi_states_t::deps;
};
struct scifi_consolidate_tracks__dev_scifi_track_ut_indices_t
  : scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t,
    is_muon::Parameters::dev_scifi_track_ut_indices_t,
    kalman_velo_only::Parameters::dev_scifi_track_ut_indices_t,
    FilterTracks::Parameters::dev_scifi_track_ut_indices_t,
    VertexFit::Parameters::dev_scifi_track_ut_indices_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t::type;
  using deps = scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t::deps;
};
struct is_muon__dev_muon_track_occupancies_t : is_muon::Parameters::dev_muon_track_occupancies_t {
  using type = is_muon::Parameters::dev_muon_track_occupancies_t::type;
  using deps = is_muon::Parameters::dev_muon_track_occupancies_t::deps;
};
struct is_muon__dev_is_muon_t : is_muon::Parameters::dev_is_muon_t, kalman_velo_only::Parameters::dev_is_muon_t {
  using type = is_muon::Parameters::dev_is_muon_t::type;
  using deps = is_muon::Parameters::dev_is_muon_t::deps;
};
struct kalman_velo_only__dev_kf_tracks_t : kalman_velo_only::Parameters::dev_kf_tracks_t,
                                           FilterTracks::Parameters::dev_kf_tracks_t,
                                           VertexFit::Parameters::dev_kf_tracks_t,
                                           track_mva_line::Parameters::dev_tracks_t,
                                           single_high_pt_muon_line::Parameters::dev_tracks_t,
                                           low_pt_muon_line::Parameters::dev_tracks_t,
                                           track_muon_mva_line::Parameters::dev_tracks_t {
  using type = kalman_velo_only::Parameters::dev_kf_tracks_t::type;
  using deps = kalman_velo_only::Parameters::dev_kf_tracks_t::deps;
};
struct kalman_velo_only__dev_kalman_pv_ipchi2_t : kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t,
                                                  FilterTracks::Parameters::dev_kalman_pv_ipchi2_t,
                                                  VertexFit::Parameters::dev_kalman_pv_ipchi2_t {
  using type = kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t::type;
  using deps = kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t::deps;
};
struct filter_tracks__dev_sv_atomics_t : FilterTracks::Parameters::dev_sv_atomics_t,
                                         host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = FilterTracks::Parameters::dev_sv_atomics_t::type;
  using deps = FilterTracks::Parameters::dev_sv_atomics_t::deps;
};
struct filter_tracks__dev_svs_trk1_idx_t : FilterTracks::Parameters::dev_svs_trk1_idx_t,
                                           VertexFit::Parameters::dev_svs_trk1_idx_t {
  using type = FilterTracks::Parameters::dev_svs_trk1_idx_t::type;
  using deps = FilterTracks::Parameters::dev_svs_trk1_idx_t::deps;
};
struct filter_tracks__dev_svs_trk2_idx_t : FilterTracks::Parameters::dev_svs_trk2_idx_t,
                                           VertexFit::Parameters::dev_svs_trk2_idx_t {
  using type = FilterTracks::Parameters::dev_svs_trk2_idx_t::type;
  using deps = FilterTracks::Parameters::dev_svs_trk2_idx_t::deps;
};
struct prefix_sum_secondary_vertices__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    VertexFit::Parameters::host_number_of_svs_t,
    two_track_preprocess::Parameters::host_number_of_svs_t,
    two_track_evaluator::Parameters::host_number_of_svs_t,
    two_track_mva_line::Parameters::host_number_of_svs_t,
    two_track_catboost_line::Parameters::host_number_of_svs_t,
    d2kk_line::Parameters::host_number_of_svs_t,
    d2kpi_line::Parameters::host_number_of_svs_t,
    d2pipi_line::Parameters::host_number_of_svs_t,
    di_muon_mass_line::Parameters::host_number_of_svs_t,
    di_muon_soft_line::Parameters::host_number_of_svs_t,
    low_pt_di_muon_line::Parameters::host_number_of_svs_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  using deps = host_prefix_sum::Parameters::host_total_sum_holder_t::deps;
};
struct prefix_sum_secondary_vertices__host_output_buffer_t : host_prefix_sum::Parameters::host_output_buffer_t {
  using type = host_prefix_sum::Parameters::host_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::host_output_buffer_t::deps;
};
struct prefix_sum_secondary_vertices__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                            VertexFit::Parameters::dev_sv_offsets_t,
                                                            two_track_preprocess::Parameters::dev_sv_offsets_t,
                                                            two_track_mva_line::Parameters::dev_sv_offsets_t,
                                                            two_track_catboost_line::Parameters::dev_sv_offsets_t,
                                                            d2kk_line::Parameters::dev_sv_offsets_t,
                                                            d2kpi_line::Parameters::dev_sv_offsets_t,
                                                            d2pipi_line::Parameters::dev_sv_offsets_t,
                                                            di_muon_mass_line::Parameters::dev_sv_offsets_t,
                                                            di_muon_soft_line::Parameters::dev_sv_offsets_t,
                                                            low_pt_di_muon_line::Parameters::dev_sv_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  using deps = host_prefix_sum::Parameters::dev_output_buffer_t::deps;
};
struct fit_secondary_vertices__dev_consolidated_svs_t : VertexFit::Parameters::dev_consolidated_svs_t,
                                                        two_track_preprocess::Parameters::dev_consolidated_svs_t,
                                                        two_track_mva_line::Parameters::dev_svs_t,
                                                        two_track_catboost_line::Parameters::dev_svs_t,
                                                        d2kk_line::Parameters::dev_svs_t,
                                                        d2kpi_line::Parameters::dev_svs_t,
                                                        d2pipi_line::Parameters::dev_svs_t,
                                                        di_muon_mass_line::Parameters::dev_svs_t,
                                                        di_muon_soft_line::Parameters::dev_svs_t,
                                                        low_pt_di_muon_line::Parameters::dev_svs_t {
  using type = VertexFit::Parameters::dev_consolidated_svs_t::type;
  using deps = VertexFit::Parameters::dev_consolidated_svs_t::deps;
};
struct two_track_preprocess__dev_two_track_preprocess_output_t
  : two_track_preprocess::Parameters::dev_two_track_preprocess_output_t,
    two_track_evaluator::Parameters::dev_two_track_catboost_preprocess_output_t {
  using type = two_track_preprocess::Parameters::dev_two_track_preprocess_output_t::type;
  using deps = two_track_preprocess::Parameters::dev_two_track_preprocess_output_t::deps;
};
struct two_track_evaluator__dev_two_track_catboost_evaluation_t
  : two_track_evaluator::Parameters::dev_two_track_catboost_evaluation_t,
    two_track_catboost_line::Parameters::dev_two_track_evaluation_t {
  using type = two_track_evaluator::Parameters::dev_two_track_catboost_evaluation_t::type;
  using deps = two_track_evaluator::Parameters::dev_two_track_catboost_evaluation_t::deps;
};
struct populate_odin_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                              track_mva_line::Parameters::dev_odin_raw_input_t,
                                              two_track_mva_line::Parameters::dev_odin_raw_input_t,
                                              two_track_catboost_line::Parameters::dev_odin_raw_input_t,
                                              single_high_pt_muon_line::Parameters::dev_odin_raw_input_t,
                                              low_pt_muon_line::Parameters::dev_odin_raw_input_t,
                                              d2kk_line::Parameters::dev_odin_raw_input_t,
                                              d2kpi_line::Parameters::dev_odin_raw_input_t,
                                              d2pipi_line::Parameters::dev_odin_raw_input_t,
                                              di_muon_mass_line::Parameters::dev_odin_raw_input_t,
                                              di_muon_soft_line::Parameters::dev_odin_raw_input_t,
                                              low_pt_di_muon_line::Parameters::dev_odin_raw_input_t,
                                              track_muon_mva_line::Parameters::dev_odin_raw_input_t,
                                              passthrough_line::Parameters::dev_odin_raw_input_t,
                                              beam_crossing_line::Parameters::dev_odin_raw_input_t,
                                              velo_micro_bias_line::Parameters::dev_odin_raw_input_t,
                                              odin_event_type_line::Parameters::dev_odin_raw_input_t,
                                              gather_selections::Parameters::dev_odin_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  using deps = data_provider::Parameters::dev_raw_banks_t::deps;
};
struct populate_odin_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                                track_mva_line::Parameters::dev_odin_raw_input_offsets_t,
                                                two_track_mva_line::Parameters::dev_odin_raw_input_offsets_t,
                                                two_track_catboost_line::Parameters::dev_odin_raw_input_offsets_t,
                                                single_high_pt_muon_line::Parameters::dev_odin_raw_input_offsets_t,
                                                low_pt_muon_line::Parameters::dev_odin_raw_input_offsets_t,
                                                d2kk_line::Parameters::dev_odin_raw_input_offsets_t,
                                                d2kpi_line::Parameters::dev_odin_raw_input_offsets_t,
                                                d2pipi_line::Parameters::dev_odin_raw_input_offsets_t,
                                                di_muon_mass_line::Parameters::dev_odin_raw_input_offsets_t,
                                                di_muon_soft_line::Parameters::dev_odin_raw_input_offsets_t,
                                                low_pt_di_muon_line::Parameters::dev_odin_raw_input_offsets_t,
                                                track_muon_mva_line::Parameters::dev_odin_raw_input_offsets_t,
                                                passthrough_line::Parameters::dev_odin_raw_input_offsets_t,
                                                beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
                                                velo_micro_bias_line::Parameters::dev_odin_raw_input_offsets_t,
                                                odin_event_type_line::Parameters::dev_odin_raw_input_offsets_t,
                                                gather_selections::Parameters::dev_odin_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  using deps = data_provider::Parameters::dev_raw_offsets_t::deps;
};
struct populate_odin_banks__host_raw_bank_version_t : data_provider::Parameters::host_raw_bank_version_t {
  using type = data_provider::Parameters::host_raw_bank_version_t::type;
  using deps = data_provider::Parameters::host_raw_bank_version_t::deps;
};
struct gather_selections__host_selections_lines_offsets_t
  : gather_selections::Parameters::host_selections_lines_offsets_t {
  using type = gather_selections::Parameters::host_selections_lines_offsets_t::type;
  using deps = gather_selections::Parameters::host_selections_lines_offsets_t::deps;
};
struct gather_selections__host_selections_offsets_t : gather_selections::Parameters::host_selections_offsets_t {
  using type = gather_selections::Parameters::host_selections_offsets_t::type;
  using deps = gather_selections::Parameters::host_selections_offsets_t::deps;
};
struct gather_selections__host_number_of_active_lines_t : gather_selections::Parameters::host_number_of_active_lines_t,
                                                          dec_reporter::Parameters::host_number_of_active_lines_t {
  using type = gather_selections::Parameters::host_number_of_active_lines_t::type;
  using deps = gather_selections::Parameters::host_number_of_active_lines_t::deps;
};
struct gather_selections__host_names_of_active_lines_t : gather_selections::Parameters::host_names_of_active_lines_t {
  using type = gather_selections::Parameters::host_names_of_active_lines_t::type;
  using deps = gather_selections::Parameters::host_names_of_active_lines_t::deps;
};
struct gather_selections__dev_selections_t : gather_selections::Parameters::dev_selections_t,
                                             dec_reporter::Parameters::dev_selections_t {
  using type = gather_selections::Parameters::dev_selections_t::type;
  using deps = gather_selections::Parameters::dev_selections_t::deps;
};
struct gather_selections__dev_selections_offsets_t : gather_selections::Parameters::dev_selections_offsets_t,
                                                     dec_reporter::Parameters::dev_selections_offsets_t {
  using type = gather_selections::Parameters::dev_selections_offsets_t::type;
  using deps = gather_selections::Parameters::dev_selections_offsets_t::deps;
};
struct gather_selections__dev_number_of_active_lines_t : gather_selections::Parameters::dev_number_of_active_lines_t,
                                                         dec_reporter::Parameters::dev_number_of_active_lines_t {
  using type = gather_selections::Parameters::dev_number_of_active_lines_t::type;
  using deps = gather_selections::Parameters::dev_number_of_active_lines_t::deps;
};
struct gather_selections__host_post_scale_factors_t : gather_selections::Parameters::host_post_scale_factors_t {
  using type = gather_selections::Parameters::host_post_scale_factors_t::type;
  using deps = gather_selections::Parameters::host_post_scale_factors_t::deps;
};
struct gather_selections__host_post_scale_hashes_t : gather_selections::Parameters::host_post_scale_hashes_t {
  using type = gather_selections::Parameters::host_post_scale_hashes_t::type;
  using deps = gather_selections::Parameters::host_post_scale_hashes_t::deps;
};
struct gather_selections__dev_post_scale_factors_t : gather_selections::Parameters::dev_post_scale_factors_t {
  using type = gather_selections::Parameters::dev_post_scale_factors_t::type;
  using deps = gather_selections::Parameters::dev_post_scale_factors_t::deps;
};
struct gather_selections__dev_post_scale_hashes_t : gather_selections::Parameters::dev_post_scale_hashes_t {
  using type = gather_selections::Parameters::dev_post_scale_hashes_t::type;
  using deps = gather_selections::Parameters::dev_post_scale_hashes_t::deps;
};
struct dec_reporter__dev_dec_reports_t : dec_reporter::Parameters::dev_dec_reports_t {
  using type = dec_reporter::Parameters::dev_dec_reports_t::type;
  using deps = dec_reporter::Parameters::dev_dec_reports_t::deps;
};

static_assert(all_host_or_all_device_v<
              initialize_event_lists__host_event_list_output_t,
              host_init_event_list::Parameters::host_event_list_output_t>);
static_assert(all_host_or_all_device_v<
              initialize_event_lists__dev_event_list_output_t,
              host_init_event_list::Parameters::dev_event_list_output_t,
              velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
              velo_estimate_input_size::Parameters::dev_event_list_t,
              velo_masked_clustering::Parameters::dev_event_list_t,
              velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
              velo_search_by_triplet::Parameters::dev_event_list_t,
              velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
              beam_crossing_line::Parameters::dev_event_list_t,
              beam_crossing_line::Parameters::dev_event_list_t,
              beam_crossing_line::Parameters::dev_event_list_t,
              beam_crossing_line::Parameters::dev_event_list_t,
              velo_micro_bias_line::Parameters::dev_event_list_t,
              odin_event_type_line::Parameters::dev_event_list_t,
              odin_event_type_line::Parameters::dev_event_list_t,
              passthrough_line::Parameters::dev_event_list_t>);
static_assert(all_host_or_all_device_v<mep_layout__host_mep_layout_t, layout_provider::Parameters::host_mep_layout_t>);
static_assert(all_host_or_all_device_v<
              mep_layout__dev_mep_layout_t,
              layout_provider::Parameters::dev_mep_layout_t,
              track_mva_line::Parameters::dev_mep_layout_t,
              two_track_mva_line::Parameters::dev_mep_layout_t,
              two_track_catboost_line::Parameters::dev_mep_layout_t,
              single_high_pt_muon_line::Parameters::dev_mep_layout_t,
              low_pt_muon_line::Parameters::dev_mep_layout_t,
              d2kk_line::Parameters::dev_mep_layout_t,
              d2kpi_line::Parameters::dev_mep_layout_t,
              d2pipi_line::Parameters::dev_mep_layout_t,
              di_muon_mass_line::Parameters::dev_mep_layout_t,
              di_muon_mass_line::Parameters::dev_mep_layout_t,
              di_muon_soft_line::Parameters::dev_mep_layout_t,
              low_pt_di_muon_line::Parameters::dev_mep_layout_t,
              track_muon_mva_line::Parameters::dev_mep_layout_t,
              passthrough_line::Parameters::dev_mep_layout_t,
              beam_crossing_line::Parameters::dev_mep_layout_t,
              beam_crossing_line::Parameters::dev_mep_layout_t,
              beam_crossing_line::Parameters::dev_mep_layout_t,
              beam_crossing_line::Parameters::dev_mep_layout_t,
              velo_micro_bias_line::Parameters::dev_mep_layout_t,
              odin_event_type_line::Parameters::dev_mep_layout_t,
              odin_event_type_line::Parameters::dev_mep_layout_t,
              passthrough_line::Parameters::dev_mep_layout_t,
              gather_selections::Parameters::dev_mep_layout_t>);
static_assert(all_host_or_all_device_v<
              initialize_number_of_events__host_number_of_events_t,
              host_init_number_of_events::Parameters::host_number_of_events_t,
              ut_calculate_number_of_hits::Parameters::host_number_of_events_t,
              ut_pre_decode::Parameters::host_number_of_events_t,
              ut_find_permutation::Parameters::host_number_of_events_t,
              ut_decode_raw_banks_in_order::Parameters::host_number_of_events_t,
              scifi_calculate_cluster_count_v4::Parameters::host_number_of_events_t,
              scifi_pre_decode_v4::Parameters::host_number_of_events_t,
              scifi_raw_bank_decoder_v4::Parameters::host_number_of_events_t,
              muon_calculate_srq_size::Parameters::host_number_of_events_t,
              muon_populate_tile_and_tdc::Parameters::host_number_of_events_t,
              muon_add_coords_crossing_maps::Parameters::host_number_of_events_t,
              muon_populate_hits::Parameters::host_number_of_events_t,
              velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
              velo_estimate_input_size::Parameters::host_number_of_events_t,
              velo_masked_clustering::Parameters::host_number_of_events_t,
              velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
              velo_search_by_triplet::Parameters::host_number_of_events_t,
              velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
              velo_copy_track_hit_number::Parameters::host_number_of_events_t,
              velo_consolidate_tracks::Parameters::host_number_of_events_t,
              velo_kalman_filter::Parameters::host_number_of_events_t,
              ut_select_velo_tracks::Parameters::host_number_of_events_t,
              pv_beamline_extrapolate::Parameters::host_number_of_events_t,
              pv_beamline_histo::Parameters::host_number_of_events_t,
              ut_search_windows::Parameters::host_number_of_events_t,
              ut_select_velo_tracks_with_windows::Parameters::host_number_of_events_t,
              compass_ut::Parameters::host_number_of_events_t,
              ut_copy_track_hit_number::Parameters::host_number_of_events_t,
              ut_consolidate_tracks::Parameters::host_number_of_events_t,
              lf_search_initial_windows::Parameters::host_number_of_events_t,
              pv_beamline_peak::Parameters::host_number_of_events_t,
              pv_beamline_calculate_denom::Parameters::host_number_of_events_t,
              pv_beamline_multi_fitter::Parameters::host_number_of_events_t,
              pv_beamline_cleanup::Parameters::host_number_of_events_t,
              velo_pv_ip::Parameters::host_number_of_events_t,
              lf_triplet_seeding::Parameters::host_number_of_events_t,
              lf_create_tracks::Parameters::host_number_of_events_t,
              lf_quality_filter_length::Parameters::host_number_of_events_t,
              lf_quality_filter::Parameters::host_number_of_events_t,
              scifi_copy_track_hit_number::Parameters::host_number_of_events_t,
              scifi_consolidate_tracks::Parameters::host_number_of_events_t,
              is_muon::Parameters::host_number_of_events_t,
              kalman_velo_only::Parameters::host_number_of_events_t,
              FilterTracks::Parameters::host_number_of_events_t,
              VertexFit::Parameters::host_number_of_events_t,
              two_track_preprocess::Parameters::host_number_of_selected_events_t,
              track_mva_line::Parameters::host_number_of_events_t,
              two_track_mva_line::Parameters::host_number_of_events_t,
              two_track_catboost_line::Parameters::host_number_of_events_t,
              single_high_pt_muon_line::Parameters::host_number_of_events_t,
              low_pt_muon_line::Parameters::host_number_of_events_t,
              d2kk_line::Parameters::host_number_of_events_t,
              d2kpi_line::Parameters::host_number_of_events_t,
              d2pipi_line::Parameters::host_number_of_events_t,
              di_muon_mass_line::Parameters::host_number_of_events_t,
              di_muon_mass_line::Parameters::host_number_of_events_t,
              di_muon_soft_line::Parameters::host_number_of_events_t,
              low_pt_di_muon_line::Parameters::host_number_of_events_t,
              track_muon_mva_line::Parameters::host_number_of_events_t,
              passthrough_line::Parameters::host_number_of_events_t,
              beam_crossing_line::Parameters::host_number_of_events_t,
              beam_crossing_line::Parameters::host_number_of_events_t,
              beam_crossing_line::Parameters::host_number_of_events_t,
              beam_crossing_line::Parameters::host_number_of_events_t,
              velo_micro_bias_line::Parameters::host_number_of_events_t,
              odin_event_type_line::Parameters::host_number_of_events_t,
              odin_event_type_line::Parameters::host_number_of_events_t,
              passthrough_line::Parameters::host_number_of_events_t,
              gather_selections::Parameters::host_number_of_events_t,
              dec_reporter::Parameters::host_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              initialize_number_of_events__dev_number_of_events_t,
              host_init_number_of_events::Parameters::dev_number_of_events_t,
              ut_pre_decode::Parameters::dev_number_of_events_t,
              ut_find_permutation::Parameters::dev_number_of_events_t,
              ut_decode_raw_banks_in_order::Parameters::dev_number_of_events_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_number_of_events_t,
              muon_populate_hits::Parameters::dev_number_of_events_t,
              velo_masked_clustering::Parameters::dev_number_of_events_t,
              velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
              velo_search_by_triplet::Parameters::dev_number_of_events_t,
              velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
              velo_consolidate_tracks::Parameters::dev_number_of_events_t,
              velo_kalman_filter::Parameters::dev_number_of_events_t,
              ut_select_velo_tracks::Parameters::dev_number_of_events_t,
              pv_beamline_extrapolate::Parameters::dev_number_of_events_t,
              pv_beamline_histo::Parameters::dev_number_of_events_t,
              ut_search_windows::Parameters::dev_number_of_events_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_number_of_events_t,
              compass_ut::Parameters::dev_number_of_events_t,
              ut_consolidate_tracks::Parameters::dev_number_of_events_t,
              lf_search_initial_windows::Parameters::dev_number_of_events_t,
              pv_beamline_calculate_denom::Parameters::dev_number_of_events_t,
              pv_beamline_multi_fitter::Parameters::dev_number_of_events_t,
              velo_pv_ip::Parameters::dev_number_of_events_t,
              lf_triplet_seeding::Parameters::dev_number_of_events_t,
              lf_create_tracks::Parameters::dev_number_of_events_t,
              lf_quality_filter_length::Parameters::dev_number_of_events_t,
              lf_quality_filter::Parameters::dev_number_of_events_t,
              scifi_consolidate_tracks::Parameters::dev_number_of_events_t,
              is_muon::Parameters::dev_number_of_events_t,
              kalman_velo_only::Parameters::dev_number_of_events_t,
              FilterTracks::Parameters::dev_number_of_events_t,
              VertexFit::Parameters::dev_number_of_events_t,
              passthrough_line::Parameters::dev_number_of_events_t,
              velo_micro_bias_line::Parameters::dev_number_of_events_t,
              passthrough_line::Parameters::dev_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_banks_t,
              host_data_provider::Parameters::host_raw_banks_t,
              host_global_event_cut::Parameters::host_scifi_raw_banks_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_offsets_t,
              host_data_provider::Parameters::host_raw_offsets_t,
              host_global_event_cut::Parameters::host_scifi_raw_offsets_t>);
static_assert(all_host_or_all_device_v<
              host_scifi_banks__host_raw_bank_version_t,
              host_data_provider::Parameters::host_raw_bank_version_t,
              host_global_event_cut::Parameters::host_ut_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_banks_t,
              host_data_provider::Parameters::host_raw_banks_t,
              host_global_event_cut::Parameters::host_ut_raw_banks_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_offsets_t,
              host_data_provider::Parameters::host_raw_offsets_t,
              host_global_event_cut::Parameters::host_ut_raw_offsets_t>);
static_assert(all_host_or_all_device_v<
              host_ut_banks__host_raw_bank_version_t,
              host_data_provider::Parameters::host_raw_bank_version_t>);
static_assert(
  all_host_or_all_device_v<gec__host_event_list_output_t, host_global_event_cut::Parameters::host_event_list_output_t>);
static_assert(
  all_host_or_all_device_v<gec__host_number_of_events_t, host_global_event_cut::Parameters::host_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              gec__host_number_of_selected_events_t,
              host_global_event_cut::Parameters::host_number_of_selected_events_t>);
static_assert(
  all_host_or_all_device_v<gec__dev_number_of_events_t, host_global_event_cut::Parameters::dev_number_of_events_t>);
static_assert(all_host_or_all_device_v<
              gec__dev_event_list_output_t,
              host_global_event_cut::Parameters::dev_event_list_output_t,
              ut_calculate_number_of_hits::Parameters::dev_event_list_t,
              ut_pre_decode::Parameters::dev_event_list_t,
              ut_find_permutation::Parameters::dev_event_list_t,
              ut_decode_raw_banks_in_order::Parameters::dev_event_list_t,
              scifi_calculate_cluster_count_v4::Parameters::dev_event_list_t,
              scifi_pre_decode_v4::Parameters::dev_event_list_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_event_list_t,
              muon_calculate_srq_size::Parameters::dev_event_list_t,
              muon_populate_tile_and_tdc::Parameters::dev_event_list_t,
              muon_add_coords_crossing_maps::Parameters::dev_event_list_t,
              muon_populate_hits::Parameters::dev_event_list_t,
              velo_consolidate_tracks::Parameters::dev_event_list_t,
              velo_kalman_filter::Parameters::dev_event_list_t,
              ut_select_velo_tracks::Parameters::dev_event_list_t,
              pv_beamline_extrapolate::Parameters::dev_event_list_t,
              pv_beamline_histo::Parameters::dev_event_list_t,
              ut_search_windows::Parameters::dev_event_list_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_event_list_t,
              compass_ut::Parameters::dev_event_list_t,
              ut_consolidate_tracks::Parameters::dev_event_list_t,
              lf_search_initial_windows::Parameters::dev_event_list_t,
              pv_beamline_peak::Parameters::dev_event_list_t,
              pv_beamline_calculate_denom::Parameters::dev_event_list_t,
              pv_beamline_multi_fitter::Parameters::dev_event_list_t,
              pv_beamline_cleanup::Parameters::dev_event_list_t,
              velo_pv_ip::Parameters::dev_event_list_t,
              lf_triplet_seeding::Parameters::dev_event_list_t,
              lf_create_tracks::Parameters::dev_event_list_t,
              lf_quality_filter_length::Parameters::dev_event_list_t,
              lf_quality_filter::Parameters::dev_event_list_t,
              scifi_consolidate_tracks::Parameters::dev_event_list_t,
              is_muon::Parameters::dev_event_list_t,
              kalman_velo_only::Parameters::dev_event_list_t,
              FilterTracks::Parameters::dev_event_list_t,
              VertexFit::Parameters::dev_event_list_t,
              two_track_preprocess::Parameters::dev_event_list_t,
              track_mva_line::Parameters::dev_event_list_t,
              two_track_mva_line::Parameters::dev_event_list_t,
              two_track_catboost_line::Parameters::dev_event_list_t,
              single_high_pt_muon_line::Parameters::dev_event_list_t,
              low_pt_muon_line::Parameters::dev_event_list_t,
              d2kk_line::Parameters::dev_event_list_t,
              d2kpi_line::Parameters::dev_event_list_t,
              d2pipi_line::Parameters::dev_event_list_t,
              di_muon_mass_line::Parameters::dev_event_list_t,
              di_muon_mass_line::Parameters::dev_event_list_t,
              di_muon_soft_line::Parameters::dev_event_list_t,
              low_pt_di_muon_line::Parameters::dev_event_list_t,
              track_muon_mva_line::Parameters::dev_event_list_t,
              passthrough_line::Parameters::dev_event_list_t>);
static_assert(all_host_or_all_device_v<
              ut_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_t,
              ut_pre_decode::Parameters::dev_ut_raw_input_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_t>);
static_assert(all_host_or_all_device_v<
              ut_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_offsets_t,
              ut_pre_decode::Parameters::dev_ut_raw_input_offsets_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_offsets_t>);
static_assert(all_host_or_all_device_v<
              ut_banks__host_raw_bank_version_t,
              data_provider::Parameters::host_raw_bank_version_t,
              ut_calculate_number_of_hits::Parameters::host_raw_bank_version_t,
              ut_pre_decode::Parameters::host_raw_bank_version_t,
              ut_decode_raw_banks_in_order::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
              ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_hits__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              ut_pre_decode::Parameters::host_accumulated_number_of_ut_hits_t,
              ut_find_permutation::Parameters::host_accumulated_number_of_ut_hits_t,
              ut_decode_raw_banks_in_order::Parameters::host_accumulated_number_of_ut_hits_t,
              ut_consolidate_tracks::Parameters::host_accumulated_number_of_ut_hits_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_hits__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_hits__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              ut_pre_decode::Parameters::dev_ut_hit_offsets_t,
              ut_find_permutation::Parameters::dev_ut_hit_offsets_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_offsets_t,
              ut_search_windows::Parameters::dev_ut_hit_offsets_t,
              compass_ut::Parameters::dev_ut_hit_offsets_t,
              ut_consolidate_tracks::Parameters::dev_ut_hit_offsets_t>);
static_assert(all_host_or_all_device_v<
              ut_pre_decode__dev_ut_pre_decoded_hits_t,
              ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t,
              ut_find_permutation::Parameters::dev_ut_pre_decoded_hits_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_pre_decoded_hits_t>);
static_assert(
  all_host_or_all_device_v<ut_pre_decode__dev_ut_hit_count_t, ut_pre_decode::Parameters::dev_ut_hit_count_t>);
static_assert(all_host_or_all_device_v<
              ut_find_permutation__dev_ut_hit_permutations_t,
              ut_find_permutation::Parameters::dev_ut_hit_permutations_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_permutations_t>);
static_assert(all_host_or_all_device_v<
              ut_decode_raw_banks_in_order__dev_ut_hits_t,
              ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t,
              ut_search_windows::Parameters::dev_ut_hits_t,
              compass_ut::Parameters::dev_ut_hits_t,
              ut_consolidate_tracks::Parameters::dev_ut_hits_t>);
static_assert(all_host_or_all_device_v<
              scifi_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_t,
              scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_t>);
static_assert(all_host_or_all_device_v<
              scifi_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_offsets_t,
              scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_offsets_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_offsets_t>);
static_assert(
  all_host_or_all_device_v<scifi_banks__host_raw_bank_version_t, data_provider::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              scifi_calculate_cluster_count__dev_scifi_hit_count_t,
              scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_hits__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              scifi_pre_decode_v4::Parameters::host_accumulated_number_of_scifi_hits_t,
              scifi_raw_bank_decoder_v4::Parameters::host_accumulated_number_of_scifi_hits_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_hits__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_hits__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              scifi_pre_decode_v4::Parameters::dev_scifi_hit_offsets_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hit_offsets_t,
              lf_search_initial_windows::Parameters::dev_scifi_hit_offsets_t,
              lf_triplet_seeding::Parameters::dev_scifi_hit_offsets_t,
              lf_create_tracks::Parameters::dev_scifi_hit_offsets_t,
              lf_quality_filter::Parameters::dev_scifi_hit_offsets_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_hit_offsets_t>);
static_assert(all_host_or_all_device_v<
              scifi_pre_decode__dev_cluster_references_t,
              scifi_pre_decode_v4::Parameters::dev_cluster_references_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_cluster_references_t>);
static_assert(all_host_or_all_device_v<
              scifi_raw_bank_decoder__dev_scifi_hits_t,
              scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t,
              lf_search_initial_windows::Parameters::dev_scifi_hits_t,
              lf_triplet_seeding::Parameters::dev_scifi_hits_t,
              lf_create_tracks::Parameters::dev_scifi_hits_t,
              lf_quality_filter::Parameters::dev_scifi_hits_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_hits_t>);
static_assert(all_host_or_all_device_v<
              muon_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              muon_calculate_srq_size::Parameters::dev_muon_raw_t,
              muon_populate_tile_and_tdc::Parameters::dev_muon_raw_t>);
static_assert(all_host_or_all_device_v<
              muon_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              muon_calculate_srq_size::Parameters::dev_muon_raw_offsets_t,
              muon_populate_tile_and_tdc::Parameters::dev_muon_raw_offsets_t>);
static_assert(
  all_host_or_all_device_v<muon_banks__host_raw_bank_version_t, data_provider::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              muon_calculate_srq_size__dev_muon_raw_to_hits_t,
              muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t,
              muon_populate_tile_and_tdc::Parameters::dev_muon_raw_to_hits_t,
              muon_add_coords_crossing_maps::Parameters::dev_muon_raw_to_hits_t,
              muon_populate_hits::Parameters::dev_muon_raw_to_hits_t>);
static_assert(all_host_or_all_device_v<
              muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t,
              muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              muon_srq_prefix_sum__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              muon_populate_tile_and_tdc::Parameters::host_muon_total_number_of_tiles_t,
              muon_add_coords_crossing_maps::Parameters::host_muon_total_number_of_tiles_t>);
static_assert(all_host_or_all_device_v<
              muon_srq_prefix_sum__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              muon_srq_prefix_sum__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              muon_populate_tile_and_tdc::Parameters::dev_storage_station_region_quarter_offsets_t,
              muon_add_coords_crossing_maps::Parameters::dev_storage_station_region_quarter_offsets_t,
              muon_populate_hits::Parameters::dev_storage_station_region_quarter_offsets_t>);
static_assert(all_host_or_all_device_v<
              muon_populate_tile_and_tdc__dev_storage_tile_id_t,
              muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t,
              muon_add_coords_crossing_maps::Parameters::dev_storage_tile_id_t,
              muon_populate_hits::Parameters::dev_storage_tile_id_t>);
static_assert(all_host_or_all_device_v<
              muon_populate_tile_and_tdc__dev_storage_tdc_value_t,
              muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t,
              muon_populate_hits::Parameters::dev_storage_tdc_value_t>);
static_assert(all_host_or_all_device_v<
              muon_populate_tile_and_tdc__dev_atomics_muon_t,
              muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t>);
static_assert(all_host_or_all_device_v<
              muon_add_coords_crossing_maps__dev_atomics_index_insert_t,
              muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t>);
static_assert(all_host_or_all_device_v<
              muon_add_coords_crossing_maps__dev_muon_compact_hit_t,
              muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t,
              muon_populate_hits::Parameters::dev_muon_compact_hit_t>);
static_assert(all_host_or_all_device_v<
              muon_add_coords_crossing_maps__dev_muon_tile_used_t,
              muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t>);
static_assert(all_host_or_all_device_v<
              muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t,
              muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              muon_populate_hits::Parameters::host_muon_total_number_of_hits_t>);
static_assert(all_host_or_all_device_v<
              muon_station_ocurrence_prefix_sum__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              muon_populate_hits::Parameters::dev_station_ocurrences_offset_t,
              is_muon::Parameters::dev_station_ocurrences_offset_t>);
static_assert(all_host_or_all_device_v<
              muon_populate_hits__dev_permutation_station_t,
              muon_populate_hits::Parameters::dev_permutation_station_t>);
static_assert(all_host_or_all_device_v<
              muon_populate_hits__dev_muon_hits_t,
              muon_populate_hits::Parameters::dev_muon_hits_t,
              is_muon::Parameters::dev_muon_hits_t>);
static_assert(all_host_or_all_device_v<
              velo_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
              velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
              velo_masked_clustering::Parameters::dev_velo_raw_input_t>);
static_assert(all_host_or_all_device_v<
              velo_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
              velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
              velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t>);
static_assert(
  all_host_or_all_device_v<velo_banks__host_raw_bank_version_t, data_provider::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_number_of_candidates__dev_number_of_candidates_t,
              velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
              velo_masked_clustering::Parameters::dev_candidates_offsets_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_estimated_input_size_t,
              velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_module_candidate_num_t,
              velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
              velo_masked_clustering::Parameters::dev_module_candidate_num_t>);
static_assert(all_host_or_all_device_v<
              velo_estimate_input_size__dev_cluster_candidates_t,
              velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
              velo_masked_clustering::Parameters::dev_cluster_candidates_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
              velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
              velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
              velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
              velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
              velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
              velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_module_cluster_num_t,
              velo_masked_clustering::Parameters::dev_module_cluster_num_t,
              velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
              velo_search_by_triplet::Parameters::dev_module_cluster_num_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_velo_cluster_container_t,
              velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
              velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t>);
static_assert(all_host_or_all_device_v<
              velo_masked_clustering__dev_velo_clusters_t,
              velo_masked_clustering::Parameters::dev_velo_clusters_t,
              velo_calculate_phi_and_sort::Parameters::dev_velo_clusters_t,
              velo_search_by_triplet::Parameters::dev_velo_clusters_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
              velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
              velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
              velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
              velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_hit_permutation_t,
              velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t>);
static_assert(all_host_or_all_device_v<
              velo_calculate_phi_and_sort__dev_hit_phi_t,
              velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
              velo_search_by_triplet::Parameters::dev_hit_phi_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracks_t,
              velo_search_by_triplet::Parameters::dev_tracks_t,
              velo_copy_track_hit_number::Parameters::dev_tracks_t,
              velo_consolidate_tracks::Parameters::dev_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracklets_t,
              velo_search_by_triplet::Parameters::dev_tracklets_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_tracks_to_follow_t,
              velo_search_by_triplet::Parameters::dev_tracks_to_follow_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_three_hit_tracks_t,
              velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
              velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_hit_used_t,
              velo_search_by_triplet::Parameters::dev_hit_used_t,
              velo_three_hit_tracks_filter::Parameters::dev_hit_used_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_atomics_velo_t,
              velo_search_by_triplet::Parameters::dev_atomics_velo_t,
              velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_rel_indices_t,
              velo_search_by_triplet::Parameters::dev_rel_indices_t>);
static_assert(all_host_or_all_device_v<
              velo_search_by_triplet__dev_number_of_velo_tracks_t,
              velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
              velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
              velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t>);
static_assert(all_host_or_all_device_v<
              velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
              velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
              velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
              velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
              velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
              velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
              velo_kalman_filter::Parameters::host_number_of_reconstructed_velo_tracks_t,
              ut_select_velo_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
              pv_beamline_extrapolate::Parameters::host_number_of_reconstructed_velo_tracks_t,
              ut_search_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
              ut_select_velo_tracks_with_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
              pv_beamline_calculate_denom::Parameters::host_number_of_reconstructed_velo_tracks_t,
              pv_beamline_multi_fitter::Parameters::host_number_of_reconstructed_velo_tracks_t,
              velo_pv_ip::Parameters::host_number_of_reconstructed_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__dev_velo_track_hit_number_t,
              velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
              velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
              velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
              velo_kalman_filter::Parameters::dev_offsets_all_velo_tracks_t,
              ut_select_velo_tracks::Parameters::dev_offsets_all_velo_tracks_t,
              pv_beamline_extrapolate::Parameters::dev_offsets_all_velo_tracks_t,
              pv_beamline_histo::Parameters::dev_offsets_all_velo_tracks_t,
              ut_search_windows::Parameters::dev_offsets_all_velo_tracks_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_offsets_all_velo_tracks_t,
              compass_ut::Parameters::dev_offsets_all_velo_tracks_t,
              lf_search_initial_windows::Parameters::dev_offsets_all_velo_tracks_t,
              pv_beamline_calculate_denom::Parameters::dev_offsets_all_velo_tracks_t,
              pv_beamline_multi_fitter::Parameters::dev_offsets_all_velo_tracks_t,
              velo_pv_ip::Parameters::dev_offsets_all_velo_tracks_t,
              lf_triplet_seeding::Parameters::dev_offsets_all_velo_tracks_t,
              lf_create_tracks::Parameters::dev_offsets_all_velo_tracks_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
              kalman_velo_only::Parameters::dev_offsets_all_velo_tracks_t,
              two_track_preprocess::Parameters::dev_offsets_all_velo_tracks_t,
              velo_micro_bias_line::Parameters::dev_offsets_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
              velo_kalman_filter::Parameters::dev_offsets_velo_track_hit_number_t,
              ut_select_velo_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
              pv_beamline_extrapolate::Parameters::dev_offsets_velo_track_hit_number_t,
              pv_beamline_histo::Parameters::dev_offsets_velo_track_hit_number_t,
              ut_search_windows::Parameters::dev_offsets_velo_track_hit_number_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_offsets_velo_track_hit_number_t,
              compass_ut::Parameters::dev_offsets_velo_track_hit_number_t,
              lf_search_initial_windows::Parameters::dev_offsets_velo_track_hit_number_t,
              pv_beamline_calculate_denom::Parameters::dev_offsets_velo_track_hit_number_t,
              pv_beamline_multi_fitter::Parameters::dev_offsets_velo_track_hit_number_t,
              velo_pv_ip::Parameters::dev_offsets_velo_track_hit_number_t,
              lf_create_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
              kalman_velo_only::Parameters::dev_offsets_velo_track_hit_number_t,
              two_track_preprocess::Parameters::dev_offsets_velo_track_hit_number_t,
              velo_micro_bias_line::Parameters::dev_offsets_velo_track_hit_number_t>);
static_assert(all_host_or_all_device_v<
              velo_consolidate_tracks__dev_accepted_velo_tracks_t,
              velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t,
              ut_select_velo_tracks::Parameters::dev_accepted_velo_tracks_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_accepted_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              velo_consolidate_tracks__dev_velo_track_hits_t,
              velo_consolidate_tracks::Parameters::dev_velo_track_hits_t,
              velo_kalman_filter::Parameters::dev_velo_track_hits_t,
              ut_select_velo_tracks::Parameters::dev_velo_track_hits_t,
              kalman_velo_only::Parameters::dev_velo_track_hits_t>);
static_assert(all_host_or_all_device_v<
              velo_kalman_filter__dev_velo_kalman_beamline_states_t,
              velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t,
              ut_select_velo_tracks::Parameters::dev_velo_states_t,
              pv_beamline_extrapolate::Parameters::dev_velo_kalman_beamline_states_t,
              velo_pv_ip::Parameters::dev_velo_kalman_beamline_states_t>);
static_assert(all_host_or_all_device_v<
              velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
              velo_kalman_filter::Parameters::dev_velo_kalman_endvelo_states_t,
              ut_search_windows::Parameters::dev_velo_states_t,
              lf_search_initial_windows::Parameters::dev_velo_states_t,
              lf_triplet_seeding::Parameters::dev_velo_states_t,
              lf_create_tracks::Parameters::dev_velo_states_t,
              scifi_consolidate_tracks::Parameters::dev_velo_states_t>);
static_assert(all_host_or_all_device_v<
              velo_kalman_filter__dev_velo_lmsfit_beamline_states_t,
              velo_kalman_filter::Parameters::dev_velo_lmsfit_beamline_states_t,
              compass_ut::Parameters::dev_velo_states_t>);
static_assert(all_host_or_all_device_v<
              ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
              ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t,
              ut_search_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
              ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t,
              ut_search_windows::Parameters::dev_ut_selected_velo_tracks_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_extrapolate__dev_pvtracks_t,
              pv_beamline_extrapolate::Parameters::dev_pvtracks_t,
              pv_beamline_histo::Parameters::dev_pvtracks_t,
              pv_beamline_calculate_denom::Parameters::dev_pvtracks_t,
              pv_beamline_multi_fitter::Parameters::dev_pvtracks_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_extrapolate__dev_pvtrack_z_t,
              pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t,
              pv_beamline_multi_fitter::Parameters::dev_pvtrack_z_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t,
              pv_beamline_extrapolate::Parameters::dev_pvtrack_unsorted_z_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_histo__dev_zhisto_t,
              pv_beamline_histo::Parameters::dev_zhisto_t,
              pv_beamline_peak::Parameters::dev_zhisto_t>);
static_assert(all_host_or_all_device_v<
              ut_search_windows__dev_ut_windows_layers_t,
              ut_search_windows::Parameters::dev_ut_windows_layers_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_ut_windows_layers_t,
              compass_ut::Parameters::dev_ut_windows_layers_t>);
static_assert(all_host_or_all_device_v<
              ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t,
              compass_ut::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t>);
static_assert(all_host_or_all_device_v<
              ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
              ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t,
              compass_ut::Parameters::dev_ut_selected_velo_tracks_with_windows_t>);
static_assert(all_host_or_all_device_v<
              compass_ut__dev_ut_tracks_t,
              compass_ut::Parameters::dev_ut_tracks_t,
              ut_copy_track_hit_number::Parameters::dev_ut_tracks_t,
              ut_consolidate_tracks::Parameters::dev_ut_tracks_t>);
static_assert(all_host_or_all_device_v<
              compass_ut__dev_atomics_ut_t,
              compass_ut::Parameters::dev_atomics_ut_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_tracks__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              ut_copy_track_hit_number::Parameters::host_number_of_reconstructed_ut_tracks_t,
              ut_consolidate_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
              lf_search_initial_windows::Parameters::host_number_of_reconstructed_ut_tracks_t,
              lf_triplet_seeding::Parameters::host_number_of_reconstructed_ut_tracks_t,
              lf_create_tracks::Parameters::host_number_of_reconstructed_ut_tracks_t,
              lf_quality_filter_length::Parameters::host_number_of_reconstructed_ut_tracks_t,
              lf_quality_filter::Parameters::host_number_of_reconstructed_ut_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_tracks__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_tracks__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              ut_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
              ut_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t,
              lf_search_initial_windows::Parameters::dev_offsets_ut_tracks_t,
              lf_triplet_seeding::Parameters::dev_offsets_ut_tracks_t,
              lf_create_tracks::Parameters::dev_offsets_ut_tracks_t,
              lf_quality_filter_length::Parameters::dev_offsets_ut_tracks_t,
              lf_quality_filter::Parameters::dev_offsets_ut_tracks_t,
              scifi_copy_track_hit_number::Parameters::dev_offsets_ut_tracks_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_ut_tracks_t,
              kalman_velo_only::Parameters::dev_offsets_ut_tracks_t>);
static_assert(all_host_or_all_device_v<
              ut_copy_track_hit_number__dev_ut_track_hit_number_t,
              ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              ut_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_ut_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_track_hit_number__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_ut_track_hit_number__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              ut_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
              lf_search_initial_windows::Parameters::dev_offsets_ut_track_hit_number_t,
              lf_triplet_seeding::Parameters::dev_offsets_ut_track_hit_number_t,
              lf_create_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
              lf_quality_filter_length::Parameters::dev_offsets_ut_track_hit_number_t,
              lf_quality_filter::Parameters::dev_offsets_ut_track_hit_number_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_ut_track_hit_number_t,
              kalman_velo_only::Parameters::dev_offsets_ut_track_hit_number_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_track_hits_t,
              ut_consolidate_tracks::Parameters::dev_ut_track_hits_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_qop_t,
              ut_consolidate_tracks::Parameters::dev_ut_qop_t,
              lf_search_initial_windows::Parameters::dev_ut_qop_t,
              lf_triplet_seeding::Parameters::dev_ut_qop_t,
              lf_create_tracks::Parameters::dev_ut_qop_t,
              scifi_consolidate_tracks::Parameters::dev_ut_qop_t,
              kalman_velo_only::Parameters::dev_ut_qop_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_x_t,
              ut_consolidate_tracks::Parameters::dev_ut_x_t,
              lf_search_initial_windows::Parameters::dev_ut_x_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_tx_t,
              ut_consolidate_tracks::Parameters::dev_ut_tx_t,
              lf_search_initial_windows::Parameters::dev_ut_tx_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_z_t,
              ut_consolidate_tracks::Parameters::dev_ut_z_t,
              lf_search_initial_windows::Parameters::dev_ut_z_t>);
static_assert(all_host_or_all_device_v<
              ut_consolidate_tracks__dev_ut_track_velo_indices_t,
              ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
              lf_search_initial_windows::Parameters::dev_ut_track_velo_indices_t,
              lf_triplet_seeding::Parameters::dev_ut_track_velo_indices_t,
              lf_create_tracks::Parameters::dev_ut_track_velo_indices_t,
              scifi_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
              kalman_velo_only::Parameters::dev_ut_track_velo_indices_t>);
static_assert(all_host_or_all_device_v<
              lf_search_initial_windows__dev_scifi_lf_initial_windows_t,
              lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t,
              lf_triplet_seeding::Parameters::dev_scifi_lf_initial_windows_t,
              lf_create_tracks::Parameters::dev_scifi_lf_initial_windows_t>);
static_assert(all_host_or_all_device_v<
              lf_search_initial_windows__dev_ut_states_t,
              lf_search_initial_windows::Parameters::dev_ut_states_t,
              lf_triplet_seeding::Parameters::dev_ut_states_t,
              lf_create_tracks::Parameters::dev_ut_states_t,
              lf_quality_filter::Parameters::dev_ut_states_t>);
static_assert(all_host_or_all_device_v<
              lf_search_initial_windows__dev_scifi_lf_process_track_t,
              lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t,
              lf_triplet_seeding::Parameters::dev_scifi_lf_process_track_t,
              lf_create_tracks::Parameters::dev_scifi_lf_process_track_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_peak__dev_zpeaks_t,
              pv_beamline_peak::Parameters::dev_zpeaks_t,
              pv_beamline_calculate_denom::Parameters::dev_zpeaks_t,
              pv_beamline_multi_fitter::Parameters::dev_zpeaks_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_peak__dev_number_of_zpeaks_t,
              pv_beamline_peak::Parameters::dev_number_of_zpeaks_t,
              pv_beamline_calculate_denom::Parameters::dev_number_of_zpeaks_t,
              pv_beamline_multi_fitter::Parameters::dev_number_of_zpeaks_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_calculate_denom__dev_pvtracks_denom_t,
              pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t,
              pv_beamline_multi_fitter::Parameters::dev_pvtracks_denom_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
              pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t,
              pv_beamline_cleanup::Parameters::dev_multi_fit_vertices_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
              pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t,
              pv_beamline_cleanup::Parameters::dev_number_of_multi_fit_vertices_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_cleanup__dev_multi_final_vertices_t,
              pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t,
              velo_pv_ip::Parameters::dev_multi_final_vertices_t,
              kalman_velo_only::Parameters::dev_multi_final_vertices_t,
              FilterTracks::Parameters::dev_multi_final_vertices_t,
              VertexFit::Parameters::dev_multi_final_vertices_t>);
static_assert(all_host_or_all_device_v<
              pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
              pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t,
              velo_pv_ip::Parameters::dev_number_of_multi_final_vertices_t,
              kalman_velo_only::Parameters::dev_number_of_multi_final_vertices_t,
              FilterTracks::Parameters::dev_number_of_multi_final_vertices_t,
              VertexFit::Parameters::dev_number_of_multi_final_vertices_t>);
static_assert(all_host_or_all_device_v<
              velo_pv_ip__dev_velo_pv_ip_t,
              velo_pv_ip::Parameters::dev_velo_pv_ip_t,
              kalman_velo_only::Parameters::dev_velo_pv_ip_t>);
static_assert(all_host_or_all_device_v<
              lf_triplet_seeding__dev_scifi_lf_found_triplets_t,
              lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t,
              lf_create_tracks::Parameters::dev_scifi_lf_found_triplets_t>);
static_assert(all_host_or_all_device_v<
              lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t,
              lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t,
              lf_create_tracks::Parameters::dev_scifi_lf_number_of_found_triplets_t>);
static_assert(all_host_or_all_device_v<
              lf_create_tracks__dev_scifi_lf_tracks_t,
              lf_create_tracks::Parameters::dev_scifi_lf_tracks_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_tracks_t>);
static_assert(all_host_or_all_device_v<
              lf_create_tracks__dev_scifi_lf_atomics_t,
              lf_create_tracks::Parameters::dev_scifi_lf_atomics_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_atomics_t>);
static_assert(all_host_or_all_device_v<
              lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t,
              lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t>);
static_assert(all_host_or_all_device_v<
              lf_create_tracks__dev_scifi_lf_parametrization_t,
              lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t,
              lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_tracks_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t,
              lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_atomics_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t,
              lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t,
              lf_quality_filter::Parameters::dev_scifi_lf_parametrization_length_filter_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter__dev_lf_quality_of_tracks_t,
              lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter__dev_atomics_scifi_t,
              lf_quality_filter::Parameters::dev_atomics_scifi_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter__dev_scifi_tracks_t,
              lf_quality_filter::Parameters::dev_scifi_tracks_t,
              scifi_copy_track_hit_number::Parameters::dev_scifi_tracks_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_tracks_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t,
              lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t>);
static_assert(all_host_or_all_device_v<
              lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t,
              lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_lf_parametrization_consolidate_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_forward_tracks__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              scifi_copy_track_hit_number::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              scifi_consolidate_tracks::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              is_muon::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              kalman_velo_only::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              track_mva_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              single_high_pt_muon_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              low_pt_muon_line::Parameters::host_number_of_reconstructed_scifi_tracks_t,
              track_muon_mva_line::Parameters::host_number_of_reconstructed_scifi_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_forward_tracks__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_forward_tracks__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              scifi_copy_track_hit_number::Parameters::dev_offsets_forward_tracks_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_forward_tracks_t,
              is_muon::Parameters::dev_offsets_forward_tracks_t,
              kalman_velo_only::Parameters::dev_offsets_forward_tracks_t,
              FilterTracks::Parameters::dev_offsets_forward_tracks_t,
              VertexFit::Parameters::dev_offsets_forward_tracks_t,
              track_mva_line::Parameters::dev_track_offsets_t,
              single_high_pt_muon_line::Parameters::dev_track_offsets_t,
              low_pt_muon_line::Parameters::dev_track_offsets_t,
              track_muon_mva_line::Parameters::dev_track_offsets_t>);
static_assert(all_host_or_all_device_v<
              scifi_copy_track_hit_number__dev_scifi_track_hit_number_t,
              scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              scifi_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_scifi_tracks_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_track_hit_number__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              scifi_consolidate_tracks::Parameters::dev_offsets_scifi_track_hit_number_t,
              is_muon::Parameters::dev_offsets_scifi_track_hit_number,
              kalman_velo_only::Parameters::dev_offsets_scifi_track_hit_number_t,
              FilterTracks::Parameters::dev_offsets_scifi_track_hit_number_t,
              VertexFit::Parameters::dev_offsets_scifi_track_hit_number_t>);
static_assert(all_host_or_all_device_v<
              scifi_consolidate_tracks__dev_scifi_track_hits_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t>);
static_assert(all_host_or_all_device_v<
              scifi_consolidate_tracks__dev_scifi_qop_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_qop_t,
              is_muon::Parameters::dev_scifi_qop_t,
              kalman_velo_only::Parameters::dev_scifi_qop_t,
              FilterTracks::Parameters::dev_scifi_qop_t,
              VertexFit::Parameters::dev_scifi_qop_t>);
static_assert(all_host_or_all_device_v<
              scifi_consolidate_tracks__dev_scifi_states_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_states_t,
              is_muon::Parameters::dev_scifi_states_t,
              kalman_velo_only::Parameters::dev_scifi_states_t,
              FilterTracks::Parameters::dev_scifi_states_t,
              VertexFit::Parameters::dev_scifi_states_t>);
static_assert(all_host_or_all_device_v<
              scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
              scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t,
              is_muon::Parameters::dev_scifi_track_ut_indices_t,
              kalman_velo_only::Parameters::dev_scifi_track_ut_indices_t,
              FilterTracks::Parameters::dev_scifi_track_ut_indices_t,
              VertexFit::Parameters::dev_scifi_track_ut_indices_t>);
static_assert(
  all_host_or_all_device_v<is_muon__dev_muon_track_occupancies_t, is_muon::Parameters::dev_muon_track_occupancies_t>);
static_assert(all_host_or_all_device_v<
              is_muon__dev_is_muon_t,
              is_muon::Parameters::dev_is_muon_t,
              kalman_velo_only::Parameters::dev_is_muon_t>);
static_assert(all_host_or_all_device_v<
              kalman_velo_only__dev_kf_tracks_t,
              kalman_velo_only::Parameters::dev_kf_tracks_t,
              FilterTracks::Parameters::dev_kf_tracks_t,
              VertexFit::Parameters::dev_kf_tracks_t,
              track_mva_line::Parameters::dev_tracks_t,
              single_high_pt_muon_line::Parameters::dev_tracks_t,
              low_pt_muon_line::Parameters::dev_tracks_t,
              track_muon_mva_line::Parameters::dev_tracks_t>);
static_assert(all_host_or_all_device_v<
              kalman_velo_only__dev_kalman_pv_ipchi2_t,
              kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t,
              FilterTracks::Parameters::dev_kalman_pv_ipchi2_t,
              VertexFit::Parameters::dev_kalman_pv_ipchi2_t>);
static_assert(all_host_or_all_device_v<
              filter_tracks__dev_sv_atomics_t,
              FilterTracks::Parameters::dev_sv_atomics_t,
              host_prefix_sum::Parameters::dev_input_buffer_t>);
static_assert(all_host_or_all_device_v<
              filter_tracks__dev_svs_trk1_idx_t,
              FilterTracks::Parameters::dev_svs_trk1_idx_t,
              VertexFit::Parameters::dev_svs_trk1_idx_t>);
static_assert(all_host_or_all_device_v<
              filter_tracks__dev_svs_trk2_idx_t,
              FilterTracks::Parameters::dev_svs_trk2_idx_t,
              VertexFit::Parameters::dev_svs_trk2_idx_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_secondary_vertices__host_total_sum_holder_t,
              host_prefix_sum::Parameters::host_total_sum_holder_t,
              VertexFit::Parameters::host_number_of_svs_t,
              two_track_preprocess::Parameters::host_number_of_svs_t,
              two_track_evaluator::Parameters::host_number_of_svs_t,
              two_track_mva_line::Parameters::host_number_of_svs_t,
              two_track_catboost_line::Parameters::host_number_of_svs_t,
              d2kk_line::Parameters::host_number_of_svs_t,
              d2kpi_line::Parameters::host_number_of_svs_t,
              d2pipi_line::Parameters::host_number_of_svs_t,
              di_muon_mass_line::Parameters::host_number_of_svs_t,
              di_muon_mass_line::Parameters::host_number_of_svs_t,
              di_muon_soft_line::Parameters::host_number_of_svs_t,
              low_pt_di_muon_line::Parameters::host_number_of_svs_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_secondary_vertices__host_output_buffer_t,
              host_prefix_sum::Parameters::host_output_buffer_t>);
static_assert(all_host_or_all_device_v<
              prefix_sum_secondary_vertices__dev_output_buffer_t,
              host_prefix_sum::Parameters::dev_output_buffer_t,
              VertexFit::Parameters::dev_sv_offsets_t,
              two_track_preprocess::Parameters::dev_sv_offsets_t,
              two_track_mva_line::Parameters::dev_sv_offsets_t,
              two_track_catboost_line::Parameters::dev_sv_offsets_t,
              d2kk_line::Parameters::dev_sv_offsets_t,
              d2kpi_line::Parameters::dev_sv_offsets_t,
              d2pipi_line::Parameters::dev_sv_offsets_t,
              di_muon_mass_line::Parameters::dev_sv_offsets_t,
              di_muon_mass_line::Parameters::dev_sv_offsets_t,
              di_muon_soft_line::Parameters::dev_sv_offsets_t,
              low_pt_di_muon_line::Parameters::dev_sv_offsets_t>);
static_assert(all_host_or_all_device_v<
              fit_secondary_vertices__dev_consolidated_svs_t,
              VertexFit::Parameters::dev_consolidated_svs_t,
              two_track_preprocess::Parameters::dev_consolidated_svs_t,
              two_track_mva_line::Parameters::dev_svs_t,
              two_track_catboost_line::Parameters::dev_svs_t,
              d2kk_line::Parameters::dev_svs_t,
              d2kpi_line::Parameters::dev_svs_t,
              d2pipi_line::Parameters::dev_svs_t,
              di_muon_mass_line::Parameters::dev_svs_t,
              di_muon_mass_line::Parameters::dev_svs_t,
              di_muon_soft_line::Parameters::dev_svs_t,
              low_pt_di_muon_line::Parameters::dev_svs_t>);
static_assert(all_host_or_all_device_v<
              two_track_preprocess__dev_two_track_preprocess_output_t,
              two_track_preprocess::Parameters::dev_two_track_preprocess_output_t,
              two_track_evaluator::Parameters::dev_two_track_catboost_preprocess_output_t>);
static_assert(all_host_or_all_device_v<
              two_track_evaluator__dev_two_track_catboost_evaluation_t,
              two_track_evaluator::Parameters::dev_two_track_catboost_evaluation_t,
              two_track_catboost_line::Parameters::dev_two_track_evaluation_t>);
static_assert(all_host_or_all_device_v<
              populate_odin_banks__dev_raw_banks_t,
              data_provider::Parameters::dev_raw_banks_t,
              track_mva_line::Parameters::dev_odin_raw_input_t,
              two_track_mva_line::Parameters::dev_odin_raw_input_t,
              two_track_catboost_line::Parameters::dev_odin_raw_input_t,
              single_high_pt_muon_line::Parameters::dev_odin_raw_input_t,
              low_pt_muon_line::Parameters::dev_odin_raw_input_t,
              d2kk_line::Parameters::dev_odin_raw_input_t,
              d2kpi_line::Parameters::dev_odin_raw_input_t,
              d2pipi_line::Parameters::dev_odin_raw_input_t,
              di_muon_mass_line::Parameters::dev_odin_raw_input_t,
              di_muon_mass_line::Parameters::dev_odin_raw_input_t,
              di_muon_soft_line::Parameters::dev_odin_raw_input_t,
              low_pt_di_muon_line::Parameters::dev_odin_raw_input_t,
              track_muon_mva_line::Parameters::dev_odin_raw_input_t,
              passthrough_line::Parameters::dev_odin_raw_input_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_t,
              velo_micro_bias_line::Parameters::dev_odin_raw_input_t,
              odin_event_type_line::Parameters::dev_odin_raw_input_t,
              odin_event_type_line::Parameters::dev_odin_raw_input_t,
              passthrough_line::Parameters::dev_odin_raw_input_t,
              gather_selections::Parameters::dev_odin_raw_input_t>);
static_assert(all_host_or_all_device_v<
              populate_odin_banks__dev_raw_offsets_t,
              data_provider::Parameters::dev_raw_offsets_t,
              track_mva_line::Parameters::dev_odin_raw_input_offsets_t,
              two_track_mva_line::Parameters::dev_odin_raw_input_offsets_t,
              two_track_catboost_line::Parameters::dev_odin_raw_input_offsets_t,
              single_high_pt_muon_line::Parameters::dev_odin_raw_input_offsets_t,
              low_pt_muon_line::Parameters::dev_odin_raw_input_offsets_t,
              d2kk_line::Parameters::dev_odin_raw_input_offsets_t,
              d2kpi_line::Parameters::dev_odin_raw_input_offsets_t,
              d2pipi_line::Parameters::dev_odin_raw_input_offsets_t,
              di_muon_mass_line::Parameters::dev_odin_raw_input_offsets_t,
              di_muon_mass_line::Parameters::dev_odin_raw_input_offsets_t,
              di_muon_soft_line::Parameters::dev_odin_raw_input_offsets_t,
              low_pt_di_muon_line::Parameters::dev_odin_raw_input_offsets_t,
              track_muon_mva_line::Parameters::dev_odin_raw_input_offsets_t,
              passthrough_line::Parameters::dev_odin_raw_input_offsets_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
              beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
              velo_micro_bias_line::Parameters::dev_odin_raw_input_offsets_t,
              odin_event_type_line::Parameters::dev_odin_raw_input_offsets_t,
              odin_event_type_line::Parameters::dev_odin_raw_input_offsets_t,
              passthrough_line::Parameters::dev_odin_raw_input_offsets_t,
              gather_selections::Parameters::dev_odin_raw_input_offsets_t>);
static_assert(all_host_or_all_device_v<
              populate_odin_banks__host_raw_bank_version_t,
              data_provider::Parameters::host_raw_bank_version_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_selections_lines_offsets_t,
              gather_selections::Parameters::host_selections_lines_offsets_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_selections_offsets_t,
              gather_selections::Parameters::host_selections_offsets_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_number_of_active_lines_t,
              gather_selections::Parameters::host_number_of_active_lines_t,
              dec_reporter::Parameters::host_number_of_active_lines_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_names_of_active_lines_t,
              gather_selections::Parameters::host_names_of_active_lines_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__dev_selections_t,
              gather_selections::Parameters::dev_selections_t,
              dec_reporter::Parameters::dev_selections_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__dev_selections_offsets_t,
              gather_selections::Parameters::dev_selections_offsets_t,
              dec_reporter::Parameters::dev_selections_offsets_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__dev_number_of_active_lines_t,
              gather_selections::Parameters::dev_number_of_active_lines_t,
              dec_reporter::Parameters::dev_number_of_active_lines_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_post_scale_factors_t,
              gather_selections::Parameters::host_post_scale_factors_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__host_post_scale_hashes_t,
              gather_selections::Parameters::host_post_scale_hashes_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__dev_post_scale_factors_t,
              gather_selections::Parameters::dev_post_scale_factors_t>);
static_assert(all_host_or_all_device_v<
              gather_selections__dev_post_scale_hashes_t,
              gather_selections::Parameters::dev_post_scale_hashes_t>);
static_assert(all_host_or_all_device_v<dec_reporter__dev_dec_reports_t, dec_reporter::Parameters::dev_dec_reports_t>);

using configured_arguments_t = std::tuple<
  initialize_event_lists__host_event_list_output_t,
  initialize_event_lists__dev_event_list_output_t,
  mep_layout__host_mep_layout_t,
  mep_layout__dev_mep_layout_t,
  initialize_number_of_events__host_number_of_events_t,
  initialize_number_of_events__dev_number_of_events_t,
  host_scifi_banks__host_raw_banks_t,
  host_scifi_banks__host_raw_offsets_t,
  host_scifi_banks__host_raw_bank_version_t,
  host_ut_banks__host_raw_banks_t,
  host_ut_banks__host_raw_offsets_t,
  host_ut_banks__host_raw_bank_version_t,
  gec__host_event_list_output_t,
  gec__host_number_of_events_t,
  gec__host_number_of_selected_events_t,
  gec__dev_number_of_events_t,
  gec__dev_event_list_output_t,
  ut_banks__dev_raw_banks_t,
  ut_banks__dev_raw_offsets_t,
  ut_banks__host_raw_bank_version_t,
  ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
  prefix_sum_ut_hits__host_total_sum_holder_t,
  prefix_sum_ut_hits__host_output_buffer_t,
  prefix_sum_ut_hits__dev_output_buffer_t,
  ut_pre_decode__dev_ut_pre_decoded_hits_t,
  ut_pre_decode__dev_ut_hit_count_t,
  ut_find_permutation__dev_ut_hit_permutations_t,
  ut_decode_raw_banks_in_order__dev_ut_hits_t,
  scifi_banks__dev_raw_banks_t,
  scifi_banks__dev_raw_offsets_t,
  scifi_banks__host_raw_bank_version_t,
  scifi_calculate_cluster_count__dev_scifi_hit_count_t,
  prefix_sum_scifi_hits__host_total_sum_holder_t,
  prefix_sum_scifi_hits__host_output_buffer_t,
  prefix_sum_scifi_hits__dev_output_buffer_t,
  scifi_pre_decode__dev_cluster_references_t,
  scifi_raw_bank_decoder__dev_scifi_hits_t,
  muon_banks__dev_raw_banks_t,
  muon_banks__dev_raw_offsets_t,
  muon_banks__host_raw_bank_version_t,
  muon_calculate_srq_size__dev_muon_raw_to_hits_t,
  muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t,
  muon_srq_prefix_sum__host_total_sum_holder_t,
  muon_srq_prefix_sum__host_output_buffer_t,
  muon_srq_prefix_sum__dev_output_buffer_t,
  muon_populate_tile_and_tdc__dev_storage_tile_id_t,
  muon_populate_tile_and_tdc__dev_storage_tdc_value_t,
  muon_populate_tile_and_tdc__dev_atomics_muon_t,
  muon_add_coords_crossing_maps__dev_atomics_index_insert_t,
  muon_add_coords_crossing_maps__dev_muon_compact_hit_t,
  muon_add_coords_crossing_maps__dev_muon_tile_used_t,
  muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t,
  muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
  muon_station_ocurrence_prefix_sum__host_output_buffer_t,
  muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
  muon_populate_hits__dev_permutation_station_t,
  muon_populate_hits__dev_muon_hits_t,
  velo_banks__dev_raw_banks_t,
  velo_banks__dev_raw_offsets_t,
  velo_banks__host_raw_bank_version_t,
  velo_calculate_number_of_candidates__dev_number_of_candidates_t,
  prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
  prefix_sum_offsets_velo_candidates__host_output_buffer_t,
  prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
  velo_estimate_input_size__dev_estimated_input_size_t,
  velo_estimate_input_size__dev_module_candidate_num_t,
  velo_estimate_input_size__dev_cluster_candidates_t,
  prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
  prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
  prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
  velo_masked_clustering__dev_module_cluster_num_t,
  velo_masked_clustering__dev_velo_cluster_container_t,
  velo_masked_clustering__dev_velo_clusters_t,
  velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
  velo_calculate_phi_and_sort__dev_hit_permutation_t,
  velo_calculate_phi_and_sort__dev_hit_phi_t,
  velo_search_by_triplet__dev_tracks_t,
  velo_search_by_triplet__dev_tracklets_t,
  velo_search_by_triplet__dev_tracks_to_follow_t,
  velo_search_by_triplet__dev_three_hit_tracks_t,
  velo_search_by_triplet__dev_hit_used_t,
  velo_search_by_triplet__dev_atomics_velo_t,
  velo_search_by_triplet__dev_rel_indices_t,
  velo_search_by_triplet__dev_number_of_velo_tracks_t,
  velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
  velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
  prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
  prefix_sum_offsets_velo_tracks__host_output_buffer_t,
  prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
  velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
  velo_copy_track_hit_number__dev_velo_track_hit_number_t,
  velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
  prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
  prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
  prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
  velo_consolidate_tracks__dev_accepted_velo_tracks_t,
  velo_consolidate_tracks__dev_velo_track_hits_t,
  velo_kalman_filter__dev_velo_kalman_beamline_states_t,
  velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
  velo_kalman_filter__dev_velo_lmsfit_beamline_states_t,
  ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
  ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
  pv_beamline_extrapolate__dev_pvtracks_t,
  pv_beamline_extrapolate__dev_pvtrack_z_t,
  pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t,
  pv_beamline_histo__dev_zhisto_t,
  ut_search_windows__dev_ut_windows_layers_t,
  ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
  ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
  compass_ut__dev_ut_tracks_t,
  compass_ut__dev_atomics_ut_t,
  prefix_sum_ut_tracks__host_total_sum_holder_t,
  prefix_sum_ut_tracks__host_output_buffer_t,
  prefix_sum_ut_tracks__dev_output_buffer_t,
  ut_copy_track_hit_number__dev_ut_track_hit_number_t,
  prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
  prefix_sum_ut_track_hit_number__host_output_buffer_t,
  prefix_sum_ut_track_hit_number__dev_output_buffer_t,
  ut_consolidate_tracks__dev_ut_track_hits_t,
  ut_consolidate_tracks__dev_ut_qop_t,
  ut_consolidate_tracks__dev_ut_x_t,
  ut_consolidate_tracks__dev_ut_tx_t,
  ut_consolidate_tracks__dev_ut_z_t,
  ut_consolidate_tracks__dev_ut_track_velo_indices_t,
  lf_search_initial_windows__dev_scifi_lf_initial_windows_t,
  lf_search_initial_windows__dev_ut_states_t,
  lf_search_initial_windows__dev_scifi_lf_process_track_t,
  pv_beamline_peak__dev_zpeaks_t,
  pv_beamline_peak__dev_number_of_zpeaks_t,
  pv_beamline_calculate_denom__dev_pvtracks_denom_t,
  pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
  pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
  pv_beamline_cleanup__dev_multi_final_vertices_t,
  pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
  velo_pv_ip__dev_velo_pv_ip_t,
  lf_triplet_seeding__dev_scifi_lf_found_triplets_t,
  lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t,
  lf_create_tracks__dev_scifi_lf_tracks_t,
  lf_create_tracks__dev_scifi_lf_atomics_t,
  lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t,
  lf_create_tracks__dev_scifi_lf_parametrization_t,
  lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t,
  lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t,
  lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t,
  lf_quality_filter__dev_lf_quality_of_tracks_t,
  lf_quality_filter__dev_atomics_scifi_t,
  lf_quality_filter__dev_scifi_tracks_t,
  lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t,
  lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t,
  prefix_sum_forward_tracks__host_total_sum_holder_t,
  prefix_sum_forward_tracks__host_output_buffer_t,
  prefix_sum_forward_tracks__dev_output_buffer_t,
  scifi_copy_track_hit_number__dev_scifi_track_hit_number_t,
  prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
  prefix_sum_scifi_track_hit_number__host_output_buffer_t,
  prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
  scifi_consolidate_tracks__dev_scifi_track_hits_t,
  scifi_consolidate_tracks__dev_scifi_qop_t,
  scifi_consolidate_tracks__dev_scifi_states_t,
  scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
  is_muon__dev_muon_track_occupancies_t,
  is_muon__dev_is_muon_t,
  kalman_velo_only__dev_kf_tracks_t,
  kalman_velo_only__dev_kalman_pv_ipchi2_t,
  filter_tracks__dev_sv_atomics_t,
  filter_tracks__dev_svs_trk1_idx_t,
  filter_tracks__dev_svs_trk2_idx_t,
  prefix_sum_secondary_vertices__host_total_sum_holder_t,
  prefix_sum_secondary_vertices__host_output_buffer_t,
  prefix_sum_secondary_vertices__dev_output_buffer_t,
  fit_secondary_vertices__dev_consolidated_svs_t,
  two_track_preprocess__dev_two_track_preprocess_output_t,
  two_track_evaluator__dev_two_track_catboost_evaluation_t,
  populate_odin_banks__dev_raw_banks_t,
  populate_odin_banks__dev_raw_offsets_t,
  populate_odin_banks__host_raw_bank_version_t,
  Hlt1TrackMVA__dev_decisions_t,
  Hlt1TrackMVA__dev_decisions_offsets_t,
  Hlt1TrackMVA__host_post_scaler_t,
  Hlt1TrackMVA__host_post_scaler_hash_t,
  Hlt1TwoTrackMVA__dev_decisions_t,
  Hlt1TwoTrackMVA__dev_decisions_offsets_t,
  Hlt1TwoTrackMVA__host_post_scaler_t,
  Hlt1TwoTrackMVA__host_post_scaler_hash_t,
  Hlt1TwoTrackCatBoost__dev_decisions_t,
  Hlt1TwoTrackCatBoost__dev_decisions_offsets_t,
  Hlt1TwoTrackCatBoost__host_post_scaler_t,
  Hlt1TwoTrackCatBoost__host_post_scaler_hash_t,
  Hlt1SingleHighPtMuon__dev_decisions_t,
  Hlt1SingleHighPtMuon__dev_decisions_offsets_t,
  Hlt1SingleHighPtMuon__host_post_scaler_t,
  Hlt1SingleHighPtMuon__host_post_scaler_hash_t,
  Hlt1LowPtMuon__dev_decisions_t,
  Hlt1LowPtMuon__dev_decisions_offsets_t,
  Hlt1LowPtMuon__host_post_scaler_t,
  Hlt1LowPtMuon__host_post_scaler_hash_t,
  Hlt1D2KK__dev_decisions_t,
  Hlt1D2KK__dev_decisions_offsets_t,
  Hlt1D2KK__host_post_scaler_t,
  Hlt1D2KK__host_post_scaler_hash_t,
  Hlt1D2KPi__dev_decisions_t,
  Hlt1D2KPi__dev_decisions_offsets_t,
  Hlt1D2KPi__host_post_scaler_t,
  Hlt1D2KPi__host_post_scaler_hash_t,
  Hlt1D2PiPi__dev_decisions_t,
  Hlt1D2PiPi__dev_decisions_offsets_t,
  Hlt1D2PiPi__host_post_scaler_t,
  Hlt1D2PiPi__host_post_scaler_hash_t,
  Hlt1DiMuonHighMass__dev_decisions_t,
  Hlt1DiMuonHighMass__dev_decisions_offsets_t,
  Hlt1DiMuonHighMass__host_post_scaler_t,
  Hlt1DiMuonHighMass__host_post_scaler_hash_t,
  Hlt1DiMuonLowMass__dev_decisions_t,
  Hlt1DiMuonLowMass__dev_decisions_offsets_t,
  Hlt1DiMuonLowMass__host_post_scaler_t,
  Hlt1DiMuonLowMass__host_post_scaler_hash_t,
  Hlt1DiMuonSoft__dev_decisions_t,
  Hlt1DiMuonSoft__dev_decisions_offsets_t,
  Hlt1DiMuonSoft__host_post_scaler_t,
  Hlt1DiMuonSoft__host_post_scaler_hash_t,
  Hlt1LowPtDiMuon__dev_decisions_t,
  Hlt1LowPtDiMuon__dev_decisions_offsets_t,
  Hlt1LowPtDiMuon__host_post_scaler_t,
  Hlt1LowPtDiMuon__host_post_scaler_hash_t,
  Hlt1TrackMuonMVA__dev_decisions_t,
  Hlt1TrackMuonMVA__dev_decisions_offsets_t,
  Hlt1TrackMuonMVA__host_post_scaler_t,
  Hlt1TrackMuonMVA__host_post_scaler_hash_t,
  Hlt1GECPassthrough__dev_decisions_t,
  Hlt1GECPassthrough__dev_decisions_offsets_t,
  Hlt1GECPassthrough__host_post_scaler_t,
  Hlt1GECPassthrough__host_post_scaler_hash_t,
  Hlt1NoBeam__dev_decisions_t,
  Hlt1NoBeam__dev_decisions_offsets_t,
  Hlt1NoBeam__host_post_scaler_t,
  Hlt1NoBeam__host_post_scaler_hash_t,
  Hlt1BeamOne__dev_decisions_t,
  Hlt1BeamOne__dev_decisions_offsets_t,
  Hlt1BeamOne__host_post_scaler_t,
  Hlt1BeamOne__host_post_scaler_hash_t,
  Hlt1BeamTwo__dev_decisions_t,
  Hlt1BeamTwo__dev_decisions_offsets_t,
  Hlt1BeamTwo__host_post_scaler_t,
  Hlt1BeamTwo__host_post_scaler_hash_t,
  Hlt1BothBeams__dev_decisions_t,
  Hlt1BothBeams__dev_decisions_offsets_t,
  Hlt1BothBeams__host_post_scaler_t,
  Hlt1BothBeams__host_post_scaler_hash_t,
  Hlt1VeloMicroBias__dev_decisions_t,
  Hlt1VeloMicroBias__dev_decisions_offsets_t,
  Hlt1VeloMicroBias__host_post_scaler_t,
  Hlt1VeloMicroBias__host_post_scaler_hash_t,
  Hlt1ODINLumi__dev_decisions_t,
  Hlt1ODINLumi__dev_decisions_offsets_t,
  Hlt1ODINLumi__host_post_scaler_t,
  Hlt1ODINLumi__host_post_scaler_hash_t,
  Hlt1ODINNoBias__dev_decisions_t,
  Hlt1ODINNoBias__dev_decisions_offsets_t,
  Hlt1ODINNoBias__host_post_scaler_t,
  Hlt1ODINNoBias__host_post_scaler_hash_t,
  Hlt1Passthrough__dev_decisions_t,
  Hlt1Passthrough__dev_decisions_offsets_t,
  Hlt1Passthrough__host_post_scaler_t,
  Hlt1Passthrough__host_post_scaler_hash_t,
  gather_selections__host_selections_lines_offsets_t,
  gather_selections__host_selections_offsets_t,
  gather_selections__host_number_of_active_lines_t,
  gather_selections__host_names_of_active_lines_t,
  gather_selections__dev_selections_t,
  gather_selections__dev_selections_offsets_t,
  gather_selections__dev_number_of_active_lines_t,
  gather_selections__host_post_scale_factors_t,
  gather_selections__host_post_scale_hashes_t,
  gather_selections__dev_post_scale_factors_t,
  gather_selections__dev_post_scale_hashes_t,
  dec_reporter__dev_dec_reports_t>;

using configured_sequence_t = std::tuple<
  host_init_event_list::host_init_event_list_t,
  layout_provider::layout_provider_t,
  host_init_number_of_events::host_init_number_of_events_t,
  host_data_provider::host_data_provider_t,
  host_data_provider::host_data_provider_t,
  host_global_event_cut::host_global_event_cut_t,
  data_provider::data_provider_t,
  ut_calculate_number_of_hits::ut_calculate_number_of_hits_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_pre_decode::ut_pre_decode_t,
  ut_find_permutation::ut_find_permutation_t,
  ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_t,
  data_provider::data_provider_t,
  scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_pre_decode_v4::scifi_pre_decode_v4_t,
  scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_t,
  data_provider::data_provider_t,
  muon_calculate_srq_size::muon_calculate_srq_size_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t,
  muon_add_coords_crossing_maps::muon_add_coords_crossing_maps_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_hits::muon_populate_hits_t,
  data_provider::data_provider_t,
  velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_estimate_input_size::velo_estimate_input_size_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_masked_clustering::velo_masked_clustering_t,
  velo_calculate_phi_and_sort::velo_calculate_phi_and_sort_t,
  velo_search_by_triplet::velo_search_by_triplet_t,
  velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_copy_track_hit_number::velo_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_consolidate_tracks::velo_consolidate_tracks_t,
  velo_kalman_filter::velo_kalman_filter_t,
  ut_select_velo_tracks::ut_select_velo_tracks_t,
  pv_beamline_extrapolate::pv_beamline_extrapolate_t,
  pv_beamline_histo::pv_beamline_histo_t,
  ut_search_windows::ut_search_windows_t,
  ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows_t,
  compass_ut::compass_ut_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_copy_track_hit_number::ut_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_consolidate_tracks::ut_consolidate_tracks_t,
  lf_search_initial_windows::lf_search_initial_windows_t,
  pv_beamline_peak::pv_beamline_peak_t,
  pv_beamline_calculate_denom::pv_beamline_calculate_denom_t,
  pv_beamline_multi_fitter::pv_beamline_multi_fitter_t,
  pv_beamline_cleanup::pv_beamline_cleanup_t,
  velo_pv_ip::velo_pv_ip_t,
  lf_triplet_seeding::lf_triplet_seeding_t,
  lf_create_tracks::lf_create_tracks_t,
  lf_quality_filter_length::lf_quality_filter_length_t,
  lf_quality_filter::lf_quality_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_copy_track_hit_number::scifi_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_consolidate_tracks::scifi_consolidate_tracks_t,
  is_muon::is_muon_t,
  kalman_velo_only::kalman_velo_only_t,
  FilterTracks::filter_tracks_t,
  host_prefix_sum::host_prefix_sum_t,
  VertexFit::fit_secondary_vertices_t,
  two_track_preprocess::two_track_preprocess_t,
  two_track_evaluator::two_track_evaluator_t,
  data_provider::data_provider_t,
  track_mva_line::track_mva_line_t,
  two_track_mva_line::two_track_mva_line_t,
  two_track_catboost_line::two_track_catboost_line_t,
  single_high_pt_muon_line::single_high_pt_muon_line_t,
  low_pt_muon_line::low_pt_muon_line_t,
  d2kk_line::d2kk_line_t,
  d2kpi_line::d2kpi_line_t,
  d2pipi_line::d2pipi_line_t,
  di_muon_mass_line::di_muon_mass_line_t,
  di_muon_mass_line::di_muon_mass_line_t,
  di_muon_soft_line::di_muon_soft_line_t,
  low_pt_di_muon_line::low_pt_di_muon_line_t,
  track_muon_mva_line::track_muon_mva_line_t,
  passthrough_line::passthrough_line_t,
  beam_crossing_line::beam_crossing_line_t,
  beam_crossing_line::beam_crossing_line_t,
  beam_crossing_line::beam_crossing_line_t,
  beam_crossing_line::beam_crossing_line_t,
  velo_micro_bias_line::velo_micro_bias_line_t,
  odin_event_type_line::odin_event_type_line_t,
  odin_event_type_line::odin_event_type_line_t,
  passthrough_line::passthrough_line_t,
  gather_selections::gather_selections_t,
  dec_reporter::dec_reporter_t>;

using configured_sequence_arguments_t = std::tuple<
  std::tuple<initialize_event_lists__host_event_list_output_t, initialize_event_lists__dev_event_list_output_t>,
  std::tuple<mep_layout__host_mep_layout_t, mep_layout__dev_mep_layout_t>,
  std::tuple<initialize_number_of_events__host_number_of_events_t, initialize_number_of_events__dev_number_of_events_t>,
  std::tuple<
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_bank_version_t>,
  std::
    tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t, host_ut_banks__host_raw_bank_version_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_bank_version_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    gec__host_event_list_output_t,
    gec__host_number_of_events_t,
    gec__host_number_of_selected_events_t,
    gec__dev_number_of_events_t,
    gec__dev_event_list_output_t>,
  std::tuple<ut_banks__dev_raw_banks_t, ut_banks__dev_raw_offsets_t, ut_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    ut_banks__host_raw_bank_version_t,
    gec__dev_event_list_output_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
    prefix_sum_ut_hits__host_output_buffer_t,
    prefix_sum_ut_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    ut_banks__host_raw_bank_version_t,
    initialize_number_of_events__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    gec__dev_event_list_output_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_pre_decode__dev_ut_hit_count_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_number_of_events__dev_number_of_events_t,
    gec__dev_event_list_output_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    ut_banks__host_raw_bank_version_t,
    initialize_number_of_events__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    gec__dev_event_list_output_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<scifi_banks__dev_raw_banks_t, scifi_banks__dev_raw_offsets_t, scifi_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    scifi_calculate_cluster_count__dev_scifi_hit_count_t>,
  std::tuple<
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_calculate_cluster_count__dev_scifi_hit_count_t,
    prefix_sum_scifi_hits__host_output_buffer_t,
    prefix_sum_scifi_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    gec__dev_event_list_output_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode__dev_cluster_references_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode__dev_cluster_references_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t>,
  std::tuple<muon_banks__dev_raw_banks_t, muon_banks__dev_raw_offsets_t, muon_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size__dev_muon_raw_to_hits_t,
    muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t>,
  std::tuple<
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t,
    muon_srq_prefix_sum__host_output_buffer_t,
    muon_srq_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc__dev_storage_tdc_value_t,
    muon_populate_tile_and_tdc__dev_atomics_muon_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc__dev_storage_tile_id_t,
    muon_calculate_srq_size__dev_muon_raw_to_hits_t,
    gec__dev_event_list_output_t,
    muon_add_coords_crossing_maps__dev_atomics_index_insert_t,
    muon_add_coords_crossing_maps__dev_muon_compact_hit_t,
    muon_add_coords_crossing_maps__dev_muon_tile_used_t,
    muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t>,
  std::tuple<
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t,
    muon_station_ocurrence_prefix_sum__host_output_buffer_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    muon_populate_tile_and_tdc__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc__dev_storage_tdc_value_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_add_coords_crossing_maps__dev_muon_compact_hit_t,
    muon_calculate_srq_size__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_hits__dev_permutation_station_t,
    muon_populate_hits__dev_muon_hits_t>,
  std::tuple<velo_banks__dev_raw_banks_t, velo_banks__dev_raw_offsets_t, velo_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_event_lists__dev_event_list_output_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t>,
  std::tuple<
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t,
    prefix_sum_offsets_velo_candidates__host_output_buffer_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    initialize_event_lists__dev_event_list_output_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    prefix_sum_offsets_estimated_input_size__host_output_buffer_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_number_of_events__host_number_of_events_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t,
    initialize_event_lists__dev_event_list_output_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_event_lists__dev_event_list_output_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    velo_calculate_phi_and_sort__dev_hit_permutation_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_event_lists__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t,
    velo_search_by_triplet__dev_tracks_t,
    velo_search_by_triplet__dev_tracklets_t,
    velo_search_by_triplet__dev_tracks_to_follow_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_hit_used_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_rel_indices_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    velo_masked_clustering__dev_velo_clusters_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_event_lists__dev_event_list_output_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_hit_used_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>,
  std::tuple<
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    prefix_sum_offsets_velo_tracks__host_output_buffer_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_velo_track_hit_number_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t>,
  std::tuple<
    prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
    velo_copy_track_hit_number__dev_velo_track_hit_number_t,
    prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    velo_consolidate_tracks__dev_velo_track_hits_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    gec__dev_event_list_output_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_extrapolate__dev_pvtrack_z_t,
    pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_histo__dev_zhisto_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    gec__dev_event_list_output_t,
    ut_search_windows__dev_ut_windows_layers_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    ut_search_windows__dev_ut_windows_layers_t,
    gec__dev_event_list_output_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_number_of_events__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_lmsfit_beamline_states_t,
    ut_search_windows__dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
    gec__dev_event_list_output_t,
    compass_ut__dev_ut_tracks_t,
    compass_ut__dev_atomics_ut_t>,
  std::tuple<
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_atomics_ut_t,
    prefix_sum_ut_tracks__host_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_ut_tracks_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t>,
  std::tuple<
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t,
    prefix_sum_ut_track_hit_number__host_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    initialize_number_of_events__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    compass_ut__dev_ut_tracks_t,
    gec__dev_event_list_output_t,
    ut_consolidate_tracks__dev_ut_track_hits_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_search_initial_windows__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows__dev_ut_states_t,
    lf_search_initial_windows__dev_scifi_lf_process_track_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    pv_beamline_histo__dev_zhisto_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t,
    pv_beamline_calculate_denom__dev_pvtracks_denom_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_calculate_denom__dev_pvtracks_denom_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t,
    pv_beamline_extrapolate__dev_pvtrack_z_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
    velo_pv_ip__dev_velo_pv_ip_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows__dev_ut_states_t,
    lf_search_initial_windows__dev_scifi_lf_process_track_t,
    lf_triplet_seeding__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_search_initial_windows__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows__dev_scifi_lf_process_track_t,
    lf_triplet_seeding__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows__dev_ut_states_t,
    lf_create_tracks__dev_scifi_lf_tracks_t,
    lf_create_tracks__dev_scifi_lf_atomics_t,
    lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t,
    lf_create_tracks__dev_scifi_lf_parametrization_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_create_tracks__dev_scifi_lf_tracks_t,
    lf_create_tracks__dev_scifi_lf_atomics_t,
    lf_create_tracks__dev_scifi_lf_parametrization_t,
    lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t,
    lf_search_initial_windows__dev_ut_states_t,
    lf_quality_filter__dev_lf_quality_of_tracks_t,
    lf_quality_filter__dev_atomics_scifi_t,
    lf_quality_filter__dev_scifi_tracks_t,
    lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t,
    lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t>,
  std::tuple<
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    lf_quality_filter__dev_atomics_scifi_t,
    prefix_sum_forward_tracks__host_output_buffer_t,
    prefix_sum_forward_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    lf_quality_filter__dev_scifi_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    scifi_copy_track_hit_number__dev_scifi_track_hit_number_t>,
  std::tuple<
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    scifi_copy_track_hit_number__dev_scifi_track_hit_number_t,
    prefix_sum_scifi_track_hit_number__host_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_kalman_filter__dev_velo_kalman_endvelo_states_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    scifi_raw_bank_decoder__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_quality_filter__dev_scifi_tracks_t,
    lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks__dev_scifi_track_hits_t,
    scifi_consolidate_tracks__dev_scifi_qop_t,
    scifi_consolidate_tracks__dev_scifi_states_t,
    scifi_consolidate_tracks__dev_scifi_track_ut_indices_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks__dev_scifi_qop_t,
    scifi_consolidate_tracks__dev_scifi_states_t,
    scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_populate_hits__dev_muon_hits_t,
    is_muon__dev_muon_track_occupancies_t,
    is_muon__dev_is_muon_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks__dev_scifi_qop_t,
    scifi_consolidate_tracks__dev_scifi_states_t,
    scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
    velo_pv_ip__dev_velo_pv_ip_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
    is_muon__dev_is_muon_t,
    kalman_velo_only__dev_kf_tracks_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks__dev_scifi_qop_t,
    scifi_consolidate_tracks__dev_scifi_states_t,
    scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t,
    filter_tracks__dev_sv_atomics_t,
    filter_tracks__dev_svs_trk1_idx_t,
    filter_tracks__dev_svs_trk2_idx_t>,
  std::tuple<
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    filter_tracks__dev_sv_atomics_t,
    prefix_sum_secondary_vertices__host_output_buffer_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    gec__dev_event_list_output_t,
    initialize_number_of_events__dev_number_of_events_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks__dev_scifi_qop_t,
    scifi_consolidate_tracks__dev_scifi_states_t,
    scifi_consolidate_tracks__dev_scifi_track_ut_indices_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t,
    filter_tracks__dev_svs_trk1_idx_t,
    filter_tracks__dev_svs_trk2_idx_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    fit_secondary_vertices__dev_consolidated_svs_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    two_track_preprocess__dev_two_track_preprocess_output_t>,
  std::tuple<
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    two_track_preprocess__dev_two_track_preprocess_output_t,
    two_track_evaluator__dev_two_track_catboost_evaluation_t>,
  std::tuple<
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    populate_odin_banks__host_raw_bank_version_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1TrackMVA__dev_decisions_t,
    Hlt1TrackMVA__dev_decisions_offsets_t,
    Hlt1TrackMVA__host_post_scaler_t,
    Hlt1TrackMVA__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1TwoTrackMVA__dev_decisions_t,
    Hlt1TwoTrackMVA__dev_decisions_offsets_t,
    Hlt1TwoTrackMVA__host_post_scaler_t,
    Hlt1TwoTrackMVA__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    two_track_evaluator__dev_two_track_catboost_evaluation_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1TwoTrackCatBoost__dev_decisions_t,
    Hlt1TwoTrackCatBoost__dev_decisions_offsets_t,
    Hlt1TwoTrackCatBoost__host_post_scaler_t,
    Hlt1TwoTrackCatBoost__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1SingleHighPtMuon__dev_decisions_t,
    Hlt1SingleHighPtMuon__dev_decisions_offsets_t,
    Hlt1SingleHighPtMuon__host_post_scaler_t,
    Hlt1SingleHighPtMuon__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1LowPtMuon__dev_decisions_t,
    Hlt1LowPtMuon__dev_decisions_offsets_t,
    Hlt1LowPtMuon__host_post_scaler_t,
    Hlt1LowPtMuon__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1D2KK__dev_decisions_t,
    Hlt1D2KK__dev_decisions_offsets_t,
    Hlt1D2KK__host_post_scaler_t,
    Hlt1D2KK__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1D2KPi__dev_decisions_t,
    Hlt1D2KPi__dev_decisions_offsets_t,
    Hlt1D2KPi__host_post_scaler_t,
    Hlt1D2KPi__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1D2PiPi__dev_decisions_t,
    Hlt1D2PiPi__dev_decisions_offsets_t,
    Hlt1D2PiPi__host_post_scaler_t,
    Hlt1D2PiPi__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1DiMuonHighMass__dev_decisions_t,
    Hlt1DiMuonHighMass__dev_decisions_offsets_t,
    Hlt1DiMuonHighMass__host_post_scaler_t,
    Hlt1DiMuonHighMass__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1DiMuonLowMass__dev_decisions_t,
    Hlt1DiMuonLowMass__dev_decisions_offsets_t,
    Hlt1DiMuonLowMass__host_post_scaler_t,
    Hlt1DiMuonLowMass__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1DiMuonSoft__dev_decisions_t,
    Hlt1DiMuonSoft__dev_decisions_offsets_t,
    Hlt1DiMuonSoft__host_post_scaler_t,
    Hlt1DiMuonSoft__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1LowPtDiMuon__dev_decisions_t,
    Hlt1LowPtDiMuon__dev_decisions_offsets_t,
    Hlt1LowPtDiMuon__host_post_scaler_t,
    Hlt1LowPtDiMuon__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1TrackMuonMVA__dev_decisions_t,
    Hlt1TrackMuonMVA__dev_decisions_offsets_t,
    Hlt1TrackMuonMVA__host_post_scaler_t,
    Hlt1TrackMuonMVA__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_number_of_events__dev_number_of_events_t,
    gec__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1GECPassthrough__dev_decisions_t,
    Hlt1GECPassthrough__dev_decisions_offsets_t,
    Hlt1GECPassthrough__host_post_scaler_t,
    Hlt1GECPassthrough__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1NoBeam__dev_decisions_t,
    Hlt1NoBeam__dev_decisions_offsets_t,
    Hlt1NoBeam__host_post_scaler_t,
    Hlt1NoBeam__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1BeamOne__dev_decisions_t,
    Hlt1BeamOne__dev_decisions_offsets_t,
    Hlt1BeamOne__host_post_scaler_t,
    Hlt1BeamOne__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1BeamTwo__dev_decisions_t,
    Hlt1BeamTwo__dev_decisions_offsets_t,
    Hlt1BeamTwo__host_post_scaler_t,
    Hlt1BeamTwo__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1BothBeams__dev_decisions_t,
    Hlt1BothBeams__dev_decisions_offsets_t,
    Hlt1BothBeams__host_post_scaler_t,
    Hlt1BothBeams__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_number_of_events__dev_number_of_events_t,
    initialize_event_lists__dev_event_list_output_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1VeloMicroBias__dev_decisions_t,
    Hlt1VeloMicroBias__dev_decisions_offsets_t,
    Hlt1VeloMicroBias__host_post_scaler_t,
    Hlt1VeloMicroBias__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1ODINLumi__dev_decisions_t,
    Hlt1ODINLumi__dev_decisions_offsets_t,
    Hlt1ODINLumi__host_post_scaler_t,
    Hlt1ODINLumi__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    mep_layout__dev_mep_layout_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    Hlt1ODINNoBias__dev_decisions_t,
    Hlt1ODINNoBias__dev_decisions_offsets_t,
    Hlt1ODINNoBias__host_post_scaler_t,
    Hlt1ODINNoBias__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    initialize_number_of_events__dev_number_of_events_t,
    initialize_event_lists__dev_event_list_output_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    mep_layout__dev_mep_layout_t,
    Hlt1Passthrough__dev_decisions_t,
    Hlt1Passthrough__dev_decisions_offsets_t,
    Hlt1Passthrough__host_post_scaler_t,
    Hlt1Passthrough__host_post_scaler_hash_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gather_selections__host_selections_lines_offsets_t,
    gather_selections__host_selections_offsets_t,
    gather_selections__host_number_of_active_lines_t,
    gather_selections__host_names_of_active_lines_t,
    mep_layout__dev_mep_layout_t,
    Hlt1TrackMVA__dev_decisions_t,
    Hlt1TwoTrackMVA__dev_decisions_t,
    Hlt1TwoTrackCatBoost__dev_decisions_t,
    Hlt1SingleHighPtMuon__dev_decisions_t,
    Hlt1LowPtMuon__dev_decisions_t,
    Hlt1D2KK__dev_decisions_t,
    Hlt1D2KPi__dev_decisions_t,
    Hlt1D2PiPi__dev_decisions_t,
    Hlt1DiMuonHighMass__dev_decisions_t,
    Hlt1DiMuonLowMass__dev_decisions_t,
    Hlt1DiMuonSoft__dev_decisions_t,
    Hlt1LowPtDiMuon__dev_decisions_t,
    Hlt1TrackMuonMVA__dev_decisions_t,
    Hlt1GECPassthrough__dev_decisions_t,
    Hlt1NoBeam__dev_decisions_t,
    Hlt1BeamOne__dev_decisions_t,
    Hlt1BeamTwo__dev_decisions_t,
    Hlt1BothBeams__dev_decisions_t,
    Hlt1VeloMicroBias__dev_decisions_t,
    Hlt1ODINLumi__dev_decisions_t,
    Hlt1ODINNoBias__dev_decisions_t,
    Hlt1Passthrough__dev_decisions_t,
    Hlt1TrackMVA__dev_decisions_offsets_t,
    Hlt1TwoTrackMVA__dev_decisions_offsets_t,
    Hlt1TwoTrackCatBoost__dev_decisions_offsets_t,
    Hlt1SingleHighPtMuon__dev_decisions_offsets_t,
    Hlt1LowPtMuon__dev_decisions_offsets_t,
    Hlt1D2KK__dev_decisions_offsets_t,
    Hlt1D2KPi__dev_decisions_offsets_t,
    Hlt1D2PiPi__dev_decisions_offsets_t,
    Hlt1DiMuonHighMass__dev_decisions_offsets_t,
    Hlt1DiMuonLowMass__dev_decisions_offsets_t,
    Hlt1DiMuonSoft__dev_decisions_offsets_t,
    Hlt1LowPtDiMuon__dev_decisions_offsets_t,
    Hlt1TrackMuonMVA__dev_decisions_offsets_t,
    Hlt1GECPassthrough__dev_decisions_offsets_t,
    Hlt1NoBeam__dev_decisions_offsets_t,
    Hlt1BeamOne__dev_decisions_offsets_t,
    Hlt1BeamTwo__dev_decisions_offsets_t,
    Hlt1BothBeams__dev_decisions_offsets_t,
    Hlt1VeloMicroBias__dev_decisions_offsets_t,
    Hlt1ODINLumi__dev_decisions_offsets_t,
    Hlt1ODINNoBias__dev_decisions_offsets_t,
    Hlt1Passthrough__dev_decisions_offsets_t,
    Hlt1TrackMVA__host_post_scaler_t,
    Hlt1TwoTrackMVA__host_post_scaler_t,
    Hlt1TwoTrackCatBoost__host_post_scaler_t,
    Hlt1SingleHighPtMuon__host_post_scaler_t,
    Hlt1LowPtMuon__host_post_scaler_t,
    Hlt1D2KK__host_post_scaler_t,
    Hlt1D2KPi__host_post_scaler_t,
    Hlt1D2PiPi__host_post_scaler_t,
    Hlt1DiMuonHighMass__host_post_scaler_t,
    Hlt1DiMuonLowMass__host_post_scaler_t,
    Hlt1DiMuonSoft__host_post_scaler_t,
    Hlt1LowPtDiMuon__host_post_scaler_t,
    Hlt1TrackMuonMVA__host_post_scaler_t,
    Hlt1GECPassthrough__host_post_scaler_t,
    Hlt1NoBeam__host_post_scaler_t,
    Hlt1BeamOne__host_post_scaler_t,
    Hlt1BeamTwo__host_post_scaler_t,
    Hlt1BothBeams__host_post_scaler_t,
    Hlt1VeloMicroBias__host_post_scaler_t,
    Hlt1ODINLumi__host_post_scaler_t,
    Hlt1ODINNoBias__host_post_scaler_t,
    Hlt1Passthrough__host_post_scaler_t,
    Hlt1TrackMVA__host_post_scaler_hash_t,
    Hlt1TwoTrackMVA__host_post_scaler_hash_t,
    Hlt1TwoTrackCatBoost__host_post_scaler_hash_t,
    Hlt1SingleHighPtMuon__host_post_scaler_hash_t,
    Hlt1LowPtMuon__host_post_scaler_hash_t,
    Hlt1D2KK__host_post_scaler_hash_t,
    Hlt1D2KPi__host_post_scaler_hash_t,
    Hlt1D2PiPi__host_post_scaler_hash_t,
    Hlt1DiMuonHighMass__host_post_scaler_hash_t,
    Hlt1DiMuonLowMass__host_post_scaler_hash_t,
    Hlt1DiMuonSoft__host_post_scaler_hash_t,
    Hlt1LowPtDiMuon__host_post_scaler_hash_t,
    Hlt1TrackMuonMVA__host_post_scaler_hash_t,
    Hlt1GECPassthrough__host_post_scaler_hash_t,
    Hlt1NoBeam__host_post_scaler_hash_t,
    Hlt1BeamOne__host_post_scaler_hash_t,
    Hlt1BeamTwo__host_post_scaler_hash_t,
    Hlt1BothBeams__host_post_scaler_hash_t,
    Hlt1VeloMicroBias__host_post_scaler_hash_t,
    Hlt1ODINLumi__host_post_scaler_hash_t,
    Hlt1ODINNoBias__host_post_scaler_hash_t,
    Hlt1Passthrough__host_post_scaler_hash_t,
    populate_odin_banks__dev_raw_banks_t,
    populate_odin_banks__dev_raw_offsets_t,
    gather_selections__dev_selections_t,
    gather_selections__dev_selections_offsets_t,
    gather_selections__dev_number_of_active_lines_t,
    gather_selections__host_post_scale_factors_t,
    gather_selections__host_post_scale_hashes_t,
    gather_selections__dev_post_scale_factors_t,
    gather_selections__dev_post_scale_hashes_t>,
  std::tuple<
    initialize_number_of_events__host_number_of_events_t,
    gather_selections__host_number_of_active_lines_t,
    gather_selections__dev_number_of_active_lines_t,
    gather_selections__dev_selections_t,
    gather_selections__dev_selections_offsets_t,
    dec_reporter__dev_dec_reports_t>>;

constexpr auto sequence_algorithm_names = std::array {
  "initialize_event_lists",
  "mep_layout",
  "initialize_number_of_events",
  "host_scifi_banks",
  "host_ut_banks",
  "gec",
  "ut_banks",
  "ut_calculate_number_of_hits",
  "prefix_sum_ut_hits",
  "ut_pre_decode",
  "ut_find_permutation",
  "ut_decode_raw_banks_in_order",
  "scifi_banks",
  "scifi_calculate_cluster_count",
  "prefix_sum_scifi_hits",
  "scifi_pre_decode",
  "scifi_raw_bank_decoder",
  "muon_banks",
  "muon_calculate_srq_size",
  "muon_srq_prefix_sum",
  "muon_populate_tile_and_tdc",
  "muon_add_coords_crossing_maps",
  "muon_station_ocurrence_prefix_sum",
  "muon_populate_hits",
  "velo_banks",
  "velo_calculate_number_of_candidates",
  "prefix_sum_offsets_velo_candidates",
  "velo_estimate_input_size",
  "prefix_sum_offsets_estimated_input_size",
  "velo_masked_clustering",
  "velo_calculate_phi_and_sort",
  "velo_search_by_triplet",
  "velo_three_hit_tracks_filter",
  "prefix_sum_offsets_number_of_three_hit_tracks_filtered",
  "prefix_sum_offsets_velo_tracks",
  "velo_copy_track_hit_number",
  "prefix_sum_offsets_velo_track_hit_number",
  "velo_consolidate_tracks",
  "velo_kalman_filter",
  "ut_select_velo_tracks",
  "pv_beamline_extrapolate",
  "pv_beamline_histo",
  "ut_search_windows",
  "ut_select_velo_tracks_with_windows",
  "compass_ut",
  "prefix_sum_ut_tracks",
  "ut_copy_track_hit_number",
  "prefix_sum_ut_track_hit_number",
  "ut_consolidate_tracks",
  "lf_search_initial_windows",
  "pv_beamline_peak",
  "pv_beamline_calculate_denom",
  "pv_beamline_multi_fitter",
  "pv_beamline_cleanup",
  "velo_pv_ip",
  "lf_triplet_seeding",
  "lf_create_tracks",
  "lf_quality_filter_length",
  "lf_quality_filter",
  "prefix_sum_forward_tracks",
  "scifi_copy_track_hit_number",
  "prefix_sum_scifi_track_hit_number",
  "scifi_consolidate_tracks",
  "is_muon",
  "kalman_velo_only",
  "filter_tracks",
  "prefix_sum_secondary_vertices",
  "fit_secondary_vertices",
  "two_track_preprocess",
  "two_track_evaluator",
  "populate_odin_banks",
  "Hlt1TrackMVA",
  "Hlt1TwoTrackMVA",
  "Hlt1TwoTrackCatBoost",
  "Hlt1SingleHighPtMuon",
  "Hlt1LowPtMuon",
  "Hlt1D2KK",
  "Hlt1D2KPi",
  "Hlt1D2PiPi",
  "Hlt1DiMuonHighMass",
  "Hlt1DiMuonLowMass",
  "Hlt1DiMuonSoft",
  "Hlt1LowPtDiMuon",
  "Hlt1TrackMuonMVA",
  "Hlt1GECPassthrough",
  "Hlt1NoBeam",
  "Hlt1BeamOne",
  "Hlt1BeamTwo",
  "Hlt1BothBeams",
  "Hlt1VeloMicroBias",
  "Hlt1ODINLumi",
  "Hlt1ODINNoBias",
  "Hlt1Passthrough",
  "gather_selections",
  "dec_reporter"};

template<typename T>
void populate_sequence_argument_names(T& argument_manager)
{
  argument_manager.template set_name<initialize_event_lists__host_event_list_output_t>(
    "initialize_event_lists__host_event_list_output_t");
  argument_manager.template set_name<initialize_event_lists__dev_event_list_output_t>(
    "initialize_event_lists__dev_event_list_output_t");
  argument_manager.template set_name<mep_layout__host_mep_layout_t>("mep_layout__host_mep_layout_t");
  argument_manager.template set_name<mep_layout__dev_mep_layout_t>("mep_layout__dev_mep_layout_t");
  argument_manager.template set_name<initialize_number_of_events__host_number_of_events_t>(
    "initialize_number_of_events__host_number_of_events_t");
  argument_manager.template set_name<initialize_number_of_events__dev_number_of_events_t>(
    "initialize_number_of_events__dev_number_of_events_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_banks_t>("host_scifi_banks__host_raw_banks_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_offsets_t>("host_scifi_banks__host_raw_offsets_t");
  argument_manager.template set_name<host_scifi_banks__host_raw_bank_version_t>(
    "host_scifi_banks__host_raw_bank_version_t");
  argument_manager.template set_name<host_ut_banks__host_raw_banks_t>("host_ut_banks__host_raw_banks_t");
  argument_manager.template set_name<host_ut_banks__host_raw_offsets_t>("host_ut_banks__host_raw_offsets_t");
  argument_manager.template set_name<host_ut_banks__host_raw_bank_version_t>("host_ut_banks__host_raw_bank_version_t");
  argument_manager.template set_name<gec__host_event_list_output_t>("gec__host_event_list_output_t");
  argument_manager.template set_name<gec__host_number_of_events_t>("gec__host_number_of_events_t");
  argument_manager.template set_name<gec__host_number_of_selected_events_t>("gec__host_number_of_selected_events_t");
  argument_manager.template set_name<gec__dev_number_of_events_t>("gec__dev_number_of_events_t");
  argument_manager.template set_name<gec__dev_event_list_output_t>("gec__dev_event_list_output_t");
  argument_manager.template set_name<ut_banks__dev_raw_banks_t>("ut_banks__dev_raw_banks_t");
  argument_manager.template set_name<ut_banks__dev_raw_offsets_t>("ut_banks__dev_raw_offsets_t");
  argument_manager.template set_name<ut_banks__host_raw_bank_version_t>("ut_banks__host_raw_bank_version_t");
  argument_manager.template set_name<ut_calculate_number_of_hits__dev_ut_hit_sizes_t>(
    "ut_calculate_number_of_hits__dev_ut_hit_sizes_t");
  argument_manager.template set_name<prefix_sum_ut_hits__host_total_sum_holder_t>(
    "prefix_sum_ut_hits__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_hits__host_output_buffer_t>(
    "prefix_sum_ut_hits__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_hits__dev_output_buffer_t>(
    "prefix_sum_ut_hits__dev_output_buffer_t");
  argument_manager.template set_name<ut_pre_decode__dev_ut_pre_decoded_hits_t>(
    "ut_pre_decode__dev_ut_pre_decoded_hits_t");
  argument_manager.template set_name<ut_pre_decode__dev_ut_hit_count_t>("ut_pre_decode__dev_ut_hit_count_t");
  argument_manager.template set_name<ut_find_permutation__dev_ut_hit_permutations_t>(
    "ut_find_permutation__dev_ut_hit_permutations_t");
  argument_manager.template set_name<ut_decode_raw_banks_in_order__dev_ut_hits_t>(
    "ut_decode_raw_banks_in_order__dev_ut_hits_t");
  argument_manager.template set_name<scifi_banks__dev_raw_banks_t>("scifi_banks__dev_raw_banks_t");
  argument_manager.template set_name<scifi_banks__dev_raw_offsets_t>("scifi_banks__dev_raw_offsets_t");
  argument_manager.template set_name<scifi_banks__host_raw_bank_version_t>("scifi_banks__host_raw_bank_version_t");
  argument_manager.template set_name<scifi_calculate_cluster_count__dev_scifi_hit_count_t>(
    "scifi_calculate_cluster_count__dev_scifi_hit_count_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__host_total_sum_holder_t>(
    "prefix_sum_scifi_hits__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__host_output_buffer_t>(
    "prefix_sum_scifi_hits__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_scifi_hits__dev_output_buffer_t>(
    "prefix_sum_scifi_hits__dev_output_buffer_t");
  argument_manager.template set_name<scifi_pre_decode__dev_cluster_references_t>(
    "scifi_pre_decode__dev_cluster_references_t");
  argument_manager.template set_name<scifi_raw_bank_decoder__dev_scifi_hits_t>(
    "scifi_raw_bank_decoder__dev_scifi_hits_t");
  argument_manager.template set_name<muon_banks__dev_raw_banks_t>("muon_banks__dev_raw_banks_t");
  argument_manager.template set_name<muon_banks__dev_raw_offsets_t>("muon_banks__dev_raw_offsets_t");
  argument_manager.template set_name<muon_banks__host_raw_bank_version_t>("muon_banks__host_raw_bank_version_t");
  argument_manager.template set_name<muon_calculate_srq_size__dev_muon_raw_to_hits_t>(
    "muon_calculate_srq_size__dev_muon_raw_to_hits_t");
  argument_manager.template set_name<muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t>(
    "muon_calculate_srq_size__dev_storage_station_region_quarter_sizes_t");
  argument_manager.template set_name<muon_srq_prefix_sum__host_total_sum_holder_t>(
    "muon_srq_prefix_sum__host_total_sum_holder_t");
  argument_manager.template set_name<muon_srq_prefix_sum__host_output_buffer_t>(
    "muon_srq_prefix_sum__host_output_buffer_t");
  argument_manager.template set_name<muon_srq_prefix_sum__dev_output_buffer_t>(
    "muon_srq_prefix_sum__dev_output_buffer_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc__dev_storage_tile_id_t>(
    "muon_populate_tile_and_tdc__dev_storage_tile_id_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc__dev_storage_tdc_value_t>(
    "muon_populate_tile_and_tdc__dev_storage_tdc_value_t");
  argument_manager.template set_name<muon_populate_tile_and_tdc__dev_atomics_muon_t>(
    "muon_populate_tile_and_tdc__dev_atomics_muon_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps__dev_atomics_index_insert_t>(
    "muon_add_coords_crossing_maps__dev_atomics_index_insert_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps__dev_muon_compact_hit_t>(
    "muon_add_coords_crossing_maps__dev_muon_compact_hit_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps__dev_muon_tile_used_t>(
    "muon_add_coords_crossing_maps__dev_muon_tile_used_t");
  argument_manager.template set_name<muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t>(
    "muon_add_coords_crossing_maps__dev_station_ocurrences_sizes_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__host_total_sum_holder_t>(
    "muon_station_ocurrence_prefix_sum__host_total_sum_holder_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__host_output_buffer_t>(
    "muon_station_ocurrence_prefix_sum__host_output_buffer_t");
  argument_manager.template set_name<muon_station_ocurrence_prefix_sum__dev_output_buffer_t>(
    "muon_station_ocurrence_prefix_sum__dev_output_buffer_t");
  argument_manager.template set_name<muon_populate_hits__dev_permutation_station_t>(
    "muon_populate_hits__dev_permutation_station_t");
  argument_manager.template set_name<muon_populate_hits__dev_muon_hits_t>("muon_populate_hits__dev_muon_hits_t");
  argument_manager.template set_name<velo_banks__dev_raw_banks_t>("velo_banks__dev_raw_banks_t");
  argument_manager.template set_name<velo_banks__dev_raw_offsets_t>("velo_banks__dev_raw_offsets_t");
  argument_manager.template set_name<velo_banks__host_raw_bank_version_t>("velo_banks__host_raw_bank_version_t");
  argument_manager.template set_name<velo_calculate_number_of_candidates__dev_number_of_candidates_t>(
    "velo_calculate_number_of_candidates__dev_number_of_candidates_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_candidates__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__host_output_buffer_t>(
    "prefix_sum_offsets_velo_candidates__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_candidates__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_candidates__dev_output_buffer_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_estimated_input_size_t>(
    "velo_estimate_input_size__dev_estimated_input_size_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_module_candidate_num_t>(
    "velo_estimate_input_size__dev_module_candidate_num_t");
  argument_manager.template set_name<velo_estimate_input_size__dev_cluster_candidates_t>(
    "velo_estimate_input_size__dev_cluster_candidates_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t>(
    "prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__host_output_buffer_t>(
    "prefix_sum_offsets_estimated_input_size__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_estimated_input_size__dev_output_buffer_t>(
    "prefix_sum_offsets_estimated_input_size__dev_output_buffer_t");
  argument_manager.template set_name<velo_masked_clustering__dev_module_cluster_num_t>(
    "velo_masked_clustering__dev_module_cluster_num_t");
  argument_manager.template set_name<velo_masked_clustering__dev_velo_cluster_container_t>(
    "velo_masked_clustering__dev_velo_cluster_container_t");
  argument_manager.template set_name<velo_masked_clustering__dev_velo_clusters_t>(
    "velo_masked_clustering__dev_velo_clusters_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t>(
    "velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_hit_permutation_t>(
    "velo_calculate_phi_and_sort__dev_hit_permutation_t");
  argument_manager.template set_name<velo_calculate_phi_and_sort__dev_hit_phi_t>(
    "velo_calculate_phi_and_sort__dev_hit_phi_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracks_t>("velo_search_by_triplet__dev_tracks_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracklets_t>(
    "velo_search_by_triplet__dev_tracklets_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_tracks_to_follow_t>(
    "velo_search_by_triplet__dev_tracks_to_follow_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_three_hit_tracks_t>(
    "velo_search_by_triplet__dev_three_hit_tracks_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_hit_used_t>("velo_search_by_triplet__dev_hit_used_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_atomics_velo_t>(
    "velo_search_by_triplet__dev_atomics_velo_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_rel_indices_t>(
    "velo_search_by_triplet__dev_rel_indices_t");
  argument_manager.template set_name<velo_search_by_triplet__dev_number_of_velo_tracks_t>(
    "velo_search_by_triplet__dev_number_of_velo_tracks_t");
  argument_manager.template set_name<velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t>(
    "velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t");
  argument_manager.template set_name<velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>(
    "velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>(
    "prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__host_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_tracks__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_tracks__dev_output_buffer_t");
  argument_manager.template set_name<velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t>(
    "velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t");
  argument_manager.template set_name<velo_copy_track_hit_number__dev_velo_track_hit_number_t>(
    "velo_copy_track_hit_number__dev_velo_track_hit_number_t");
  argument_manager.template set_name<velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t>(
    "velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t>(
    "prefix_sum_offsets_velo_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<velo_consolidate_tracks__dev_accepted_velo_tracks_t>(
    "velo_consolidate_tracks__dev_accepted_velo_tracks_t");
  argument_manager.template set_name<velo_consolidate_tracks__dev_velo_track_hits_t>(
    "velo_consolidate_tracks__dev_velo_track_hits_t");
  argument_manager.template set_name<velo_kalman_filter__dev_velo_kalman_beamline_states_t>(
    "velo_kalman_filter__dev_velo_kalman_beamline_states_t");
  argument_manager.template set_name<velo_kalman_filter__dev_velo_kalman_endvelo_states_t>(
    "velo_kalman_filter__dev_velo_kalman_endvelo_states_t");
  argument_manager.template set_name<velo_kalman_filter__dev_velo_lmsfit_beamline_states_t>(
    "velo_kalman_filter__dev_velo_lmsfit_beamline_states_t");
  argument_manager.template set_name<ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t>(
    "ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t");
  argument_manager.template set_name<ut_select_velo_tracks__dev_ut_selected_velo_tracks_t>(
    "ut_select_velo_tracks__dev_ut_selected_velo_tracks_t");
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtracks_t>(
    "pv_beamline_extrapolate__dev_pvtracks_t");
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtrack_z_t>(
    "pv_beamline_extrapolate__dev_pvtrack_z_t");
  argument_manager.template set_name<pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t>(
    "pv_beamline_extrapolate__dev_pvtrack_unsorted_z_t");
  argument_manager.template set_name<pv_beamline_histo__dev_zhisto_t>("pv_beamline_histo__dev_zhisto_t");
  argument_manager.template set_name<ut_search_windows__dev_ut_windows_layers_t>(
    "ut_search_windows__dev_ut_windows_layers_t");
  argument_manager
    .template set_name<ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t>(
      "ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t");
  argument_manager.template set_name<ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t>(
    "ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t");
  argument_manager.template set_name<compass_ut__dev_ut_tracks_t>("compass_ut__dev_ut_tracks_t");
  argument_manager.template set_name<compass_ut__dev_atomics_ut_t>("compass_ut__dev_atomics_ut_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__host_total_sum_holder_t>(
    "prefix_sum_ut_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__host_output_buffer_t>(
    "prefix_sum_ut_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_tracks__dev_output_buffer_t>(
    "prefix_sum_ut_tracks__dev_output_buffer_t");
  argument_manager.template set_name<ut_copy_track_hit_number__dev_ut_track_hit_number_t>(
    "ut_copy_track_hit_number__dev_ut_track_hit_number_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_ut_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__host_output_buffer_t>(
    "prefix_sum_ut_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_ut_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_ut_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_track_hits_t>(
    "ut_consolidate_tracks__dev_ut_track_hits_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_qop_t>("ut_consolidate_tracks__dev_ut_qop_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_x_t>("ut_consolidate_tracks__dev_ut_x_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_tx_t>("ut_consolidate_tracks__dev_ut_tx_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_z_t>("ut_consolidate_tracks__dev_ut_z_t");
  argument_manager.template set_name<ut_consolidate_tracks__dev_ut_track_velo_indices_t>(
    "ut_consolidate_tracks__dev_ut_track_velo_indices_t");
  argument_manager.template set_name<lf_search_initial_windows__dev_scifi_lf_initial_windows_t>(
    "lf_search_initial_windows__dev_scifi_lf_initial_windows_t");
  argument_manager.template set_name<lf_search_initial_windows__dev_ut_states_t>(
    "lf_search_initial_windows__dev_ut_states_t");
  argument_manager.template set_name<lf_search_initial_windows__dev_scifi_lf_process_track_t>(
    "lf_search_initial_windows__dev_scifi_lf_process_track_t");
  argument_manager.template set_name<pv_beamline_peak__dev_zpeaks_t>("pv_beamline_peak__dev_zpeaks_t");
  argument_manager.template set_name<pv_beamline_peak__dev_number_of_zpeaks_t>(
    "pv_beamline_peak__dev_number_of_zpeaks_t");
  argument_manager.template set_name<pv_beamline_calculate_denom__dev_pvtracks_denom_t>(
    "pv_beamline_calculate_denom__dev_pvtracks_denom_t");
  argument_manager.template set_name<pv_beamline_multi_fitter__dev_multi_fit_vertices_t>(
    "pv_beamline_multi_fitter__dev_multi_fit_vertices_t");
  argument_manager.template set_name<pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t>(
    "pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t");
  argument_manager.template set_name<pv_beamline_cleanup__dev_multi_final_vertices_t>(
    "pv_beamline_cleanup__dev_multi_final_vertices_t");
  argument_manager.template set_name<pv_beamline_cleanup__dev_number_of_multi_final_vertices_t>(
    "pv_beamline_cleanup__dev_number_of_multi_final_vertices_t");
  argument_manager.template set_name<velo_pv_ip__dev_velo_pv_ip_t>("velo_pv_ip__dev_velo_pv_ip_t");
  argument_manager.template set_name<lf_triplet_seeding__dev_scifi_lf_found_triplets_t>(
    "lf_triplet_seeding__dev_scifi_lf_found_triplets_t");
  argument_manager.template set_name<lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t>(
    "lf_triplet_seeding__dev_scifi_lf_number_of_found_triplets_t");
  argument_manager.template set_name<lf_create_tracks__dev_scifi_lf_tracks_t>(
    "lf_create_tracks__dev_scifi_lf_tracks_t");
  argument_manager.template set_name<lf_create_tracks__dev_scifi_lf_atomics_t>(
    "lf_create_tracks__dev_scifi_lf_atomics_t");
  argument_manager.template set_name<lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t>(
    "lf_create_tracks__dev_scifi_lf_total_number_of_found_triplets_t");
  argument_manager.template set_name<lf_create_tracks__dev_scifi_lf_parametrization_t>(
    "lf_create_tracks__dev_scifi_lf_parametrization_t");
  argument_manager.template set_name<lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t>(
    "lf_quality_filter_length__dev_scifi_lf_length_filtered_tracks_t");
  argument_manager.template set_name<lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t>(
    "lf_quality_filter_length__dev_scifi_lf_length_filtered_atomics_t");
  argument_manager.template set_name<lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t>(
    "lf_quality_filter_length__dev_scifi_lf_parametrization_length_filter_t");
  argument_manager.template set_name<lf_quality_filter__dev_lf_quality_of_tracks_t>(
    "lf_quality_filter__dev_lf_quality_of_tracks_t");
  argument_manager.template set_name<lf_quality_filter__dev_atomics_scifi_t>("lf_quality_filter__dev_atomics_scifi_t");
  argument_manager.template set_name<lf_quality_filter__dev_scifi_tracks_t>("lf_quality_filter__dev_scifi_tracks_t");
  argument_manager.template set_name<lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t>(
    "lf_quality_filter__dev_scifi_lf_y_parametrization_length_filter_t");
  argument_manager.template set_name<lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t>(
    "lf_quality_filter__dev_scifi_lf_parametrization_consolidate_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__host_total_sum_holder_t>(
    "prefix_sum_forward_tracks__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__host_output_buffer_t>(
    "prefix_sum_forward_tracks__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_forward_tracks__dev_output_buffer_t>(
    "prefix_sum_forward_tracks__dev_output_buffer_t");
  argument_manager.template set_name<scifi_copy_track_hit_number__dev_scifi_track_hit_number_t>(
    "scifi_copy_track_hit_number__dev_scifi_track_hit_number_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__host_total_sum_holder_t>(
    "prefix_sum_scifi_track_hit_number__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__host_output_buffer_t>(
    "prefix_sum_scifi_track_hit_number__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_scifi_track_hit_number__dev_output_buffer_t>(
    "prefix_sum_scifi_track_hit_number__dev_output_buffer_t");
  argument_manager.template set_name<scifi_consolidate_tracks__dev_scifi_track_hits_t>(
    "scifi_consolidate_tracks__dev_scifi_track_hits_t");
  argument_manager.template set_name<scifi_consolidate_tracks__dev_scifi_qop_t>(
    "scifi_consolidate_tracks__dev_scifi_qop_t");
  argument_manager.template set_name<scifi_consolidate_tracks__dev_scifi_states_t>(
    "scifi_consolidate_tracks__dev_scifi_states_t");
  argument_manager.template set_name<scifi_consolidate_tracks__dev_scifi_track_ut_indices_t>(
    "scifi_consolidate_tracks__dev_scifi_track_ut_indices_t");
  argument_manager.template set_name<is_muon__dev_muon_track_occupancies_t>("is_muon__dev_muon_track_occupancies_t");
  argument_manager.template set_name<is_muon__dev_is_muon_t>("is_muon__dev_is_muon_t");
  argument_manager.template set_name<kalman_velo_only__dev_kf_tracks_t>("kalman_velo_only__dev_kf_tracks_t");
  argument_manager.template set_name<kalman_velo_only__dev_kalman_pv_ipchi2_t>(
    "kalman_velo_only__dev_kalman_pv_ipchi2_t");
  argument_manager.template set_name<filter_tracks__dev_sv_atomics_t>("filter_tracks__dev_sv_atomics_t");
  argument_manager.template set_name<filter_tracks__dev_svs_trk1_idx_t>("filter_tracks__dev_svs_trk1_idx_t");
  argument_manager.template set_name<filter_tracks__dev_svs_trk2_idx_t>("filter_tracks__dev_svs_trk2_idx_t");
  argument_manager.template set_name<prefix_sum_secondary_vertices__host_total_sum_holder_t>(
    "prefix_sum_secondary_vertices__host_total_sum_holder_t");
  argument_manager.template set_name<prefix_sum_secondary_vertices__host_output_buffer_t>(
    "prefix_sum_secondary_vertices__host_output_buffer_t");
  argument_manager.template set_name<prefix_sum_secondary_vertices__dev_output_buffer_t>(
    "prefix_sum_secondary_vertices__dev_output_buffer_t");
  argument_manager.template set_name<fit_secondary_vertices__dev_consolidated_svs_t>(
    "fit_secondary_vertices__dev_consolidated_svs_t");
  argument_manager.template set_name<two_track_preprocess__dev_two_track_preprocess_output_t>(
    "two_track_preprocess__dev_two_track_preprocess_output_t");
  argument_manager.template set_name<two_track_evaluator__dev_two_track_catboost_evaluation_t>(
    "two_track_evaluator__dev_two_track_catboost_evaluation_t");
  argument_manager.template set_name<populate_odin_banks__dev_raw_banks_t>("populate_odin_banks__dev_raw_banks_t");
  argument_manager.template set_name<populate_odin_banks__dev_raw_offsets_t>("populate_odin_banks__dev_raw_offsets_t");
  argument_manager.template set_name<populate_odin_banks__host_raw_bank_version_t>(
    "populate_odin_banks__host_raw_bank_version_t");
  argument_manager.template set_name<Hlt1TrackMVA__dev_decisions_t>("Hlt1TrackMVA__dev_decisions_t");
  argument_manager.template set_name<Hlt1TrackMVA__dev_decisions_offsets_t>("Hlt1TrackMVA__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1TrackMVA__host_post_scaler_t>("Hlt1TrackMVA__host_post_scaler_t");
  argument_manager.template set_name<Hlt1TrackMVA__host_post_scaler_hash_t>("Hlt1TrackMVA__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1TwoTrackMVA__dev_decisions_t>("Hlt1TwoTrackMVA__dev_decisions_t");
  argument_manager.template set_name<Hlt1TwoTrackMVA__dev_decisions_offsets_t>(
    "Hlt1TwoTrackMVA__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1TwoTrackMVA__host_post_scaler_t>("Hlt1TwoTrackMVA__host_post_scaler_t");
  argument_manager.template set_name<Hlt1TwoTrackMVA__host_post_scaler_hash_t>(
    "Hlt1TwoTrackMVA__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1TwoTrackCatBoost__dev_decisions_t>("Hlt1TwoTrackCatBoost__dev_decisions_t");
  argument_manager.template set_name<Hlt1TwoTrackCatBoost__dev_decisions_offsets_t>(
    "Hlt1TwoTrackCatBoost__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1TwoTrackCatBoost__host_post_scaler_t>(
    "Hlt1TwoTrackCatBoost__host_post_scaler_t");
  argument_manager.template set_name<Hlt1TwoTrackCatBoost__host_post_scaler_hash_t>(
    "Hlt1TwoTrackCatBoost__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1SingleHighPtMuon__dev_decisions_t>("Hlt1SingleHighPtMuon__dev_decisions_t");
  argument_manager.template set_name<Hlt1SingleHighPtMuon__dev_decisions_offsets_t>(
    "Hlt1SingleHighPtMuon__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1SingleHighPtMuon__host_post_scaler_t>(
    "Hlt1SingleHighPtMuon__host_post_scaler_t");
  argument_manager.template set_name<Hlt1SingleHighPtMuon__host_post_scaler_hash_t>(
    "Hlt1SingleHighPtMuon__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1LowPtMuon__dev_decisions_t>("Hlt1LowPtMuon__dev_decisions_t");
  argument_manager.template set_name<Hlt1LowPtMuon__dev_decisions_offsets_t>("Hlt1LowPtMuon__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1LowPtMuon__host_post_scaler_t>("Hlt1LowPtMuon__host_post_scaler_t");
  argument_manager.template set_name<Hlt1LowPtMuon__host_post_scaler_hash_t>("Hlt1LowPtMuon__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1D2KK__dev_decisions_t>("Hlt1D2KK__dev_decisions_t");
  argument_manager.template set_name<Hlt1D2KK__dev_decisions_offsets_t>("Hlt1D2KK__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1D2KK__host_post_scaler_t>("Hlt1D2KK__host_post_scaler_t");
  argument_manager.template set_name<Hlt1D2KK__host_post_scaler_hash_t>("Hlt1D2KK__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1D2KPi__dev_decisions_t>("Hlt1D2KPi__dev_decisions_t");
  argument_manager.template set_name<Hlt1D2KPi__dev_decisions_offsets_t>("Hlt1D2KPi__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1D2KPi__host_post_scaler_t>("Hlt1D2KPi__host_post_scaler_t");
  argument_manager.template set_name<Hlt1D2KPi__host_post_scaler_hash_t>("Hlt1D2KPi__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1D2PiPi__dev_decisions_t>("Hlt1D2PiPi__dev_decisions_t");
  argument_manager.template set_name<Hlt1D2PiPi__dev_decisions_offsets_t>("Hlt1D2PiPi__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1D2PiPi__host_post_scaler_t>("Hlt1D2PiPi__host_post_scaler_t");
  argument_manager.template set_name<Hlt1D2PiPi__host_post_scaler_hash_t>("Hlt1D2PiPi__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1DiMuonHighMass__dev_decisions_t>("Hlt1DiMuonHighMass__dev_decisions_t");
  argument_manager.template set_name<Hlt1DiMuonHighMass__dev_decisions_offsets_t>(
    "Hlt1DiMuonHighMass__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1DiMuonHighMass__host_post_scaler_t>("Hlt1DiMuonHighMass__host_post_scaler_t");
  argument_manager.template set_name<Hlt1DiMuonHighMass__host_post_scaler_hash_t>(
    "Hlt1DiMuonHighMass__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1DiMuonLowMass__dev_decisions_t>("Hlt1DiMuonLowMass__dev_decisions_t");
  argument_manager.template set_name<Hlt1DiMuonLowMass__dev_decisions_offsets_t>(
    "Hlt1DiMuonLowMass__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1DiMuonLowMass__host_post_scaler_t>("Hlt1DiMuonLowMass__host_post_scaler_t");
  argument_manager.template set_name<Hlt1DiMuonLowMass__host_post_scaler_hash_t>(
    "Hlt1DiMuonLowMass__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1DiMuonSoft__dev_decisions_t>("Hlt1DiMuonSoft__dev_decisions_t");
  argument_manager.template set_name<Hlt1DiMuonSoft__dev_decisions_offsets_t>(
    "Hlt1DiMuonSoft__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1DiMuonSoft__host_post_scaler_t>("Hlt1DiMuonSoft__host_post_scaler_t");
  argument_manager.template set_name<Hlt1DiMuonSoft__host_post_scaler_hash_t>(
    "Hlt1DiMuonSoft__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1LowPtDiMuon__dev_decisions_t>("Hlt1LowPtDiMuon__dev_decisions_t");
  argument_manager.template set_name<Hlt1LowPtDiMuon__dev_decisions_offsets_t>(
    "Hlt1LowPtDiMuon__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1LowPtDiMuon__host_post_scaler_t>("Hlt1LowPtDiMuon__host_post_scaler_t");
  argument_manager.template set_name<Hlt1LowPtDiMuon__host_post_scaler_hash_t>(
    "Hlt1LowPtDiMuon__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1TrackMuonMVA__dev_decisions_t>("Hlt1TrackMuonMVA__dev_decisions_t");
  argument_manager.template set_name<Hlt1TrackMuonMVA__dev_decisions_offsets_t>(
    "Hlt1TrackMuonMVA__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1TrackMuonMVA__host_post_scaler_t>("Hlt1TrackMuonMVA__host_post_scaler_t");
  argument_manager.template set_name<Hlt1TrackMuonMVA__host_post_scaler_hash_t>(
    "Hlt1TrackMuonMVA__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1GECPassthrough__dev_decisions_t>("Hlt1GECPassthrough__dev_decisions_t");
  argument_manager.template set_name<Hlt1GECPassthrough__dev_decisions_offsets_t>(
    "Hlt1GECPassthrough__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1GECPassthrough__host_post_scaler_t>("Hlt1GECPassthrough__host_post_scaler_t");
  argument_manager.template set_name<Hlt1GECPassthrough__host_post_scaler_hash_t>(
    "Hlt1GECPassthrough__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1NoBeam__dev_decisions_t>("Hlt1NoBeam__dev_decisions_t");
  argument_manager.template set_name<Hlt1NoBeam__dev_decisions_offsets_t>("Hlt1NoBeam__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1NoBeam__host_post_scaler_t>("Hlt1NoBeam__host_post_scaler_t");
  argument_manager.template set_name<Hlt1NoBeam__host_post_scaler_hash_t>("Hlt1NoBeam__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1BeamOne__dev_decisions_t>("Hlt1BeamOne__dev_decisions_t");
  argument_manager.template set_name<Hlt1BeamOne__dev_decisions_offsets_t>("Hlt1BeamOne__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1BeamOne__host_post_scaler_t>("Hlt1BeamOne__host_post_scaler_t");
  argument_manager.template set_name<Hlt1BeamOne__host_post_scaler_hash_t>("Hlt1BeamOne__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1BeamTwo__dev_decisions_t>("Hlt1BeamTwo__dev_decisions_t");
  argument_manager.template set_name<Hlt1BeamTwo__dev_decisions_offsets_t>("Hlt1BeamTwo__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1BeamTwo__host_post_scaler_t>("Hlt1BeamTwo__host_post_scaler_t");
  argument_manager.template set_name<Hlt1BeamTwo__host_post_scaler_hash_t>("Hlt1BeamTwo__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1BothBeams__dev_decisions_t>("Hlt1BothBeams__dev_decisions_t");
  argument_manager.template set_name<Hlt1BothBeams__dev_decisions_offsets_t>("Hlt1BothBeams__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1BothBeams__host_post_scaler_t>("Hlt1BothBeams__host_post_scaler_t");
  argument_manager.template set_name<Hlt1BothBeams__host_post_scaler_hash_t>("Hlt1BothBeams__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1VeloMicroBias__dev_decisions_t>("Hlt1VeloMicroBias__dev_decisions_t");
  argument_manager.template set_name<Hlt1VeloMicroBias__dev_decisions_offsets_t>(
    "Hlt1VeloMicroBias__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1VeloMicroBias__host_post_scaler_t>("Hlt1VeloMicroBias__host_post_scaler_t");
  argument_manager.template set_name<Hlt1VeloMicroBias__host_post_scaler_hash_t>(
    "Hlt1VeloMicroBias__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1ODINLumi__dev_decisions_t>("Hlt1ODINLumi__dev_decisions_t");
  argument_manager.template set_name<Hlt1ODINLumi__dev_decisions_offsets_t>("Hlt1ODINLumi__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1ODINLumi__host_post_scaler_t>("Hlt1ODINLumi__host_post_scaler_t");
  argument_manager.template set_name<Hlt1ODINLumi__host_post_scaler_hash_t>("Hlt1ODINLumi__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1ODINNoBias__dev_decisions_t>("Hlt1ODINNoBias__dev_decisions_t");
  argument_manager.template set_name<Hlt1ODINNoBias__dev_decisions_offsets_t>(
    "Hlt1ODINNoBias__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1ODINNoBias__host_post_scaler_t>("Hlt1ODINNoBias__host_post_scaler_t");
  argument_manager.template set_name<Hlt1ODINNoBias__host_post_scaler_hash_t>(
    "Hlt1ODINNoBias__host_post_scaler_hash_t");
  argument_manager.template set_name<Hlt1Passthrough__dev_decisions_t>("Hlt1Passthrough__dev_decisions_t");
  argument_manager.template set_name<Hlt1Passthrough__dev_decisions_offsets_t>(
    "Hlt1Passthrough__dev_decisions_offsets_t");
  argument_manager.template set_name<Hlt1Passthrough__host_post_scaler_t>("Hlt1Passthrough__host_post_scaler_t");
  argument_manager.template set_name<Hlt1Passthrough__host_post_scaler_hash_t>(
    "Hlt1Passthrough__host_post_scaler_hash_t");
  argument_manager.template set_name<gather_selections__host_selections_lines_offsets_t>(
    "gather_selections__host_selections_lines_offsets_t");
  argument_manager.template set_name<gather_selections__host_selections_offsets_t>(
    "gather_selections__host_selections_offsets_t");
  argument_manager.template set_name<gather_selections__host_number_of_active_lines_t>(
    "gather_selections__host_number_of_active_lines_t");
  argument_manager.template set_name<gather_selections__host_names_of_active_lines_t>(
    "gather_selections__host_names_of_active_lines_t");
  argument_manager.template set_name<gather_selections__dev_selections_t>("gather_selections__dev_selections_t");
  argument_manager.template set_name<gather_selections__dev_selections_offsets_t>(
    "gather_selections__dev_selections_offsets_t");
  argument_manager.template set_name<gather_selections__dev_number_of_active_lines_t>(
    "gather_selections__dev_number_of_active_lines_t");
  argument_manager.template set_name<gather_selections__host_post_scale_factors_t>(
    "gather_selections__host_post_scale_factors_t");
  argument_manager.template set_name<gather_selections__host_post_scale_hashes_t>(
    "gather_selections__host_post_scale_hashes_t");
  argument_manager.template set_name<gather_selections__dev_post_scale_factors_t>(
    "gather_selections__dev_post_scale_factors_t");
  argument_manager.template set_name<gather_selections__dev_post_scale_hashes_t>(
    "gather_selections__dev_post_scale_hashes_t");
  argument_manager.template set_name<dec_reporter__dev_dec_reports_t>("dec_reporter__dev_dec_reports_t");
}
