/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <gsl/gsl>

#include <CaloDigit.cuh>
#include <CaloCluster.cuh>

#include <BackendCommon.h>

// Forward declarations
namespace PV {
  class Vertex;
}
namespace UT {
  struct TrackHits;
}
namespace SciFi {
  struct TrackHits;
} // namespace SciFi
struct MiniState;
namespace ParKalmanFilter {
  struct FittedTrack;
}
namespace VertexFit {
  struct TrackMVAVertex;
}
namespace Checker {
  struct Track;
}

struct HostBuffers {
private:
  // Use a custom memory manager for the host pinned memory used here

public:
  // Pinned host datatypes
  unsigned host_number_of_events;
  unsigned host_number_of_selected_events;
  unsigned* host_prefix_sum_buffer;
  gsl::span<bool> host_passing_event_list;
  uint32_t* host_sel_rep_raw_banks;
  unsigned host_sel_rep_raw_banks_size;
  size_t host_allocated_prefix_sum_space;
  unsigned* host_sel_rep_offsets;
  unsigned* host_number_of_sel_rep_words;

  // Velo
  unsigned* host_total_number_of_velo_clusters;
  unsigned* host_number_of_reconstructed_velo_tracks;
  unsigned* host_accumulated_number_of_hits_in_velo_tracks;
  PV::Vertex* host_reconstructed_pvs;
  int* host_number_of_vertex;
  int* host_number_of_seeds;
  unsigned* host_n_scifi_tracks;
  float* host_zhisto;
  float* host_peaks;
  unsigned* host_number_of_peaks;
  gsl::span<PV::Vertex> host_reconstructed_multi_pvs;
  gsl::span<uint32_t> host_number_of_multivertex = {};

  // UT
  UT::TrackHits* host_ut_tracks;
  unsigned* host_number_of_reconstructed_ut_tracks;
  unsigned* host_accumulated_number_of_ut_hits;
  unsigned* host_accumulated_number_of_hits_in_ut_tracks;

  // SciFi
  unsigned* host_accumulated_number_of_scifi_hits;
  unsigned* host_number_of_reconstructed_scifi_tracks;
  gsl::span<uint32_t> host_atomics_scifi = {};
  unsigned* host_accumulated_number_of_hits_in_scifi_tracks;
  unsigned* host_lf_total_size_first_window_layer;
  unsigned* host_lf_total_number_of_candidates;
  Checker::Track* host_long_checker_tracks;
  Checker::Track* host_kalman_checker_tracks;

  // Kalman
  gsl::span<ParKalmanFilter::FittedTrack> host_kf_tracks = {};

  // Muon
  unsigned* host_muon_total_number_of_tiles;
  unsigned* host_muon_total_number_of_hits;
  unsigned* host_event_list_mf;

  // Secondary vertices
  unsigned* host_number_of_svs;
  unsigned* host_mf_sv_offsets;

  unsigned host_mf_secondary_vertices_size;
  VertexFit::TrackMVAVertex* host_mf_secondary_vertices;

  // Selections
  std::string host_names_of_lines;
  unsigned host_number_of_lines;
  gsl::span<uint32_t> host_dec_reports = {};
  gsl::span<unsigned> host_sel_reports = {};
  gsl::span<unsigned> host_sel_report_offsets;

  // Non pinned datatypes: CPU algorithms
  std::vector<char> host_velo_states;
  std::vector<std::vector<std::vector<uint32_t>>> scifi_ids_ut_tracks;
  std::vector<unsigned> host_scifi_hits;
  std::vector<unsigned> host_scifi_hit_count;

  /**
   * @brief Reserves all host buffers.
   */
  void reserve(const unsigned max_number_of_events, const size_t n_lines);

  /**
   * @brief Returns total number of velo track hits.
   */
  size_t velo_track_hit_number_size() const;

  /**
   * @brief Returns total number of UT track hits.
   */
  size_t ut_track_hit_number_size() const;

  /**
   * @brief Returns total number of SciFi track hits.
   */
  size_t scifi_track_hit_number_size() const;

  /**
   * @brief Retrieve total number of hit uints.
   */
  uint32_t scifi_hits_uints() const;
};
