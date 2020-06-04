/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include "ConfiguredInputAggregates.h"
#include "../../stream/gear/include/ArgumentManager.cuh"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/global_event_cut/include/HostGlobalEventCut.h"
#include "../../host/init_event_list/include/HostInitEventList.h"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/mask_clustering/include/EstimateInputSize.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/mask_clustering/include/MaskedVeloClustering.cuh"
#include "../../device/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"
#include "../../device/velo/search_by_triplet/include/SearchByTriplet.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"
#include "../../device/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_histo.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_peak.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"
#include "../../device/PV/beamlinePV/include/pv_beamline_cleanup.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/UTDecoding/include/UTPreDecode.cuh"
#include "../../device/UT/UTDecoding/include/UTFindPermutation.cuh"
#include "../../device/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"
#include "../../device/UT/compassUT/include/UTSelectVeloTracks.cuh"
#include "../../device/UT/compassUT/include/SearchWindows.cuh"
#include "../../device/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"
#include "../../device/UT/compassUT/include/CompassUT.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/consolidate/include/UTCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/UT/consolidate/include/ConsolidateUT.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/SciFi/preprocessing/include/SciFiCalculateClusterCountV4.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/preprocessing/include/SciFiPreDecodeV4.cuh"
#include "../../device/SciFi/preprocessing/include/SciFiRawBankDecoderV4.cuh"
#include "../../device/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"
#include "../../device/SciFi/looking_forward/include/LFTripletSeeding.cuh"
#include "../../device/SciFi/looking_forward/include/LFCreateTracks.cuh"
#include "../../device/SciFi/looking_forward/include/LFQualityFilterLength.cuh"
#include "../../device/SciFi/looking_forward/include/LFQualityFilter.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/SciFi/consolidate/include/ConsolidateSciFi.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/muon/decoding/include/MuonCalculateSRQSize.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/muon/decoding/include/MuonPopulateTileAndTDC.cuh"
#include "../../device/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/muon/decoding/include/MuonPopulateHits.cuh"
#include "../../device/muon/is_muon/include/IsMuon.cuh"
#include "../../device/associate/include/VeloPVIP.cuh"
#include "../../device/kalman/ParKalman/include/ParKalmanVeloOnly.cuh"
#include "../../device/vertex_fit/vertex_fitter/include/FilterTracks.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/vertex_fit/vertex_fitter/include/VertexFitter.cuh"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/selections/lines/include/TrackMVALine.cuh"
#include "../../device/selections/lines/include/TwoTrackMVALine.cuh"
#include "../../device/selections/lines/include/BeamCrossingLine.cuh"
#include "../../device/selections/lines/include/BeamCrossingLine.cuh"
#include "../../device/selections/lines/include/BeamCrossingLine.cuh"
#include "../../device/selections/Hlt1/include/GatherSelections.cuh"

