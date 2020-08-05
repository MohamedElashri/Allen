#include "HostBuffers.cuh"
#include "CudaCommon.h"
#include "VeloEventModel.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "TrackChecker.h"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "PV_Definitions.cuh"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"
#include "BeamlinePVConstants.cuh"
#include "LookingForwardConstants.cuh"
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"
#include "HltSelReport.cuh"

void HostBuffers::reserve(const unsigned max_number_of_events, const bool do_check, const unsigned number_of_hlt1_lines)
{
  // Datatypes needed to run, regardless of checking
  // Note: These datatypes must be pinned to allow for asynchronicity
  cudaCheck(cudaMallocHost((void**) &host_number_of_selected_events, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_total_number_of_velo_clusters, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_velo_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_velo_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_ut_hits, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_ut_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_ut_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_scifi_hits, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_scifi_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_scifi_tracks, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_lf_total_number_of_candidates, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_lf_total_size_first_window_layer, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_muon_total_number_of_tiles, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_svs, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_muon_total_number_of_hits, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_sel_rep_words, sizeof(unsigned)));
  cudaCheck(cudaMallocHost((void**) &host_selected_events_mf, sizeof(unsigned)));

  // Initialize for sequences that don't fill this in.
  host_number_of_events = 0;

  // Buffer for performing GEC on CPU
  cudaCheck(cudaMallocHost((void**) &host_event_list, max_number_of_events * sizeof(unsigned)));

  // Buffer for saving events passing Hlt1 selections.
  cudaCheck(cudaMallocHost((void**) &host_passing_event_list, max_number_of_events * sizeof(bool)));

  // Buffers for output of HLT1 lines
  host_number_of_hlt1_lines = number_of_hlt1_lines;
  cudaCheck(cudaMallocHost((void**) &host_sel_results_atomics, (number_of_hlt1_lines + 1) * sizeof(unsigned)));

  host_sel_results_size = max_number_of_events * 1000 * number_of_hlt1_lines * sizeof(bool);
  cudaCheck(cudaMallocHost((void**) &host_sel_results, host_sel_results_size));

  // Buffer for saving raw banks.
  cudaCheck(
    cudaMallocHost((void**) &host_dec_reports, (number_of_hlt1_lines + 2) * max_number_of_events * sizeof(unsigned)));

  host_sel_rep_raw_banks_size =
    4 * HltSelRepRawBank::DefaultAllocation::kDefaultAllocation * max_number_of_events * sizeof(unsigned);
  cudaCheck(cudaMallocHost((void**) &host_sel_rep_raw_banks, host_sel_rep_raw_banks_size));
  cudaCheck(cudaMallocHost((void**) &host_sel_rep_offsets, (2 * max_number_of_events + 1) * sizeof(unsigned)));

  // Buffer for performing prefix sum
  // Note: If it is of insufficient space, it will get reallocated
  host_allocated_prefix_sum_space = 10000000;
  cudaCheck(cudaMallocHost((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(unsigned)));

  // Needed for track monitoring
  cudaCheck(cudaMallocHost((void**) &host_atomics_scifi, max_number_of_events * SciFi::num_atomics * sizeof(int)));
  cudaCheck(cudaMallocHost(
    (void**) &host_kf_tracks,
    max_number_of_events * SciFi::Constants::max_tracks * sizeof(ParKalmanFilter::FittedTrack)));

  // Needed for PV monitoring
  cudaCheck(cudaMallocHost(
    (void**) &host_reconstructed_multi_pvs, max_number_of_events * PV::max_number_vertices * sizeof(PV::Vertex)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_multivertex, max_number_of_events * sizeof(int)));

  // Needed for SV monitoring
  host_secondary_vertices_size =
    max_number_of_events * SciFi::Constants::max_tracks * 10 * sizeof(VertexFit::TrackMVAVertex);
  cudaCheck(cudaMallocHost((void**) &host_secondary_vertices, host_secondary_vertices_size));
  cudaCheck(cudaMallocHost((void**) &host_sv_offsets, (max_number_of_events + 1) * sizeof(unsigned)));

  host_mf_secondary_vertices_size =
    max_number_of_events * UT::Constants::max_num_tracks * 10 * sizeof(VertexFit::TrackMVAVertex);
  cudaCheck(cudaMallocHost((void**) &host_mf_secondary_vertices, host_mf_secondary_vertices_size));
  cudaCheck(cudaMallocHost((void**) &host_mf_sv_offsets, (max_number_of_events + 1) * sizeof(unsigned)));

  if (do_check) {
    // Datatypes to be reserved only if checking is on
    // Note: These datatypes in principle do not require to be pinned
    host_atomics_velo =
      reinterpret_cast<decltype(host_atomics_velo)>(malloc((2 * max_number_of_events + 1) * sizeof(int)));
    host_velo_track_hit_number = reinterpret_cast<decltype(host_velo_track_hit_number)>(
      malloc(max_number_of_events * Velo::Constants::max_tracks * sizeof(unsigned)));
    host_velo_track_hits = reinterpret_cast<decltype(host_velo_track_hits)>(
      malloc(max_number_of_events * Velo::Constants::max_tracks * Velo::Constants::max_track_size * sizeof(Velo::Hit)));
    host_kalmanvelo_states = reinterpret_cast<decltype(host_kalmanvelo_states)>(
      malloc(max_number_of_events * Velo::Constants::max_tracks * Velo::Consolidated::States::size));

    host_atomics_ut =
      reinterpret_cast<decltype(host_atomics_ut)>(malloc(UT::num_atomics * (max_number_of_events + 1) * sizeof(int)));
    host_ut_tracks = reinterpret_cast<decltype(host_ut_tracks)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(UT::TrackHits)));
    host_ut_track_hit_number = reinterpret_cast<decltype(host_ut_track_hit_number)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(unsigned)));
    host_ut_track_hits = reinterpret_cast<decltype(host_ut_track_hits)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * UT::Constants::max_track_size * sizeof(UT::Hit)));
    host_ut_qop = reinterpret_cast<decltype(host_ut_qop)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    host_ut_x = reinterpret_cast<decltype(host_ut_x)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    host_ut_tx = reinterpret_cast<decltype(host_ut_tx)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    host_ut_z = reinterpret_cast<decltype(host_ut_z)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    host_ut_track_velo_indices = reinterpret_cast<decltype(host_ut_track_velo_indices)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(int)));

    host_scifi_tracks = reinterpret_cast<decltype(host_scifi_tracks)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      sizeof(SciFi::TrackHits)));
    host_scifi_track_hit_number = reinterpret_cast<decltype(host_scifi_track_hit_number)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      sizeof(unsigned)));
    host_scifi_track_hits = reinterpret_cast<decltype(host_scifi_track_hits)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      SciFi::Constants::max_track_size * sizeof(SciFi::Hit)));
    host_scifi_qop = reinterpret_cast<decltype(host_scifi_qop)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      sizeof(float)));
    host_scifi_states = reinterpret_cast<decltype(host_scifi_states)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      sizeof(MiniState)));
    host_scifi_track_ut_indices = reinterpret_cast<decltype(host_scifi_track_ut_indices)>(malloc(
      max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
      sizeof(unsigned)));

    host_reconstructed_pvs = reinterpret_cast<decltype(host_reconstructed_pvs)>(
      malloc(max_number_of_events * PV::max_number_vertices * sizeof(PV::Vertex)));
    host_number_of_vertex =
      reinterpret_cast<decltype(host_number_of_vertex)>(malloc(max_number_of_events * sizeof(int)));
    host_number_of_seeds = reinterpret_cast<decltype(host_number_of_seeds)>(malloc(max_number_of_events * sizeof(int)));
    host_zhisto = reinterpret_cast<decltype(host_zhisto)>(malloc(
      max_number_of_events * sizeof(float) * (BeamlinePVConstants::Common::zmax - BeamlinePVConstants::Common::zmin) /
      BeamlinePVConstants::Common::dz));
    host_peaks =
      reinterpret_cast<decltype(host_peaks)>(malloc(max_number_of_events * sizeof(float) * PV::max_number_vertices));
    host_number_of_peaks =
      reinterpret_cast<decltype(host_number_of_peaks)>(malloc(max_number_of_events * sizeof(unsigned)));

    host_muon_catboost_output = reinterpret_cast<decltype(host_muon_catboost_output)>(
      malloc(max_number_of_events * SciFi::Constants::max_tracks * sizeof(float)));
    host_is_muon = reinterpret_cast<decltype(host_is_muon)>(
      malloc(max_number_of_events * SciFi::Constants::max_tracks * sizeof(bool)));
    host_event_list_mf =
      reinterpret_cast<decltype(host_event_list_mf)>(malloc(max_number_of_events * sizeof(unsigned)));
    host_match_upstream_muon = reinterpret_cast<decltype(host_match_upstream_muon)>(
      malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(bool)));

    host_sv_atomics =
      reinterpret_cast<decltype(host_sv_atomics)>(malloc((2 * max_number_of_events + 1) * sizeof(unsigned)));
  }
}
