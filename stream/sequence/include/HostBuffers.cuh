#pragma once

#include <vector>
#include <cstdint>
#include <cstdlib>

// Forward declarations
namespace PV {
  class Vertex;
}
namespace UT {
  class TrackHits;
}
namespace SciFi {
  class TrackHits;
}
class MiniState;
namespace ParKalmanFilter {
  class FittedTrack;
}
namespace VertexFit {
  class TrackMVAVertex;
}

struct HostBuffers {
  // Pinned host datatypes
  uint* host_number_of_selected_events;
  uint* host_event_list;
  uint* host_prefix_sum_buffer;
  uint* host_number_of_passing_events;
  uint* host_passing_event_list;
  uint32_t* host_dec_reports;
  uint32_t* host_sel_rep_raw_banks;
  size_t host_allocated_prefix_sum_space;
  uint* host_sel_rep_offsets;
  uint* host_number_of_sel_rep_words;
  
  // Velo
  uint* host_atomics_velo;
  uint* host_velo_track_hit_number;
  char* host_velo_track_hits;
  uint* host_total_number_of_velo_clusters;
  uint* host_number_of_reconstructed_velo_tracks;
  uint* host_accumulated_number_of_hits_in_velo_tracks;
  char* host_kalmanvelo_states;
  PV::Vertex* host_reconstructed_pvs;
  int* host_number_of_vertex;
  int* host_number_of_seeds;
  uint* host_n_scifi_tracks;
  float* host_zhisto;
  float* host_peaks;
  uint* host_number_of_peaks;
  PV::Vertex* host_reconstructed_multi_pvs;
  int* host_number_of_multivertex;

  // UT
  uint* host_atomics_ut;
  UT::TrackHits* host_ut_tracks;
  uint* host_number_of_reconstructed_ut_tracks;
  uint* host_accumulated_number_of_ut_hits;
  uint* host_accumulated_number_of_hits_in_ut_tracks;
  uint* host_ut_track_hit_number;
  char* host_ut_track_hits;
  float* host_ut_qop;
  float* host_ut_x;
  float* host_ut_tx;
  float* host_ut_z;
  uint* host_ut_track_velo_indices;

  // SciFi
  uint* host_accumulated_number_of_scifi_hits;
  uint* host_number_of_reconstructed_scifi_tracks;
  SciFi::TrackHits* host_scifi_tracks;
  uint* host_atomics_scifi;
  uint* host_accumulated_number_of_hits_in_scifi_tracks;
  uint* host_scifi_track_hit_number;
  char* host_scifi_track_hits;
  float* host_scifi_qop;
  MiniState* host_scifi_states;
  uint* host_scifi_track_ut_indices;
  uint* host_lf_total_size_first_window_layer;
  uint* host_lf_total_number_of_candidates;

  // Kalman
  ParKalmanFilter::FittedTrack* host_kf_tracks;

  // Muon
  float* host_muon_catboost_output;
  bool* host_is_muon;
  uint* host_muon_total_number_of_tiles;
  uint* host_muon_total_number_of_hits;
  uint* host_selected_events_mf;
  uint* host_event_list_mf;
  bool* host_match_upstream_muon;
  
  // Secondary vertices
  uint* host_number_of_svs;
  uint* host_sv_offsets;
  uint* host_sv_atomics;
  VertexFit::TrackMVAVertex* host_secondary_vertices;

  // Selections
  uint* host_sel_results_atomics;
  bool* host_sel_results;

  // Non pinned datatypes: CPU algorithms
  std::vector<char> host_velo_states;
  std::vector<std::vector<std::vector<uint32_t>>> scifi_ids_ut_tracks;
  std::vector<uint> host_scifi_hits;
  std::vector<uint> host_scifi_hit_count;

  /**
   * @brief Reserves all host buffers.
   */
  void reserve(const uint max_number_of_events, const bool do_check, const uint number_of_hlt1_lines);

  // /**
  //  * @brief Frees all host buffers.
  //  */
  // cudaError_t free(const bool do_check);

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