struct host_ut_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                         host_global_event_cut::Parameters::host_ut_raw_banks_t,
                                         host_init_event_list::Parameters::host_ut_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "host_ut_banks__host_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct host_ut_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                           host_global_event_cut::Parameters::host_ut_raw_offsets_t,
                                           host_init_event_list::Parameters::host_ut_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "host_ut_banks__host_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct host_scifi_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t,
                                            host_global_event_cut::Parameters::host_scifi_raw_banks_t,
                                            host_init_event_list::Parameters::host_scifi_raw_banks_t {
  using type = host_data_provider::Parameters::host_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "host_scifi_banks__host_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct host_scifi_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t,
                                              host_global_event_cut::Parameters::host_scifi_raw_offsets_t,
                                              host_init_event_list::Parameters::host_scifi_raw_offsets_t {
  using type = host_data_provider::Parameters::host_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "host_scifi_banks__host_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct initialize_lists__host_event_list_t : host_global_event_cut::Parameters::host_event_list_t {
  using type = host_global_event_cut::Parameters::host_event_list_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "initialize_lists__host_event_list_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct initialize_lists__host_number_of_events_t
  : host_global_event_cut::Parameters::host_number_of_events_t,
    velo_calculate_number_of_candidates::Parameters::host_number_of_events_t,
    velo_estimate_input_size::Parameters::host_number_of_events_t,
    velo_masked_clustering::Parameters::host_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::host_number_of_events_t,
    velo_search_by_triplet::Parameters::host_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::host_number_of_events_t,
    velo_copy_track_hit_number::Parameters::host_number_of_events_t,
    velo_consolidate_tracks::Parameters::host_number_of_events_t,
    velo_kalman_filter::Parameters::host_number_of_events_t,
    pv_beamline_extrapolate::Parameters::host_number_of_events_t,
    pv_beamline_histo::Parameters::host_number_of_events_t,
    pv_beamline_peak::Parameters::host_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_events_t,
    pv_beamline_cleanup::Parameters::host_number_of_events_t,
    ut_calculate_number_of_hits::Parameters::host_number_of_events_t,
    ut_pre_decode::Parameters::host_number_of_events_t,
    ut_find_permutation::Parameters::host_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::host_number_of_events_t,
    ut_select_velo_tracks::Parameters::host_number_of_events_t,
    ut_search_windows::Parameters::host_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_events_t,
    compass_ut::Parameters::host_number_of_events_t,
    ut_copy_track_hit_number::Parameters::host_number_of_events_t,
    ut_consolidate_tracks::Parameters::host_number_of_events_t,
    scifi_calculate_cluster_count_v4::Parameters::host_number_of_events_t,
    scifi_pre_decode_v4::Parameters::host_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::host_number_of_events_t,
    lf_search_initial_windows::Parameters::host_number_of_events_t,
    lf_triplet_seeding::Parameters::host_number_of_events_t,
    lf_create_tracks::Parameters::host_number_of_events_t,
    lf_quality_filter_length::Parameters::host_number_of_events_t,
    lf_quality_filter::Parameters::host_number_of_events_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_events_t,
    scifi_consolidate_tracks::Parameters::host_number_of_events_t,
    muon_calculate_srq_size::Parameters::host_number_of_events_t,
    muon_populate_tile_and_tdc::Parameters::host_number_of_events_t,
    muon_add_coords_crossing_maps::Parameters::host_number_of_events_t,
    muon_populate_hits::Parameters::host_number_of_events_t,
    is_muon::Parameters::host_number_of_events_t,
    velo_pv_ip::Parameters::host_number_of_events_t,
    kalman_velo_only::Parameters::host_number_of_events_t,
    FilterTracks::Parameters::host_number_of_events_t,
    VertexFit::Parameters::host_number_of_events_t,
    track_mva_line::Parameters::host_number_of_events_t,
    two_track_mva_line::Parameters::host_number_of_events_t,
    beam_crossing_line::Parameters::host_number_of_events_t,
    gather_selections::Parameters::host_number_of_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_events_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "initialize_lists__host_number_of_events_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct initialize_lists__host_number_of_selected_events_t
  : host_global_event_cut::Parameters::host_number_of_selected_events_t {
  using type = host_global_event_cut::Parameters::host_number_of_selected_events_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "initialize_lists__host_number_of_selected_events_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct initialize_lists__dev_number_of_events_t
  : host_global_event_cut::Parameters::dev_number_of_events_t,
    velo_masked_clustering::Parameters::dev_number_of_events_t,
    velo_calculate_phi_and_sort::Parameters::dev_number_of_events_t,
    velo_search_by_triplet::Parameters::dev_number_of_events_t,
    velo_three_hit_tracks_filter::Parameters::dev_number_of_events_t,
    velo_consolidate_tracks::Parameters::dev_number_of_events_t,
    velo_kalman_filter::Parameters::dev_number_of_events_t,
    pv_beamline_extrapolate::Parameters::dev_number_of_events_t,
    pv_beamline_histo::Parameters::dev_number_of_events_t,
    pv_beamline_peak::Parameters::dev_number_of_events_t,
    pv_beamline_calculate_denom::Parameters::dev_number_of_events_t,
    pv_beamline_multi_fitter::Parameters::dev_number_of_events_t,
    ut_pre_decode::Parameters::dev_number_of_events_t,
    ut_find_permutation::Parameters::dev_number_of_events_t,
    ut_decode_raw_banks_in_order::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks::Parameters::dev_number_of_events_t,
    ut_search_windows::Parameters::dev_number_of_events_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_number_of_events_t,
    compass_ut::Parameters::dev_number_of_events_t,
    ut_consolidate_tracks::Parameters::dev_number_of_events_t,
    scifi_raw_bank_decoder_v4::Parameters::dev_number_of_events_t,
    lf_search_initial_windows::Parameters::dev_number_of_events_t,
    lf_triplet_seeding::Parameters::dev_number_of_events_t,
    lf_create_tracks::Parameters::dev_number_of_events_t,
    lf_quality_filter_length::Parameters::dev_number_of_events_t,
    lf_quality_filter::Parameters::dev_number_of_events_t,
    scifi_consolidate_tracks::Parameters::dev_number_of_events_t,
    muon_populate_hits::Parameters::dev_number_of_events_t,
    is_muon::Parameters::dev_number_of_events_t,
    velo_pv_ip::Parameters::dev_number_of_events_t,
    kalman_velo_only::Parameters::dev_number_of_events_t,
    FilterTracks::Parameters::dev_number_of_events_t,
    VertexFit::Parameters::dev_number_of_events_t {
  using type = host_global_event_cut::Parameters::dev_number_of_events_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "initialize_lists__dev_number_of_events_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct initialize_lists__dev_event_list_t : host_global_event_cut::Parameters::dev_event_list_t,
                                            velo_calculate_number_of_candidates::Parameters::dev_event_list_t,
                                            velo_estimate_input_size::Parameters::dev_event_list_t,
                                            velo_masked_clustering::Parameters::dev_event_list_t,
                                            velo_calculate_phi_and_sort::Parameters::dev_event_list_t,
                                            velo_search_by_triplet::Parameters::dev_event_list_t,
                                            velo_three_hit_tracks_filter::Parameters::dev_event_list_t,
                                            velo_consolidate_tracks::Parameters::dev_event_list_t,
                                            velo_kalman_filter::Parameters::dev_event_list_t,
                                            pv_beamline_extrapolate::Parameters::dev_event_list_t,
                                            pv_beamline_histo::Parameters::dev_event_list_t,
                                            pv_beamline_peak::Parameters::dev_event_list_t,
                                            pv_beamline_calculate_denom::Parameters::dev_event_list_t,
                                            pv_beamline_multi_fitter::Parameters::dev_event_list_t,
                                            pv_beamline_cleanup::Parameters::dev_event_list_t,
                                            ut_calculate_number_of_hits::Parameters::dev_event_list_t,
                                            ut_pre_decode::Parameters::dev_event_list_t,
                                            ut_find_permutation::Parameters::dev_event_list_t,
                                            ut_decode_raw_banks_in_order::Parameters::dev_event_list_t,
                                            ut_select_velo_tracks::Parameters::dev_event_list_t,
                                            ut_search_windows::Parameters::dev_event_list_t,
                                            ut_select_velo_tracks_with_windows::Parameters::dev_event_list_t,
                                            compass_ut::Parameters::dev_event_list_t,
                                            ut_consolidate_tracks::Parameters::dev_event_list_t,
                                            scifi_calculate_cluster_count_v4::Parameters::dev_event_list_t,
                                            scifi_pre_decode_v4::Parameters::dev_event_list_t,
                                            scifi_raw_bank_decoder_v4::Parameters::dev_event_list_t,
                                            lf_search_initial_windows::Parameters::dev_event_list_t,
                                            lf_triplet_seeding::Parameters::dev_event_list_t,
                                            lf_create_tracks::Parameters::dev_event_list_t,
                                            lf_quality_filter_length::Parameters::dev_event_list_t,
                                            lf_quality_filter::Parameters::dev_event_list_t,
                                            scifi_consolidate_tracks::Parameters::dev_event_list_t,
                                            muon_calculate_srq_size::Parameters::dev_event_list_t,
                                            muon_populate_tile_and_tdc::Parameters::dev_event_list_t,
                                            muon_add_coords_crossing_maps::Parameters::dev_event_list_t,
                                            muon_populate_hits::Parameters::dev_event_list_t,
                                            is_muon::Parameters::dev_event_list_t,
                                            velo_pv_ip::Parameters::dev_event_list_t,
                                            kalman_velo_only::Parameters::dev_event_list_t,
                                            FilterTracks::Parameters::dev_event_list_t,
                                            VertexFit::Parameters::dev_event_list_t,
                                            track_mva_line::Parameters::dev_event_list_t,
                                            two_track_mva_line::Parameters::dev_event_list_t {
  using type = host_global_event_cut::Parameters::dev_event_list_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "initialize_lists__dev_event_list_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct full_event_list__host_number_of_events_t : host_init_event_list::Parameters::host_number_of_events_t {
  using type = host_init_event_list::Parameters::host_number_of_events_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "full_event_list__host_number_of_events_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct full_event_list__host_event_list_t : host_init_event_list::Parameters::host_event_list_t {
  using type = host_init_event_list::Parameters::host_event_list_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "full_event_list__host_event_list_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct full_event_list__dev_number_of_events_t : host_init_event_list::Parameters::dev_number_of_events_t {
  using type = host_init_event_list::Parameters::dev_number_of_events_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "full_event_list__dev_number_of_events_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct full_event_list__dev_event_list_t : host_init_event_list::Parameters::dev_event_list_t,
                                           beam_crossing_line::Parameters::dev_event_list_t {
  using type = host_init_event_list::Parameters::dev_event_list_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "full_event_list__dev_event_list_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_t,
                                     velo_estimate_input_size::Parameters::dev_velo_raw_input_t,
                                     velo_masked_clustering::Parameters::dev_velo_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_banks__dev_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       velo_calculate_number_of_candidates::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_estimate_input_size::Parameters::dev_velo_raw_input_offsets_t,
                                       velo_masked_clustering::Parameters::dev_velo_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_banks__dev_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_calculate_number_of_candidates__dev_number_of_candidates_t
  : velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_calculate_number_of_candidates::Parameters::dev_number_of_candidates_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_calculate_number_of_candidates__dev_number_of_candidates_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_candidates__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_estimate_input_size::Parameters::host_number_of_cluster_candidates_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_candidates__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_candidates__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_estimate_input_size::Parameters::dev_candidates_offsets_t,
    velo_masked_clustering::Parameters::dev_candidates_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_candidates__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_estimate_input_size__dev_estimated_input_size_t
  : velo_estimate_input_size::Parameters::dev_estimated_input_size_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_estimate_input_size::Parameters::dev_estimated_input_size_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_estimate_input_size__dev_estimated_input_size_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_estimate_input_size__dev_module_candidate_num_t
  : velo_estimate_input_size::Parameters::dev_module_candidate_num_t,
    velo_masked_clustering::Parameters::dev_module_candidate_num_t {
  using type = velo_estimate_input_size::Parameters::dev_module_candidate_num_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_estimate_input_size__dev_module_candidate_num_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_estimate_input_size__dev_cluster_candidates_t
  : velo_estimate_input_size::Parameters::dev_cluster_candidates_t,
    velo_masked_clustering::Parameters::dev_cluster_candidates_t {
  using type = velo_estimate_input_size::Parameters::dev_cluster_candidates_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_estimate_input_size__dev_cluster_candidates_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_masked_clustering::Parameters::host_total_number_of_velo_clusters_t,
    velo_calculate_phi_and_sort::Parameters::host_total_number_of_velo_clusters_t,
    velo_search_by_triplet::Parameters::host_total_number_of_velo_clusters_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_estimated_input_size__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_masked_clustering::Parameters::dev_offsets_estimated_input_size_t,
    velo_calculate_phi_and_sort::Parameters::dev_offsets_estimated_input_size_t,
    velo_search_by_triplet::Parameters::dev_offsets_estimated_input_size_t,
    velo_three_hit_tracks_filter::Parameters::dev_offsets_estimated_input_size_t,
    velo_consolidate_tracks::Parameters::dev_offsets_estimated_input_size_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_estimated_input_size__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_masked_clustering__dev_module_cluster_num_t
  : velo_masked_clustering::Parameters::dev_module_cluster_num_t,
    velo_calculate_phi_and_sort::Parameters::dev_module_cluster_num_t,
    velo_search_by_triplet::Parameters::dev_module_cluster_num_t {
  using type = velo_masked_clustering::Parameters::dev_module_cluster_num_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_masked_clustering__dev_module_cluster_num_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_masked_clustering__dev_velo_cluster_container_t
  : velo_masked_clustering::Parameters::dev_velo_cluster_container_t,
    velo_calculate_phi_and_sort::Parameters::dev_velo_cluster_container_t {
  using type = velo_masked_clustering::Parameters::dev_velo_cluster_container_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_masked_clustering__dev_velo_cluster_container_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t
  : velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t,
    velo_search_by_triplet::Parameters::dev_sorted_velo_cluster_container_t,
    velo_three_hit_tracks_filter::Parameters::dev_sorted_velo_cluster_container_t,
    velo_consolidate_tracks::Parameters::dev_sorted_velo_cluster_container_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_sorted_velo_cluster_container_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_calculate_phi_and_sort__dev_hit_permutation_t
  : velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_permutation_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_calculate_phi_and_sort__dev_hit_permutation_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_calculate_phi_and_sort__dev_hit_phi_t : velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t,
                                                    velo_search_by_triplet::Parameters::dev_hit_phi_t {
  using type = velo_calculate_phi_and_sort::Parameters::dev_hit_phi_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_calculate_phi_and_sort__dev_hit_phi_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_tracks_t : velo_search_by_triplet::Parameters::dev_tracks_t,
                                              velo_copy_track_hit_number::Parameters::dev_tracks_t,
                                              velo_consolidate_tracks::Parameters::dev_tracks_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_tracklets_t : velo_search_by_triplet::Parameters::dev_tracklets_t {
  using type = velo_search_by_triplet::Parameters::dev_tracklets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_tracklets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_tracks_to_follow_t : velo_search_by_triplet::Parameters::dev_tracks_to_follow_t {
  using type = velo_search_by_triplet::Parameters::dev_tracks_to_follow_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_tracks_to_follow_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_three_hit_tracks_t
  : velo_search_by_triplet::Parameters::dev_three_hit_tracks_t,
    velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_input_t {
  using type = velo_search_by_triplet::Parameters::dev_three_hit_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_three_hit_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_hit_used_t : velo_search_by_triplet::Parameters::dev_hit_used_t,
                                                velo_three_hit_tracks_filter::Parameters::dev_hit_used_t {
  using type = velo_search_by_triplet::Parameters::dev_hit_used_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_hit_used_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_atomics_velo_t : velo_search_by_triplet::Parameters::dev_atomics_velo_t,
                                                    velo_three_hit_tracks_filter::Parameters::dev_atomics_velo_t {
  using type = velo_search_by_triplet::Parameters::dev_atomics_velo_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_atomics_velo_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_rel_indices_t : velo_search_by_triplet::Parameters::dev_rel_indices_t {
  using type = velo_search_by_triplet::Parameters::dev_rel_indices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_rel_indices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_search_by_triplet__dev_number_of_velo_tracks_t
  : velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_search_by_triplet::Parameters::dev_number_of_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_search_by_triplet__dev_number_of_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_velo_tracks_at_least_four_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_tracks__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_velo_tracks_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_tracks__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t,
    velo_consolidate_tracks::Parameters::dev_three_hit_tracks_output_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_three_hit_tracks_output_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t
  : velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_three_hit_tracks_filter::Parameters::dev_number_of_three_hit_tracks_output_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_copy_track_hit_number::Parameters::host_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::host_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override
  {
    return "prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t";
  }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_copy_track_hit_number::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t,
    velo_consolidate_tracks::Parameters::dev_offsets_number_of_three_hit_tracks_filtered_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override
  {
    return "prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t";
  }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_consolidate_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_kalman_filter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::host_number_of_reconstructed_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_search_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::host_number_of_reconstructed_velo_tracks_t,
    velo_pv_ip::Parameters::host_number_of_reconstructed_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::host_number_of_reconstructed_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_copy_track_hit_number__dev_velo_track_hit_number_t
  : velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = velo_copy_track_hit_number::Parameters::dev_velo_track_hit_number_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_copy_track_hit_number__dev_velo_track_hit_number_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t
  : velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t,
    velo_consolidate_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    velo_kalman_filter::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_histo::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_all_velo_tracks_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    ut_search_windows::Parameters::dev_offsets_all_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_all_velo_tracks_t,
    compass_ut::Parameters::dev_offsets_all_velo_tracks_t,
    lf_search_initial_windows::Parameters::dev_offsets_all_velo_tracks_t,
    lf_triplet_seeding::Parameters::dev_offsets_all_velo_tracks_t,
    lf_create_tracks::Parameters::dev_offsets_all_velo_tracks_t,
    lf_quality_filter::Parameters::dev_offsets_all_velo_tracks_t,
    velo_pv_ip::Parameters::dev_offsets_all_velo_tracks_t,
    kalman_velo_only::Parameters::dev_offsets_all_velo_tracks_t {
  using type = velo_copy_track_hit_number::Parameters::dev_offsets_all_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    velo_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_velo_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    velo_consolidate_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_kalman_filter::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_extrapolate::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_histo::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_calculate_denom::Parameters::dev_offsets_velo_track_hit_number_t,
    pv_beamline_multi_fitter::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_search_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    compass_ut::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_search_initial_windows::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_create_tracks::Parameters::dev_offsets_velo_track_hit_number_t,
    lf_quality_filter::Parameters::dev_offsets_velo_track_hit_number_t,
    velo_pv_ip::Parameters::dev_offsets_velo_track_hit_number_t,
    kalman_velo_only::Parameters::dev_offsets_velo_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_consolidate_tracks__dev_accepted_velo_tracks_t
  : velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks::Parameters::dev_accepted_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_accepted_velo_tracks_t {
  using type = velo_consolidate_tracks::Parameters::dev_accepted_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_consolidate_tracks__dev_accepted_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_consolidate_tracks__dev_velo_states_t : velo_consolidate_tracks::Parameters::dev_velo_states_t,
                                                    velo_kalman_filter::Parameters::dev_velo_states_t,
                                                    ut_select_velo_tracks::Parameters::dev_velo_states_t,
                                                    ut_search_windows::Parameters::dev_velo_states_t,
                                                    ut_select_velo_tracks_with_windows::Parameters::dev_velo_states_t,
                                                    compass_ut::Parameters::dev_velo_states_t,
                                                    lf_search_initial_windows::Parameters::dev_velo_states_t,
                                                    lf_triplet_seeding::Parameters::dev_velo_states_t,
                                                    lf_create_tracks::Parameters::dev_velo_states_t,
                                                    lf_quality_filter::Parameters::dev_velo_states_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_states_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_consolidate_tracks__dev_velo_states_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_consolidate_tracks__dev_velo_track_hits_t : velo_consolidate_tracks::Parameters::dev_velo_track_hits_t,
                                                        velo_kalman_filter::Parameters::dev_velo_track_hits_t,
                                                        kalman_velo_only::Parameters::dev_velo_track_hits_t {
  using type = velo_consolidate_tracks::Parameters::dev_velo_track_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_consolidate_tracks__dev_velo_track_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_kalman_filter__dev_velo_kalman_beamline_states_t
  : velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t,
    pv_beamline_extrapolate::Parameters::dev_velo_kalman_beamline_states_t,
    velo_pv_ip::Parameters::dev_velo_kalman_beamline_states_t {
  using type = velo_kalman_filter::Parameters::dev_velo_kalman_beamline_states_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_kalman_filter__dev_velo_kalman_beamline_states_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_extrapolate__dev_pvtracks_t : pv_beamline_extrapolate::Parameters::dev_pvtracks_t,
                                                 pv_beamline_histo::Parameters::dev_pvtracks_t,
                                                 pv_beamline_calculate_denom::Parameters::dev_pvtracks_t,
                                                 pv_beamline_multi_fitter::Parameters::dev_pvtracks_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_extrapolate__dev_pvtracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_extrapolate__dev_pvtrack_z_t : pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_pvtrack_z_t {
  using type = pv_beamline_extrapolate::Parameters::dev_pvtrack_z_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_extrapolate__dev_pvtrack_z_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_histo__dev_zhisto_t : pv_beamline_histo::Parameters::dev_zhisto_t,
                                         pv_beamline_peak::Parameters::dev_zhisto_t {
  using type = pv_beamline_histo::Parameters::dev_zhisto_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_histo__dev_zhisto_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_peak__dev_zpeaks_t : pv_beamline_peak::Parameters::dev_zpeaks_t,
                                        pv_beamline_calculate_denom::Parameters::dev_zpeaks_t,
                                        pv_beamline_multi_fitter::Parameters::dev_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_zpeaks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_peak__dev_zpeaks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_peak__dev_number_of_zpeaks_t : pv_beamline_peak::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_calculate_denom::Parameters::dev_number_of_zpeaks_t,
                                                  pv_beamline_multi_fitter::Parameters::dev_number_of_zpeaks_t {
  using type = pv_beamline_peak::Parameters::dev_number_of_zpeaks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_peak__dev_number_of_zpeaks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_calculate_denom__dev_pvtracks_denom_t
  : pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t,
    pv_beamline_multi_fitter::Parameters::dev_pvtracks_denom_t {
  using type = pv_beamline_calculate_denom::Parameters::dev_pvtracks_denom_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_calculate_denom__dev_pvtracks_denom_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_multi_fitter__dev_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_multi_fit_vertices_t,
    velo_pv_ip::Parameters::dev_multi_fit_vertices_t,
    kalman_velo_only::Parameters::dev_multi_fit_vertices_t,
    FilterTracks::Parameters::dev_multi_fit_vertices_t,
    VertexFit::Parameters::dev_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_multi_fit_vertices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_multi_fitter__dev_multi_fit_vertices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t
  : pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup::Parameters::dev_number_of_multi_fit_vertices_t,
    velo_pv_ip::Parameters::dev_number_of_multi_fit_vertices_t,
    kalman_velo_only::Parameters::dev_number_of_multi_fit_vertices_t,
    FilterTracks::Parameters::dev_number_of_multi_fit_vertices_t,
    VertexFit::Parameters::dev_number_of_multi_fit_vertices_t {
  using type = pv_beamline_multi_fitter::Parameters::dev_number_of_multi_fit_vertices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_cleanup__dev_multi_final_vertices_t : pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_multi_final_vertices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_cleanup__dev_multi_final_vertices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct pv_beamline_cleanup__dev_number_of_multi_final_vertices_t
  : pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t {
  using type = pv_beamline_cleanup::Parameters::dev_number_of_multi_final_vertices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "pv_beamline_cleanup__dev_number_of_multi_final_vertices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                   ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_t,
                                   ut_pre_decode::Parameters::dev_ut_raw_input_t,
                                   ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_banks__dev_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                     ut_calculate_number_of_hits::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_pre_decode::Parameters::dev_ut_raw_input_offsets_t,
                                     ut_decode_raw_banks_in_order::Parameters::dev_ut_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_banks__dev_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_calculate_number_of_hits__dev_ut_hit_sizes_t : ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t,
                                                         host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_calculate_number_of_hits::Parameters::dev_ut_hit_sizes_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_calculate_number_of_hits__dev_ut_hit_sizes_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_ut_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_pre_decode::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_find_permutation::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_decode_raw_banks_in_order::Parameters::host_accumulated_number_of_ut_hits_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_ut_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_hits__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_ut_hits__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                 ut_pre_decode::Parameters::dev_ut_hit_offsets_t,
                                                 ut_find_permutation::Parameters::dev_ut_hit_offsets_t,
                                                 ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_offsets_t,
                                                 ut_search_windows::Parameters::dev_ut_hit_offsets_t,
                                                 compass_ut::Parameters::dev_ut_hit_offsets_t,
                                                 ut_consolidate_tracks::Parameters::dev_ut_hit_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_hits__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_pre_decode__dev_ut_pre_decoded_hits_t : ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_find_permutation::Parameters::dev_ut_pre_decoded_hits_t,
                                                  ut_decode_raw_banks_in_order::Parameters::dev_ut_pre_decoded_hits_t {
  using type = ut_pre_decode::Parameters::dev_ut_pre_decoded_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_pre_decode__dev_ut_pre_decoded_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_pre_decode__dev_ut_hit_count_t : ut_pre_decode::Parameters::dev_ut_hit_count_t {
  using type = ut_pre_decode::Parameters::dev_ut_hit_count_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_pre_decode__dev_ut_hit_count_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_find_permutation__dev_ut_hit_permutations_t
  : ut_find_permutation::Parameters::dev_ut_hit_permutations_t,
    ut_decode_raw_banks_in_order::Parameters::dev_ut_hit_permutations_t {
  using type = ut_find_permutation::Parameters::dev_ut_hit_permutations_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_find_permutation__dev_ut_hit_permutations_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_decode_raw_banks_in_order__dev_ut_hits_t : ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t,
                                                     ut_search_windows::Parameters::dev_ut_hits_t,
                                                     compass_ut::Parameters::dev_ut_hits_t,
                                                     ut_consolidate_tracks::Parameters::dev_ut_hits_t {
  using type = ut_decode_raw_banks_in_order::Parameters::dev_ut_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_decode_raw_banks_in_order__dev_ut_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_number_of_selected_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_select_velo_tracks__dev_ut_selected_velo_tracks_t
  : ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t,
    ut_search_windows::Parameters::dev_ut_selected_velo_tracks_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_t {
  using type = ut_select_velo_tracks::Parameters::dev_ut_selected_velo_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_select_velo_tracks__dev_ut_selected_velo_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_search_windows__dev_ut_windows_layers_t
  : ut_search_windows::Parameters::dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_windows_layers_t,
    compass_ut::Parameters::dev_ut_windows_layers_t {
  using type = ut_search_windows::Parameters::dev_ut_windows_layers_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_search_windows__dev_ut_windows_layers_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t {
  using type =
    ut_select_velo_tracks_with_windows::Parameters::dev_ut_number_of_selected_velo_tracks_with_windows_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override
  {
    return "ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t";
  }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t
  : ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t,
    compass_ut::Parameters::dev_ut_selected_velo_tracks_with_windows_t {
  using type = ut_select_velo_tracks_with_windows::Parameters::dev_ut_selected_velo_tracks_with_windows_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override
  {
    return "ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t";
  }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct compass_ut__dev_ut_tracks_t : compass_ut::Parameters::dev_ut_tracks_t,
                                     ut_copy_track_hit_number::Parameters::dev_ut_tracks_t,
                                     ut_consolidate_tracks::Parameters::dev_ut_tracks_t {
  using type = compass_ut::Parameters::dev_ut_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "compass_ut__dev_ut_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct compass_ut__dev_atomics_ut_t : compass_ut::Parameters::dev_atomics_ut_t,
                                      host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = compass_ut::Parameters::dev_atomics_ut_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "compass_ut__dev_atomics_ut_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
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
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_tracks__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
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
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_tracks__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_copy_track_hit_number__dev_ut_track_hit_number_t
  : ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = ut_copy_track_hit_number::Parameters::dev_ut_track_hit_number_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_copy_track_hit_number__dev_ut_track_hit_number_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_ut_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    ut_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_ut_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_track_hit_number__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
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
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_ut_track_hit_number__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_track_hits_t : ut_consolidate_tracks::Parameters::dev_ut_track_hits_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_track_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_qop_t : ut_consolidate_tracks::Parameters::dev_ut_qop_t,
                                             lf_search_initial_windows::Parameters::dev_ut_qop_t,
                                             lf_triplet_seeding::Parameters::dev_ut_qop_t,
                                             lf_create_tracks::Parameters::dev_ut_qop_t,
                                             kalman_velo_only::Parameters::dev_ut_qop_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_qop_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_qop_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_x_t : ut_consolidate_tracks::Parameters::dev_ut_x_t,
                                           lf_search_initial_windows::Parameters::dev_ut_x_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_x_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_x_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_tx_t : ut_consolidate_tracks::Parameters::dev_ut_tx_t,
                                            lf_search_initial_windows::Parameters::dev_ut_tx_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_tx_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_tx_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_z_t : ut_consolidate_tracks::Parameters::dev_ut_z_t,
                                           lf_search_initial_windows::Parameters::dev_ut_z_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_z_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_z_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct ut_consolidate_tracks__dev_ut_track_velo_indices_t
  : ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t,
    lf_search_initial_windows::Parameters::dev_ut_track_velo_indices_t,
    lf_triplet_seeding::Parameters::dev_ut_track_velo_indices_t,
    lf_create_tracks::Parameters::dev_ut_track_velo_indices_t,
    lf_quality_filter::Parameters::dev_ut_track_velo_indices_t,
    kalman_velo_only::Parameters::dev_ut_track_velo_indices_t {
  using type = ut_consolidate_tracks::Parameters::dev_ut_track_velo_indices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "ut_consolidate_tracks__dev_ut_track_velo_indices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                      scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_t,
                                      scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_banks__dev_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                        scifi_calculate_cluster_count_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_pre_decode_v4::Parameters::dev_scifi_raw_input_offsets_t,
                                        scifi_raw_bank_decoder_v4::Parameters::dev_scifi_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_banks__dev_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t
  : scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_calculate_cluster_count_v4::Parameters::dev_scifi_hit_count_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_scifi_hits__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_pre_decode_v4::Parameters::host_accumulated_number_of_scifi_hits_t,
    scifi_raw_bank_decoder_v4::Parameters::host_accumulated_number_of_scifi_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_scifi_hits__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
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
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_scifi_hits__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_pre_decode_v4_t__dev_cluster_references_t
  : scifi_pre_decode_v4::Parameters::dev_cluster_references_t,
    scifi_raw_bank_decoder_v4::Parameters::dev_cluster_references_t {
  using type = scifi_pre_decode_v4::Parameters::dev_cluster_references_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_pre_decode_v4_t__dev_cluster_references_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t : scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t,
                                                       lf_search_initial_windows::Parameters::dev_scifi_hits_t,
                                                       lf_triplet_seeding::Parameters::dev_scifi_hits_t,
                                                       lf_create_tracks::Parameters::dev_scifi_hits_t,
                                                       lf_quality_filter::Parameters::dev_scifi_hits_t,
                                                       scifi_consolidate_tracks::Parameters::dev_scifi_hits_t {
  using type = scifi_raw_bank_decoder_v4::Parameters::dev_scifi_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_initial_windows_t,
    lf_create_tracks::Parameters::dev_scifi_lf_initial_windows_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_initial_windows_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_search_initial_windows_t__dev_ut_states_t : lf_search_initial_windows::Parameters::dev_ut_states_t,
                                                      lf_triplet_seeding::Parameters::dev_ut_states_t,
                                                      lf_create_tracks::Parameters::dev_ut_states_t,
                                                      lf_quality_filter::Parameters::dev_ut_states_t {
  using type = lf_search_initial_windows::Parameters::dev_ut_states_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_search_initial_windows_t__dev_ut_states_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_search_initial_windows_t__dev_scifi_lf_process_track_t
  : lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t,
    lf_triplet_seeding::Parameters::dev_scifi_lf_process_track_t,
    lf_create_tracks::Parameters::dev_scifi_lf_process_track_t {
  using type = lf_search_initial_windows::Parameters::dev_scifi_lf_process_track_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_search_initial_windows_t__dev_scifi_lf_process_track_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_found_triplets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t
  : lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t,
    lf_create_tracks::Parameters::dev_scifi_lf_number_of_found_triplets_t {
  using type = lf_triplet_seeding::Parameters::dev_scifi_lf_number_of_found_triplets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_create_tracks_t__dev_scifi_lf_tracks_t : lf_create_tracks::Parameters::dev_scifi_lf_tracks_t,
                                                   lf_quality_filter_length::Parameters::dev_scifi_lf_tracks_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_create_tracks_t__dev_scifi_lf_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_create_tracks_t__dev_scifi_lf_atomics_t : lf_create_tracks::Parameters::dev_scifi_lf_atomics_t,
                                                    lf_quality_filter_length::Parameters::dev_scifi_lf_atomics_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_atomics_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_create_tracks_t__dev_scifi_lf_atomics_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t
  : lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_total_number_of_found_triplets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_create_tracks_t__dev_scifi_lf_parametrization_t
  : lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t,
    lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_t {
  using type = lf_create_tracks::Parameters::dev_scifi_lf_parametrization_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_create_tracks_t__dev_scifi_lf_parametrization_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_tracks_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter::Parameters::dev_scifi_lf_length_filtered_atomics_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_length_filtered_atomics_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t
  : lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t,
    lf_quality_filter::Parameters::dev_scifi_lf_parametrization_length_filter_t {
  using type = lf_quality_filter_length::Parameters::dev_scifi_lf_parametrization_length_filter_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override
  {
    return "lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t";
  }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_t__dev_lf_quality_of_tracks_t : lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t {
  using type = lf_quality_filter::Parameters::dev_lf_quality_of_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_t__dev_lf_quality_of_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_t__dev_atomics_scifi_t : lf_quality_filter::Parameters::dev_atomics_scifi_t,
                                                  host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = lf_quality_filter::Parameters::dev_atomics_scifi_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_t__dev_atomics_scifi_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_t__dev_scifi_tracks_t : lf_quality_filter::Parameters::dev_scifi_tracks_t,
                                                 scifi_copy_track_hit_number::Parameters::dev_scifi_tracks_t,
                                                 scifi_consolidate_tracks::Parameters::dev_scifi_tracks_t {
  using type = lf_quality_filter::Parameters::dev_scifi_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_t__dev_scifi_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t
  : lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_y_parametrization_length_filter_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t
  : lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks::Parameters::dev_scifi_lf_parametrization_consolidate_t {
  using type = lf_quality_filter::Parameters::dev_scifi_lf_parametrization_consolidate_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_forward_tracks__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_copy_track_hit_number::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    scifi_consolidate_tracks::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    is_muon::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    kalman_velo_only::Parameters::host_number_of_reconstructed_scifi_tracks_t,
    track_mva_line::Parameters::host_number_of_reconstructed_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_forward_tracks__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_forward_tracks__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_copy_track_hit_number::Parameters::dev_offsets_forward_tracks_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_forward_tracks_t,
    is_muon::Parameters::dev_offsets_forward_tracks_t,
    kalman_velo_only::Parameters::dev_offsets_forward_tracks_t,
    FilterTracks::Parameters::dev_offsets_forward_tracks_t,
    VertexFit::Parameters::dev_offsets_forward_tracks_t,
    track_mva_line::Parameters::dev_track_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_forward_tracks__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t
  : scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = scifi_copy_track_hit_number::Parameters::dev_scifi_track_hit_number_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_scifi_track_hit_number__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    scifi_consolidate_tracks::Parameters::host_accumulated_number_of_hits_in_scifi_tracks_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_scifi_track_hit_number__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_scifi_track_hit_number__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    scifi_consolidate_tracks::Parameters::dev_offsets_scifi_track_hit_number_t,
    is_muon::Parameters::dev_offsets_scifi_track_hit_number,
    kalman_velo_only::Parameters::dev_offsets_scifi_track_hit_number_t,
    FilterTracks::Parameters::dev_offsets_scifi_track_hit_number_t,
    VertexFit::Parameters::dev_offsets_scifi_track_hit_number_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_scifi_track_hit_number__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_consolidate_tracks_t__dev_scifi_track_hits_t
  : scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_consolidate_tracks_t__dev_scifi_track_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_consolidate_tracks_t__dev_scifi_qop_t : scifi_consolidate_tracks::Parameters::dev_scifi_qop_t,
                                                     is_muon::Parameters::dev_scifi_qop_t,
                                                     kalman_velo_only::Parameters::dev_scifi_qop_t,
                                                     FilterTracks::Parameters::dev_scifi_qop_t,
                                                     VertexFit::Parameters::dev_scifi_qop_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_qop_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_consolidate_tracks_t__dev_scifi_qop_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_consolidate_tracks_t__dev_scifi_states_t : scifi_consolidate_tracks::Parameters::dev_scifi_states_t,
                                                        is_muon::Parameters::dev_scifi_states_t,
                                                        kalman_velo_only::Parameters::dev_scifi_states_t,
                                                        FilterTracks::Parameters::dev_scifi_states_t,
                                                        VertexFit::Parameters::dev_scifi_states_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_states_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_consolidate_tracks_t__dev_scifi_states_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t
  : scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t,
    is_muon::Parameters::dev_scifi_track_ut_indices_t,
    kalman_velo_only::Parameters::dev_scifi_track_ut_indices_t,
    FilterTracks::Parameters::dev_scifi_track_ut_indices_t,
    VertexFit::Parameters::dev_scifi_track_ut_indices_t {
  using type = scifi_consolidate_tracks::Parameters::dev_scifi_track_ut_indices_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     muon_calculate_srq_size::Parameters::dev_muon_raw_t,
                                     muon_populate_tile_and_tdc::Parameters::dev_muon_raw_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_banks__dev_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       muon_calculate_srq_size::Parameters::dev_muon_raw_offsets_t,
                                       muon_populate_tile_and_tdc::Parameters::dev_muon_raw_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_banks__dev_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_calculate_srq_size_t__dev_muon_raw_to_hits_t
  : muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_tile_and_tdc::Parameters::dev_muon_raw_to_hits_t,
    muon_add_coords_crossing_maps::Parameters::dev_muon_raw_to_hits_t,
    muon_populate_hits::Parameters::dev_muon_raw_to_hits_t {
  using type = muon_calculate_srq_size::Parameters::dev_muon_raw_to_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_calculate_srq_size_t__dev_muon_raw_to_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t
  : muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_calculate_srq_size::Parameters::dev_storage_station_region_quarter_sizes_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_srq_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_tile_and_tdc::Parameters::host_muon_total_number_of_tiles_t,
    muon_add_coords_crossing_maps::Parameters::host_muon_total_number_of_tiles_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_srq_prefix_sum__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_srq_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_tile_and_tdc::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_station_region_quarter_offsets_t,
    muon_populate_hits::Parameters::dev_storage_station_region_quarter_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_srq_prefix_sum__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_populate_tile_and_tdc_t__dev_storage_tile_id_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t,
    muon_add_coords_crossing_maps::Parameters::dev_storage_tile_id_t,
    muon_populate_hits::Parameters::dev_storage_tile_id_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tile_id_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_populate_tile_and_tdc_t__dev_storage_tile_id_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t
  : muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t,
    muon_populate_hits::Parameters::dev_storage_tdc_value_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_storage_tdc_value_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_populate_tile_and_tdc_t__dev_atomics_muon_t : muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t {
  using type = muon_populate_tile_and_tdc::Parameters::dev_atomics_muon_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_populate_tile_and_tdc_t__dev_atomics_muon_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t
  : muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_atomics_index_insert_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t,
    muon_populate_hits::Parameters::dev_muon_compact_hit_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_compact_hit_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_add_coords_crossing_maps_t__dev_muon_tile_used_t
  : muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_muon_tile_used_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_add_coords_crossing_maps_t__dev_muon_tile_used_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t
  : muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t,
    host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = muon_add_coords_crossing_maps::Parameters::dev_station_ocurrences_sizes_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_station_ocurrence_prefix_sum__host_total_sum_holder_t
  : host_prefix_sum::Parameters::host_total_sum_holder_t,
    muon_populate_hits::Parameters::host_muon_total_number_of_hits_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_station_ocurrence_prefix_sum__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_station_ocurrence_prefix_sum__dev_output_buffer_t
  : host_prefix_sum::Parameters::dev_output_buffer_t,
    muon_populate_hits::Parameters::dev_station_ocurrences_offset_t,
    is_muon::Parameters::dev_station_ocurrences_offset_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_station_ocurrence_prefix_sum__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_populate_hits_t__dev_permutation_station_t : muon_populate_hits::Parameters::dev_permutation_station_t {
  using type = muon_populate_hits::Parameters::dev_permutation_station_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_populate_hits_t__dev_permutation_station_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct muon_populate_hits_t__dev_muon_hits_t : muon_populate_hits::Parameters::dev_muon_hits_t,
                                               is_muon::Parameters::dev_muon_hits_t {
  using type = muon_populate_hits::Parameters::dev_muon_hits_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "muon_populate_hits_t__dev_muon_hits_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct is_muon_t__dev_muon_track_occupancies_t : is_muon::Parameters::dev_muon_track_occupancies_t {
  using type = is_muon::Parameters::dev_muon_track_occupancies_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "is_muon_t__dev_muon_track_occupancies_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct is_muon_t__dev_is_muon_t : is_muon::Parameters::dev_is_muon_t, kalman_velo_only::Parameters::dev_is_muon_t {
  using type = is_muon::Parameters::dev_is_muon_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "is_muon_t__dev_is_muon_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct velo_pv_ip_t__dev_velo_pv_ip_t : velo_pv_ip::Parameters::dev_velo_pv_ip_t,
                                        kalman_velo_only::Parameters::dev_velo_pv_ip_t {
  using type = velo_pv_ip::Parameters::dev_velo_pv_ip_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "velo_pv_ip_t__dev_velo_pv_ip_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct kalman_velo_only__dev_kf_tracks_t : kalman_velo_only::Parameters::dev_kf_tracks_t,
                                           FilterTracks::Parameters::dev_kf_tracks_t,
                                           VertexFit::Parameters::dev_kf_tracks_t,
                                           track_mva_line::Parameters::dev_tracks_t {
  using type = kalman_velo_only::Parameters::dev_kf_tracks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "kalman_velo_only__dev_kf_tracks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct kalman_velo_only__dev_kalman_pv_ipchi2_t : kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t,
                                                  FilterTracks::Parameters::dev_kalman_pv_ipchi2_t,
                                                  VertexFit::Parameters::dev_kalman_pv_ipchi2_t {
  using type = kalman_velo_only::Parameters::dev_kalman_pv_ipchi2_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "kalman_velo_only__dev_kalman_pv_ipchi2_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct filter_tracks_t__dev_sv_atomics_t : FilterTracks::Parameters::dev_sv_atomics_t,
                                           host_prefix_sum::Parameters::dev_input_buffer_t {
  using type = FilterTracks::Parameters::dev_sv_atomics_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "filter_tracks_t__dev_sv_atomics_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct filter_tracks_t__dev_svs_trk1_idx_t : FilterTracks::Parameters::dev_svs_trk1_idx_t,
                                             VertexFit::Parameters::dev_svs_trk1_idx_t {
  using type = FilterTracks::Parameters::dev_svs_trk1_idx_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "filter_tracks_t__dev_svs_trk1_idx_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct filter_tracks_t__dev_svs_trk2_idx_t : FilterTracks::Parameters::dev_svs_trk2_idx_t,
                                             VertexFit::Parameters::dev_svs_trk2_idx_t {
  using type = FilterTracks::Parameters::dev_svs_trk2_idx_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "filter_tracks_t__dev_svs_trk2_idx_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_secondary_vertices__host_total_sum_holder_t : host_prefix_sum::Parameters::host_total_sum_holder_t,
                                                                VertexFit::Parameters::host_number_of_svs_t,
                                                                two_track_mva_line::Parameters::host_number_of_svs_t {
  using type = host_prefix_sum::Parameters::host_total_sum_holder_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_secondary_vertices__host_total_sum_holder_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct prefix_sum_secondary_vertices__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t,
                                                            VertexFit::Parameters::dev_sv_offsets_t,
                                                            two_track_mva_line::Parameters::dev_sv_offsets_t {
  using type = host_prefix_sum::Parameters::dev_output_buffer_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "prefix_sum_secondary_vertices__dev_output_buffer_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct fit_secondary_vertices__dev_consolidated_svs_t : VertexFit::Parameters::dev_consolidated_svs_t,
                                                        two_track_mva_line::Parameters::dev_svs_t {
  using type = VertexFit::Parameters::dev_consolidated_svs_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "fit_secondary_vertices__dev_consolidated_svs_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct odin_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t,
                                     beam_crossing_line::Parameters::dev_odin_raw_input_t,
                                     gather_selections::Parameters::dev_odin_raw_input_t {
  using type = data_provider::Parameters::dev_raw_banks_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "odin_banks__dev_raw_banks_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct odin_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t,
                                       beam_crossing_line::Parameters::dev_odin_raw_input_offsets_t,
                                       gather_selections::Parameters::dev_odin_raw_input_offsets_t {
  using type = data_provider::Parameters::dev_raw_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "odin_banks__dev_raw_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__host_selections_lines_offsets_t
  : gather_selections::Parameters::host_selections_lines_offsets_t {
  using type = gather_selections::Parameters::host_selections_lines_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__host_selections_lines_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__host_selections_offsets_t : gather_selections::Parameters::host_selections_offsets_t {
  using type = gather_selections::Parameters::host_selections_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__host_selections_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__host_number_of_active_lines_t : gather_selections::Parameters::host_number_of_active_lines_t {
  using type = gather_selections::Parameters::host_number_of_active_lines_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__host_number_of_active_lines_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__host_names_of_active_lines_t : gather_selections::Parameters::host_names_of_active_lines_t {
  using type = gather_selections::Parameters::host_names_of_active_lines_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__host_names_of_active_lines_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__dev_selections_t : gather_selections::Parameters::dev_selections_t {
  using type = gather_selections::Parameters::dev_selections_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__dev_selections_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct gather_selections__dev_selections_offsets_t : gather_selections::Parameters::dev_selections_offsets_t {
  using type = gather_selections::Parameters::dev_selections_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "gather_selections__dev_selections_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }
private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};

using configured_arguments_t = std::tuple<
  host_ut_banks__host_raw_banks_t,
  host_ut_banks__host_raw_offsets_t,
  host_scifi_banks__host_raw_banks_t,
  host_scifi_banks__host_raw_offsets_t,
  initialize_lists__host_event_list_t,
  initialize_lists__host_number_of_events_t,
  initialize_lists__host_number_of_selected_events_t,
  initialize_lists__dev_number_of_events_t,
  initialize_lists__dev_event_list_t,
  full_event_list__host_number_of_events_t,
  full_event_list__host_event_list_t,
  full_event_list__dev_number_of_events_t,
  full_event_list__dev_event_list_t,
  velo_banks__dev_raw_banks_t,
  velo_banks__dev_raw_offsets_t,
  velo_calculate_number_of_candidates__dev_number_of_candidates_t,
  prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
  prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
  velo_estimate_input_size__dev_estimated_input_size_t,
  velo_estimate_input_size__dev_module_candidate_num_t,
  velo_estimate_input_size__dev_cluster_candidates_t,
  prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
  prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
  velo_masked_clustering__dev_module_cluster_num_t,
  velo_masked_clustering__dev_velo_cluster_container_t,
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
  prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
  prefix_sum_offsets_velo_tracks__dev_output_buffer_t,
  velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
  velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
  prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
  velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
  velo_copy_track_hit_number__dev_velo_track_hit_number_t,
  velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
  prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
  prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
  velo_consolidate_tracks__dev_accepted_velo_tracks_t,
  velo_consolidate_tracks__dev_velo_states_t,
  velo_consolidate_tracks__dev_velo_track_hits_t,
  velo_kalman_filter__dev_velo_kalman_beamline_states_t,
  pv_beamline_extrapolate__dev_pvtracks_t,
  pv_beamline_extrapolate__dev_pvtrack_z_t,
  pv_beamline_histo__dev_zhisto_t,
  pv_beamline_peak__dev_zpeaks_t,
  pv_beamline_peak__dev_number_of_zpeaks_t,
  pv_beamline_calculate_denom__dev_pvtracks_denom_t,
  pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
  pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
  pv_beamline_cleanup__dev_multi_final_vertices_t,
  pv_beamline_cleanup__dev_number_of_multi_final_vertices_t,
  ut_banks__dev_raw_banks_t,
  ut_banks__dev_raw_offsets_t,
  ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
  prefix_sum_ut_hits__host_total_sum_holder_t,
  prefix_sum_ut_hits__dev_output_buffer_t,
  ut_pre_decode__dev_ut_pre_decoded_hits_t,
  ut_pre_decode__dev_ut_hit_count_t,
  ut_find_permutation__dev_ut_hit_permutations_t,
  ut_decode_raw_banks_in_order__dev_ut_hits_t,
  ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
  ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
  ut_search_windows__dev_ut_windows_layers_t,
  ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
  ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
  compass_ut__dev_ut_tracks_t,
  compass_ut__dev_atomics_ut_t,
  prefix_sum_ut_tracks__host_total_sum_holder_t,
  prefix_sum_ut_tracks__dev_output_buffer_t,
  ut_copy_track_hit_number__dev_ut_track_hit_number_t,
  prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
  prefix_sum_ut_track_hit_number__dev_output_buffer_t,
  ut_consolidate_tracks__dev_ut_track_hits_t,
  ut_consolidate_tracks__dev_ut_qop_t,
  ut_consolidate_tracks__dev_ut_x_t,
  ut_consolidate_tracks__dev_ut_tx_t,
  ut_consolidate_tracks__dev_ut_z_t,
  ut_consolidate_tracks__dev_ut_track_velo_indices_t,
  scifi_banks__dev_raw_banks_t,
  scifi_banks__dev_raw_offsets_t,
  scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t,
  prefix_sum_scifi_hits__host_total_sum_holder_t,
  prefix_sum_scifi_hits__dev_output_buffer_t,
  scifi_pre_decode_v4_t__dev_cluster_references_t,
  scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
  lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
  lf_search_initial_windows_t__dev_ut_states_t,
  lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
  lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
  lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t,
  lf_create_tracks_t__dev_scifi_lf_tracks_t,
  lf_create_tracks_t__dev_scifi_lf_atomics_t,
  lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t,
  lf_create_tracks_t__dev_scifi_lf_parametrization_t,
  lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
  lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
  lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t,
  lf_quality_filter_t__dev_lf_quality_of_tracks_t,
  lf_quality_filter_t__dev_atomics_scifi_t,
  lf_quality_filter_t__dev_scifi_tracks_t,
  lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t,
  lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t,
  prefix_sum_forward_tracks__host_total_sum_holder_t,
  prefix_sum_forward_tracks__dev_output_buffer_t,
  scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t,
  prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
  prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
  scifi_consolidate_tracks_t__dev_scifi_track_hits_t,
  scifi_consolidate_tracks_t__dev_scifi_qop_t,
  scifi_consolidate_tracks_t__dev_scifi_states_t,
  scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
  muon_banks__dev_raw_banks_t,
  muon_banks__dev_raw_offsets_t,
  muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
  muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t,
  muon_srq_prefix_sum__host_total_sum_holder_t,
  muon_srq_prefix_sum__dev_output_buffer_t,
  muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
  muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
  muon_populate_tile_and_tdc_t__dev_atomics_muon_t,
  muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t,
  muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
  muon_add_coords_crossing_maps_t__dev_muon_tile_used_t,
  muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t,
  muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
  muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
  muon_populate_hits_t__dev_permutation_station_t,
  muon_populate_hits_t__dev_muon_hits_t,
  is_muon_t__dev_muon_track_occupancies_t,
  is_muon_t__dev_is_muon_t,
  velo_pv_ip_t__dev_velo_pv_ip_t,
  kalman_velo_only__dev_kf_tracks_t,
  kalman_velo_only__dev_kalman_pv_ipchi2_t,
  filter_tracks_t__dev_sv_atomics_t,
  filter_tracks_t__dev_svs_trk1_idx_t,
  filter_tracks_t__dev_svs_trk2_idx_t,
  prefix_sum_secondary_vertices__host_total_sum_holder_t,
  prefix_sum_secondary_vertices__dev_output_buffer_t,
  fit_secondary_vertices__dev_consolidated_svs_t,
  odin_banks__dev_raw_banks_t,
  odin_banks__dev_raw_offsets_t,
  track_mva_line__dev_decisions_t,
  track_mva_line__dev_decisions_offsets_t,
  two_track_mva_line__dev_decisions_t,
  two_track_mva_line__dev_decisions_offsets_t,
  no_beam_line__dev_decisions_t,
  no_beam_line__dev_decisions_offsets_t,
  beam_one_line__dev_decisions_t,
  beam_one_line__dev_decisions_offsets_t,
  beam_two_line__dev_decisions_t,
  beam_two_line__dev_decisions_offsets_t,
  gather_selections__host_selections_lines_offsets_t,
  gather_selections__host_selections_offsets_t,
  gather_selections__host_number_of_active_lines_t,
  gather_selections__host_names_of_active_lines_t,
  gather_selections__dev_selections_t,
  gather_selections__dev_selections_offsets_t>;

using configured_sequence_t = std::tuple<
  host_data_provider::host_data_provider_t,
  host_data_provider::host_data_provider_t,
  host_global_event_cut::host_global_event_cut_t,
  host_init_event_list::host_init_event_list_t,
  data_provider::data_provider_t,
  velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_estimate_input_size::velo_estimate_input_size_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_masked_clustering::velo_masked_clustering_t,
  velo_calculate_phi_and_sort::velo_calculate_phi_and_sort_t,
  velo_search_by_triplet::velo_search_by_triplet_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_copy_track_hit_number::velo_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  velo_consolidate_tracks::velo_consolidate_tracks_t,
  velo_kalman_filter::velo_kalman_filter_t,
  pv_beamline_extrapolate::pv_beamline_extrapolate_t,
  pv_beamline_histo::pv_beamline_histo_t,
  pv_beamline_peak::pv_beamline_peak_t,
  pv_beamline_calculate_denom::pv_beamline_calculate_denom_t,
  pv_beamline_multi_fitter::pv_beamline_multi_fitter_t,
  pv_beamline_cleanup::pv_beamline_cleanup_t,
  data_provider::data_provider_t,
  ut_calculate_number_of_hits::ut_calculate_number_of_hits_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_pre_decode::ut_pre_decode_t,
  ut_find_permutation::ut_find_permutation_t,
  ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_t,
  ut_select_velo_tracks::ut_select_velo_tracks_t,
  ut_search_windows::ut_search_windows_t,
  ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows_t,
  compass_ut::compass_ut_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_copy_track_hit_number::ut_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  ut_consolidate_tracks::ut_consolidate_tracks_t,
  data_provider::data_provider_t,
  scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_pre_decode_v4::scifi_pre_decode_v4_t,
  scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_t,
  lf_search_initial_windows::lf_search_initial_windows_t,
  lf_triplet_seeding::lf_triplet_seeding_t,
  lf_create_tracks::lf_create_tracks_t,
  lf_quality_filter_length::lf_quality_filter_length_t,
  lf_quality_filter::lf_quality_filter_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_copy_track_hit_number::scifi_copy_track_hit_number_t,
  host_prefix_sum::host_prefix_sum_t,
  scifi_consolidate_tracks::scifi_consolidate_tracks_t,
  data_provider::data_provider_t,
  muon_calculate_srq_size::muon_calculate_srq_size_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t,
  muon_add_coords_crossing_maps::muon_add_coords_crossing_maps_t,
  host_prefix_sum::host_prefix_sum_t,
  muon_populate_hits::muon_populate_hits_t,
  is_muon::is_muon_t,
  velo_pv_ip::velo_pv_ip_t,
  kalman_velo_only::kalman_velo_only_t,
  FilterTracks::filter_tracks_t,
  host_prefix_sum::host_prefix_sum_t,
  VertexFit::fit_secondary_vertices_t,
  data_provider::data_provider_t,
  track_mva_line::track_mva_line_t,
  two_track_mva_line::two_track_mva_line_t,
  beam_crossing_line::beam_crossing_line_t,
  beam_crossing_line::beam_crossing_line_t,
  beam_crossing_line::beam_crossing_line_t,
  gather_selections::gather_selections_t>;

using configured_sequence_arguments_t = std::tuple<
  std::tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t>,
  std::tuple<host_scifi_banks__host_raw_banks_t, host_scifi_banks__host_raw_offsets_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    initialize_lists__host_event_list_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__host_number_of_selected_events_t,
    initialize_lists__dev_number_of_events_t,
    initialize_lists__dev_event_list_t>,
  std::tuple<
    host_ut_banks__host_raw_banks_t,
    host_ut_banks__host_raw_offsets_t,
    host_scifi_banks__host_raw_banks_t,
    host_scifi_banks__host_raw_offsets_t,
    full_event_list__host_number_of_events_t,
    full_event_list__host_event_list_t,
    full_event_list__dev_number_of_events_t,
    full_event_list__dev_event_list_t>,
  std::tuple<velo_banks__dev_raw_banks_t, velo_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t>,
  std::tuple<
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    velo_calculate_number_of_candidates__dev_number_of_candidates_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_velo_candidates__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    velo_estimate_input_size__dev_estimated_input_size_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_lists__host_number_of_events_t,
    velo_banks__dev_raw_banks_t,
    velo_banks__dev_raw_offsets_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_estimate_input_size__dev_module_candidate_num_t,
    velo_estimate_input_size__dev_cluster_candidates_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_offsets_velo_candidates__dev_output_buffer_t,
    initialize_lists__dev_number_of_events_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_masked_clustering__dev_module_cluster_num_t,
    velo_masked_clustering__dev_velo_cluster_container_t,
    initialize_lists__dev_number_of_events_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    velo_calculate_phi_and_sort__dev_hit_permutation_t,
    velo_calculate_phi_and_sort__dev_hit_phi_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_offsets_estimated_input_size__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
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
    velo_search_by_triplet__dev_number_of_velo_tracks_t>,
  std::tuple<
    prefix_sum_offsets_velo_tracks__host_total_sum_holder_t,
    velo_search_by_triplet__dev_number_of_velo_tracks_t,
    prefix_sum_offsets_velo_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_search_by_triplet__dev_three_hit_tracks_t,
    velo_search_by_triplet__dev_atomics_velo_t,
    velo_search_by_triplet__dev_hit_used_t,
    initialize_lists__dev_number_of_events_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t>,
  std::tuple<
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    velo_three_hit_tracks_filter__dev_number_of_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
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
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_offsets_velo_track_hit_number__host_total_sum_holder_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__host_total_sum_holder_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_search_by_triplet__dev_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_calculate_phi_and_sort__dev_sorted_velo_cluster_container_t,
    prefix_sum_offsets_estimated_input_size__dev_output_buffer_t,
    velo_three_hit_tracks_filter__dev_three_hit_tracks_output_t,
    prefix_sum_offsets_number_of_three_hit_tracks_filtered__dev_output_buffer_t,
    initialize_lists__dev_number_of_events_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    velo_consolidate_tracks__dev_velo_states_t,
    velo_consolidate_tracks__dev_velo_track_hits_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    velo_consolidate_tracks__dev_velo_states_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_extrapolate__dev_pvtrack_z_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_histo__dev_zhisto_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    pv_beamline_histo__dev_zhisto_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_extrapolate__dev_pvtracks_t,
    pv_beamline_peak__dev_zpeaks_t,
    pv_beamline_peak__dev_number_of_zpeaks_t,
    pv_beamline_calculate_denom__dev_pvtracks_denom_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
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
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    pv_beamline_cleanup__dev_multi_final_vertices_t,
    pv_beamline_cleanup__dev_number_of_multi_final_vertices_t>,
  std::tuple<ut_banks__dev_raw_banks_t, ut_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    ut_calculate_number_of_hits__dev_ut_hit_sizes_t,
    prefix_sum_ut_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_pre_decode__dev_ut_hit_count_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    initialize_lists__dev_event_list_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_hits__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_banks__dev_raw_banks_t,
    ut_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    ut_pre_decode__dev_ut_pre_decoded_hits_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    ut_find_permutation__dev_ut_hit_permutations_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    initialize_lists__dev_event_list_t,
    ut_search_windows__dev_ut_windows_layers_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    velo_consolidate_tracks__dev_accepted_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_number_of_selected_velo_tracks_t,
    ut_select_velo_tracks__dev_ut_selected_velo_tracks_t,
    ut_search_windows__dev_ut_windows_layers_t,
    initialize_lists__dev_event_list_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    ut_search_windows__dev_ut_windows_layers_t,
    ut_select_velo_tracks_with_windows__dev_ut_number_of_selected_velo_tracks_with_windows_t,
    ut_select_velo_tracks_with_windows__dev_ut_selected_velo_tracks_with_windows_t,
    initialize_lists__dev_event_list_t,
    compass_ut__dev_ut_tracks_t,
    compass_ut__dev_atomics_ut_t>,
  std::tuple<
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_atomics_ut_t,
    prefix_sum_ut_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    compass_ut__dev_ut_tracks_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t>,
  std::tuple<
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    ut_copy_track_hit_number__dev_ut_track_hit_number_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    prefix_sum_ut_hits__host_total_sum_holder_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_track_hit_number__host_total_sum_holder_t,
    initialize_lists__dev_number_of_events_t,
    ut_decode_raw_banks_in_order__dev_ut_hits_t,
    prefix_sum_ut_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    compass_ut__dev_ut_tracks_t,
    initialize_lists__dev_event_list_t,
    ut_consolidate_tracks__dev_ut_track_hits_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t>,
  std::tuple<scifi_banks__dev_raw_banks_t, scifi_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t>,
  std::tuple<
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_calculate_cluster_count_v4_t__dev_scifi_hit_count_t,
    prefix_sum_scifi_hits__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    initialize_lists__dev_event_list_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode_v4_t__dev_cluster_references_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_hits__host_total_sum_holder_t,
    scifi_banks__dev_raw_banks_t,
    scifi_banks__dev_raw_offsets_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    scifi_pre_decode_v4_t__dev_cluster_references_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_x_t,
    ut_consolidate_tracks__dev_ut_tx_t,
    ut_consolidate_tracks__dev_ut_z_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    velo_consolidate_tracks__dev_velo_states_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
    lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_search_initial_windows_t__dev_scifi_lf_initial_windows_t,
    lf_search_initial_windows_t__dev_scifi_lf_process_track_t,
    lf_triplet_seeding_t__dev_scifi_lf_found_triplets_t,
    lf_triplet_seeding_t__dev_scifi_lf_number_of_found_triplets_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_states_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    lf_create_tracks_t__dev_scifi_lf_tracks_t,
    lf_create_tracks_t__dev_scifi_lf_atomics_t,
    lf_create_tracks_t__dev_scifi_lf_total_number_of_found_triplets_t,
    lf_create_tracks_t__dev_scifi_lf_parametrization_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_create_tracks_t__dev_scifi_lf_tracks_t,
    lf_create_tracks_t__dev_scifi_lf_atomics_t,
    lf_create_tracks_t__dev_scifi_lf_parametrization_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_ut_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_tracks_t,
    lf_quality_filter_length_t__dev_scifi_lf_length_filtered_atomics_t,
    lf_quality_filter_length_t__dev_scifi_lf_parametrization_length_filter_t,
    lf_search_initial_windows_t__dev_ut_states_t,
    velo_consolidate_tracks__dev_velo_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    lf_quality_filter_t__dev_lf_quality_of_tracks_t,
    lf_quality_filter_t__dev_atomics_scifi_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    lf_quality_filter_t__dev_scifi_lf_y_parametrization_length_filter_t,
    lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t>,
  std::tuple<
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    lf_quality_filter_t__dev_atomics_scifi_t,
    prefix_sum_forward_tracks__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t>,
  std::tuple<
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    scifi_copy_track_hit_number_t__dev_scifi_track_hit_number_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_scifi_track_hit_number__host_total_sum_holder_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    scifi_raw_bank_decoder_v4_t__dev_scifi_hits_t,
    prefix_sum_scifi_hits__dev_output_buffer_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    lf_quality_filter_t__dev_scifi_tracks_t,
    lf_quality_filter_t__dev_scifi_lf_parametrization_consolidate_t,
    scifi_consolidate_tracks_t__dev_scifi_track_hits_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t>,
  std::tuple<muon_banks__dev_raw_banks_t, muon_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t>,
  std::tuple<
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_calculate_srq_size_t__dev_storage_station_region_quarter_sizes_t,
    muon_srq_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    muon_banks__dev_raw_banks_t,
    muon_banks__dev_raw_offsets_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
    muon_populate_tile_and_tdc_t__dev_atomics_muon_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_srq_prefix_sum__host_total_sum_holder_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    initialize_lists__dev_event_list_t,
    muon_add_coords_crossing_maps_t__dev_atomics_index_insert_t,
    muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
    muon_add_coords_crossing_maps_t__dev_muon_tile_used_t,
    muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t>,
  std::tuple<
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    muon_add_coords_crossing_maps_t__dev_station_ocurrences_sizes_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    muon_station_ocurrence_prefix_sum__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    muon_populate_tile_and_tdc_t__dev_storage_tile_id_t,
    muon_populate_tile_and_tdc_t__dev_storage_tdc_value_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_add_coords_crossing_maps_t__dev_muon_compact_hit_t,
    muon_calculate_srq_size_t__dev_muon_raw_to_hits_t,
    muon_srq_prefix_sum__dev_output_buffer_t,
    muon_populate_hits_t__dev_permutation_station_t,
    muon_populate_hits_t__dev_muon_hits_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
    muon_station_ocurrence_prefix_sum__dev_output_buffer_t,
    muon_populate_hits_t__dev_muon_hits_t,
    is_muon_t__dev_muon_track_occupancies_t,
    is_muon_t__dev_is_muon_t>,
  std::tuple<
    velo_copy_track_hit_number__host_number_of_reconstructed_velo_tracks_t,
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_kalman_filter__dev_velo_kalman_beamline_states_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    velo_pv_ip_t__dev_velo_pv_ip_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    velo_copy_track_hit_number__dev_offsets_all_velo_tracks_t,
    prefix_sum_offsets_velo_track_hit_number__dev_output_buffer_t,
    velo_consolidate_tracks__dev_velo_track_hits_t,
    prefix_sum_ut_tracks__dev_output_buffer_t,
    prefix_sum_ut_track_hit_number__dev_output_buffer_t,
    ut_consolidate_tracks__dev_ut_qop_t,
    ut_consolidate_tracks__dev_ut_track_velo_indices_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
    velo_pv_ip_t__dev_velo_pv_ip_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    is_muon_t__dev_is_muon_t,
    kalman_velo_only__dev_kf_tracks_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t,
    filter_tracks_t__dev_sv_atomics_t,
    filter_tracks_t__dev_svs_trk1_idx_t,
    filter_tracks_t__dev_svs_trk2_idx_t>,
  std::tuple<
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    filter_tracks_t__dev_sv_atomics_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    initialize_lists__dev_event_list_t,
    initialize_lists__dev_number_of_events_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    prefix_sum_scifi_track_hit_number__dev_output_buffer_t,
    scifi_consolidate_tracks_t__dev_scifi_qop_t,
    scifi_consolidate_tracks_t__dev_scifi_states_t,
    scifi_consolidate_tracks_t__dev_scifi_track_ut_indices_t,
    pv_beamline_multi_fitter__dev_multi_fit_vertices_t,
    pv_beamline_multi_fitter__dev_number_of_multi_fit_vertices_t,
    kalman_velo_only__dev_kalman_pv_ipchi2_t,
    filter_tracks_t__dev_svs_trk1_idx_t,
    filter_tracks_t__dev_svs_trk2_idx_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    fit_secondary_vertices__dev_consolidated_svs_t>,
  std::tuple<odin_banks__dev_raw_banks_t, odin_banks__dev_raw_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_forward_tracks__host_total_sum_holder_t,
    kalman_velo_only__dev_kf_tracks_t,
    prefix_sum_forward_tracks__dev_output_buffer_t,
    initialize_lists__dev_event_list_t,
    track_mva_line__dev_decisions_t,
    track_mva_line__dev_decisions_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    prefix_sum_secondary_vertices__host_total_sum_holder_t,
    fit_secondary_vertices__dev_consolidated_svs_t,
    prefix_sum_secondary_vertices__dev_output_buffer_t,
    initialize_lists__dev_event_list_t,
    two_track_mva_line__dev_decisions_t,
    two_track_mva_line__dev_decisions_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    full_event_list__dev_event_list_t,
    odin_banks__dev_raw_banks_t,
    odin_banks__dev_raw_offsets_t,
    no_beam_line__dev_decisions_t,
    no_beam_line__dev_decisions_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    full_event_list__dev_event_list_t,
    odin_banks__dev_raw_banks_t,
    odin_banks__dev_raw_offsets_t,
    beam_one_line__dev_decisions_t,
    beam_one_line__dev_decisions_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    full_event_list__dev_event_list_t,
    odin_banks__dev_raw_banks_t,
    odin_banks__dev_raw_offsets_t,
    beam_two_line__dev_decisions_t,
    beam_two_line__dev_decisions_offsets_t>,
  std::tuple<
    initialize_lists__host_number_of_events_t,
    gather_selections__host_selections_lines_offsets_t,
    gather_selections__host_selections_offsets_t,
    gather_selections__host_number_of_active_lines_t,
    gather_selections__host_names_of_active_lines_t,
    track_mva_line__dev_decisions_t,
    two_track_mva_line__dev_decisions_t,
    no_beam_line__dev_decisions_t,
    beam_one_line__dev_decisions_t,
    beam_two_line__dev_decisions_t,
    track_mva_line__dev_decisions_offsets_t,
    two_track_mva_line__dev_decisions_offsets_t,
    no_beam_line__dev_decisions_offsets_t,
    beam_one_line__dev_decisions_offsets_t,
    beam_two_line__dev_decisions_offsets_t,
    odin_banks__dev_raw_banks_t,
    odin_banks__dev_raw_offsets_t,
    gather_selections__dev_selections_t,
    gather_selections__dev_selections_offsets_t>>;

void inline populate_sequence_algorithm_names(configured_sequence_t& sequence)
{
  std::get<0>(sequence).set_name("host_ut_banks");
  std::get<1>(sequence).set_name("host_scifi_banks");
  std::get<2>(sequence).set_name("initialize_lists");
  std::get<3>(sequence).set_name("full_event_list");
  std::get<4>(sequence).set_name("velo_banks");
  std::get<5>(sequence).set_name("velo_calculate_number_of_candidates");
  std::get<6>(sequence).set_name("prefix_sum_offsets_velo_candidates");
  std::get<7>(sequence).set_name("velo_estimate_input_size");
  std::get<8>(sequence).set_name("prefix_sum_offsets_estimated_input_size");
  std::get<9>(sequence).set_name("velo_masked_clustering");
  std::get<10>(sequence).set_name("velo_calculate_phi_and_sort");
  std::get<11>(sequence).set_name("velo_search_by_triplet");
  std::get<12>(sequence).set_name("prefix_sum_offsets_velo_tracks");
  std::get<13>(sequence).set_name("velo_three_hit_tracks_filter");
  std::get<14>(sequence).set_name("prefix_sum_offsets_number_of_three_hit_tracks_filtered");
  std::get<15>(sequence).set_name("velo_copy_track_hit_number");
  std::get<16>(sequence).set_name("prefix_sum_offsets_velo_track_hit_number");
  std::get<17>(sequence).set_name("velo_consolidate_tracks");
  std::get<18>(sequence).set_name("velo_kalman_filter");
  std::get<19>(sequence).set_name("pv_beamline_extrapolate");
  std::get<20>(sequence).set_name("pv_beamline_histo");
  std::get<21>(sequence).set_name("pv_beamline_peak");
  std::get<22>(sequence).set_name("pv_beamline_calculate_denom");
  std::get<23>(sequence).set_name("pv_beamline_multi_fitter");
  std::get<24>(sequence).set_name("pv_beamline_cleanup");
  std::get<25>(sequence).set_name("ut_banks");
  std::get<26>(sequence).set_name("ut_calculate_number_of_hits");
  std::get<27>(sequence).set_name("prefix_sum_ut_hits");
  std::get<28>(sequence).set_name("ut_pre_decode");
  std::get<29>(sequence).set_name("ut_find_permutation");
  std::get<30>(sequence).set_name("ut_decode_raw_banks_in_order");
  std::get<31>(sequence).set_name("ut_select_velo_tracks");
  std::get<32>(sequence).set_name("ut_search_windows");
  std::get<33>(sequence).set_name("ut_select_velo_tracks_with_windows");
  std::get<34>(sequence).set_name("compass_ut");
  std::get<35>(sequence).set_name("prefix_sum_ut_tracks");
  std::get<36>(sequence).set_name("ut_copy_track_hit_number");
  std::get<37>(sequence).set_name("prefix_sum_ut_track_hit_number");
  std::get<38>(sequence).set_name("ut_consolidate_tracks");
  std::get<39>(sequence).set_name("scifi_banks");
  std::get<40>(sequence).set_name("scifi_calculate_cluster_count_v4_t");
  std::get<41>(sequence).set_name("prefix_sum_scifi_hits");
  std::get<42>(sequence).set_name("scifi_pre_decode_v4_t");
  std::get<43>(sequence).set_name("scifi_raw_bank_decoder_v4_t");
  std::get<44>(sequence).set_name("lf_search_initial_windows_t");
  std::get<45>(sequence).set_name("lf_triplet_seeding_t");
  std::get<46>(sequence).set_name("lf_create_tracks_t");
  std::get<47>(sequence).set_name("lf_quality_filter_length_t");
  std::get<48>(sequence).set_name("lf_quality_filter_t");
  std::get<49>(sequence).set_name("prefix_sum_forward_tracks");
  std::get<50>(sequence).set_name("scifi_copy_track_hit_number_t");
  std::get<51>(sequence).set_name("prefix_sum_scifi_track_hit_number");
  std::get<52>(sequence).set_name("scifi_consolidate_tracks_t");
  std::get<53>(sequence).set_name("muon_banks");
  std::get<54>(sequence).set_name("muon_calculate_srq_size_t");
  std::get<55>(sequence).set_name("muon_srq_prefix_sum");
  std::get<56>(sequence).set_name("muon_populate_tile_and_tdc_t");
  std::get<57>(sequence).set_name("muon_add_coords_crossing_maps_t");
  std::get<58>(sequence).set_name("muon_station_ocurrence_prefix_sum");
  std::get<59>(sequence).set_name("muon_populate_hits_t");
  std::get<60>(sequence).set_name("is_muon_t");
  std::get<61>(sequence).set_name("velo_pv_ip_t");
  std::get<62>(sequence).set_name("kalman_velo_only");
  std::get<63>(sequence).set_name("filter_tracks_t");
  std::get<64>(sequence).set_name("prefix_sum_secondary_vertices");
  std::get<65>(sequence).set_name("fit_secondary_vertices");
  std::get<66>(sequence).set_name("odin_banks");
  std::get<67>(sequence).set_name("track_mva_line");
  std::get<68>(sequence).set_name("two_track_mva_line");
  std::get<69>(sequence).set_name("no_beam_line");
  std::get<70>(sequence).set_name("beam_one_line");
  std::get<71>(sequence).set_name("beam_two_line");
  std::get<72>(sequence).set_name("gather_selections");
}
