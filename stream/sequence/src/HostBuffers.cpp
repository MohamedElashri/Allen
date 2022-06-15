/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostBuffers.cuh"
#include "BackendCommon.h"
#include "VeloEventModel.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "PV_Definitions.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "VertexDefinitions.cuh"
#include "BeamlinePVConstants.cuh"
#include "LookingForwardConstants.cuh"
#include "CheckerTracks.cuh"

void HostBuffers::reserve(const unsigned max_number_of_events, const size_t n_lines)
{
  // Datatypes needed to run, regardless of checking
  // Note: These datatypes must be pinned to allow for asynchronicity
  Allen::malloc_host((void**) &host_number_of_events, sizeof(unsigned));
  Allen::malloc_host((void**) &host_total_number_of_velo_clusters, sizeof(unsigned));
  Allen::malloc_host((void**) &host_number_of_reconstructed_velo_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_accumulated_number_of_hits_in_velo_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_accumulated_number_of_ut_hits, sizeof(unsigned));
  Allen::malloc_host((void**) &host_number_of_reconstructed_ut_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_accumulated_number_of_hits_in_ut_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_accumulated_number_of_scifi_hits, sizeof(unsigned));
  Allen::malloc_host((void**) &host_number_of_reconstructed_scifi_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_accumulated_number_of_hits_in_scifi_tracks, sizeof(unsigned));
  Allen::malloc_host((void**) &host_lf_total_number_of_candidates, sizeof(unsigned));
  Allen::malloc_host((void**) &host_lf_total_size_first_window_layer, sizeof(unsigned));
  Allen::malloc_host((void**) &host_muon_total_number_of_tiles, sizeof(unsigned));
  Allen::malloc_host((void**) &host_number_of_svs, sizeof(unsigned));
  Allen::malloc_host((void**) &host_muon_total_number_of_hits, sizeof(unsigned));
  Allen::malloc_host((void**) &host_number_of_sel_rep_words, sizeof(unsigned));

  // Initialize for sequences that don't fill this in.
  host_number_of_events = 0;

  // Buffer for saving dec reports to the host.
  uint32_t* dec_reports = nullptr;
  size_t const dec_reports_size = max_number_of_events * (n_lines + 2);
  size_t const dec_reports_size_bytes = dec_reports_size * sizeof(uint32_t);
  Allen::malloc_host((void**) &dec_reports, dec_reports_size_bytes);
  ::memset(dec_reports, 0, dec_reports_size_bytes);
  host_dec_reports = {dec_reports, dec_reports_size};

  // Buffer for saving sel reports to the host.
  uint32_t* sel_reports = nullptr;
  // SelReports for events selected by the passthrough line have a
  // size of 20. SelReports for almost all events selected by physics
  // lines have a size of 100-200 with almost all <300. So 300 is
  // chosen as a reasonable safe value for the maximum average
  // SelReport size for all events.
  size_t const max_average_sel_report_size = 300;
  size_t const sel_reports_size = max_number_of_events * max_average_sel_report_size;
  size_t const sel_reports_size_bytes = sel_reports_size * sizeof(uint32_t);
  Allen::malloc_host((void**) &sel_reports, sel_reports_size_bytes);
  ::memset(sel_reports, 0, sel_reports_size_bytes);
  host_sel_reports = {sel_reports, sel_reports_size};

  uint32_t* sel_report_offsets = nullptr;
  Allen::malloc_host((void**) &sel_report_offsets, (max_number_of_events + 1) * sizeof(uint32_t));
  ::memset(sel_report_offsets, 0, (max_number_of_events + 1) * sizeof(uint32_t));
  host_sel_report_offsets = {sel_report_offsets, (max_number_of_events + 1)};

  // Buffer for saving events passing Hlt1 selections.
  bool* passing_event_list = nullptr;
  Allen::malloc_host((void**) &passing_event_list, max_number_of_events * sizeof(bool));
  ::memset(passing_event_list, 0, max_number_of_events * sizeof(bool));
  host_passing_event_list = {passing_event_list, max_number_of_events};

  // Buffer for performing prefix sum
  // Note: If it is of insufficient space, it will get reallocated
  host_allocated_prefix_sum_space = 10000000;
  Allen::malloc_host((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(unsigned));

  // Needed for track monitoring
  uint32_t* atomics_scifi = nullptr;
  size_t const atomics_scifi_size = max_number_of_events * SciFi::num_atomics;
  size_t const atomics_scifi_size_bytes = atomics_scifi_size * sizeof(uint32_t);
  Allen::malloc_host((void**) &atomics_scifi, atomics_scifi_size_bytes);
  ::memset(atomics_scifi, 0, atomics_scifi_size_bytes);
  host_atomics_scifi = {atomics_scifi, atomics_scifi_size};

  ParKalmanFilter::FittedTrack* kf_tracks = nullptr;
  size_t const kf_tracks_size = max_number_of_events * SciFi::Constants::max_tracks;
  size_t const kf_tracks_size_bytes = kf_tracks_size * sizeof(ParKalmanFilter::FittedTrack);
  Allen::malloc_host((void**) &kf_tracks, kf_tracks_size_bytes);
  ::memset((void*) kf_tracks, 0, kf_tracks_size_bytes);
  host_kf_tracks = {kf_tracks, kf_tracks_size};

  // Needed for PV monitoring
  PV::Vertex* reconstructed_multi_pvs = nullptr;
  size_t const reconstructed_multi_pvs_size = max_number_of_events * PV::max_number_vertices;
  size_t const reconstructed_multi_pvs_size_bytes = reconstructed_multi_pvs_size * sizeof(PV::Vertex);
  Allen::malloc_host((void**) &reconstructed_multi_pvs, reconstructed_multi_pvs_size_bytes);
  ::memset((void*) reconstructed_multi_pvs, 0, reconstructed_multi_pvs_size_bytes);
  host_reconstructed_multi_pvs = {reconstructed_multi_pvs, reconstructed_multi_pvs_size};

  uint32_t* number_of_multivertex = nullptr;
  size_t const number_of_multivertex_size = max_number_of_events;
  size_t const number_of_multivertex_size_bytes = number_of_multivertex_size * sizeof(uint32_t);
  Allen::malloc_host((void**) &number_of_multivertex, number_of_multivertex_size_bytes);
  ::memset(number_of_multivertex, 0, number_of_multivertex_size_bytes);
  host_number_of_multivertex = {number_of_multivertex, number_of_multivertex_size};

  // Datatypes to be reserved only if checking is on
  // Note: These datatypes in principle do not require to be pinned
  host_ut_tracks = reinterpret_cast<decltype(host_ut_tracks)>(
    malloc(max_number_of_events * UT::Constants::max_num_tracks * sizeof(UT::TrackHits)));

  host_long_checker_tracks = reinterpret_cast<decltype(host_long_checker_tracks)>(malloc(
    max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
    sizeof(Checker::Track)));
  host_kalman_checker_tracks = reinterpret_cast<decltype(host_kalman_checker_tracks)>(malloc(
    max_number_of_events * UT::Constants::max_num_tracks * LookingForward::maximum_number_of_candidates_per_ut_track *
    sizeof(Checker::Track)));

  host_reconstructed_pvs = reinterpret_cast<decltype(host_reconstructed_pvs)>(
    malloc(max_number_of_events * PV::max_number_vertices * sizeof(PV::Vertex)));
  host_number_of_vertex = reinterpret_cast<decltype(host_number_of_vertex)>(malloc(max_number_of_events * sizeof(int)));
  host_number_of_seeds = reinterpret_cast<decltype(host_number_of_seeds)>(malloc(max_number_of_events * sizeof(int)));
  host_zhisto = reinterpret_cast<decltype(host_zhisto)>(malloc(
    max_number_of_events * sizeof(float) * (BeamlinePVConstants::Common::zmax - BeamlinePVConstants::Common::zmin) /
    BeamlinePVConstants::Common::dz));
  host_peaks =
    reinterpret_cast<decltype(host_peaks)>(malloc(max_number_of_events * sizeof(float) * PV::max_number_vertices));
  host_number_of_peaks =
    reinterpret_cast<decltype(host_number_of_peaks)>(malloc(max_number_of_events * sizeof(unsigned)));

  host_event_list_mf = reinterpret_cast<decltype(host_event_list_mf)>(malloc(max_number_of_events * sizeof(unsigned)));
}
