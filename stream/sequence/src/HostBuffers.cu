#include "HostBuffers.cuh"
#include "SciFiDefinitions.cuh"
#include "BeamlinePVConstants.cuh"

void HostBuffers::reserve(const uint max_number_of_events, const bool do_check)
{
  // Datatypes needed to run, regardless of checking
  // Note: These datatypes must be pinned to allow for asynchronicity
  cudaCheck(cudaMallocHost((void**) &host_number_of_selected_events, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_total_number_of_velo_clusters, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_velo_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_velo_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_ut_hits, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_ut_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_ut_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_scifi_hits, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_reconstructed_scifi_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_accumulated_number_of_hits_in_scifi_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_lf_total_number_of_candidates, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_lf_total_size_first_window_layer, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**) &host_number_of_svs, sizeof(uint)));

  // Buffer for performing GEC on CPU
  cudaCheck(cudaMallocHost((void**) &host_event_list, max_number_of_events * sizeof(uint)));

  // Buffer for performing prefix sum
  // Note: If it is of insufficient space, it will get reallocated
  host_allocated_prefix_sum_space = 10000000;
  cudaCheck(cudaMallocHost((void**) &host_prefix_sum_buffer, host_allocated_prefix_sum_space * sizeof(uint)));

  if (do_check) {
    // Datatypes to be reserved only if checking is on
    // Note: These datatypes in principle do not require to be pinned
    cudaCheck(cudaMallocHost((void**) &host_atomics_velo, (2 * max_number_of_events + 1) * sizeof(int)));
    cudaCheck(cudaMallocHost(
      (void**) &host_velo_track_hit_number, max_number_of_events * Velo::Constants::max_tracks * sizeof(uint)));
    cudaCheck(cudaMallocHost(
      (void**) &host_velo_track_hits,
      max_number_of_events * Velo::Constants::max_tracks * Velo::Constants::max_track_size * sizeof(Velo::Hit)));
    cudaCheck(cudaMallocHost(
      (void**) &host_kalmanvelo_states, max_number_of_events * Velo::Constants::max_tracks * sizeof(VeloState)));

    cudaCheck(cudaMallocHost((void**) &host_atomics_ut, UT::num_atomics * max_number_of_events * sizeof(int)));
    cudaCheck(cudaMallocHost(
      (void**) &host_ut_tracks, max_number_of_events * UT::Constants::max_num_tracks * sizeof(UT::TrackHits)));

    cudaCheck(cudaMallocHost(
      (void**) &host_ut_track_hit_number, max_number_of_events * UT::Constants::max_num_tracks * sizeof(uint)));
    cudaCheck(cudaMallocHost(
      (void**) &host_ut_track_hits,
      max_number_of_events * UT::Constants::max_num_tracks * UT::Constants::max_track_size * sizeof(UT::Hit)));
    cudaCheck(
      cudaMallocHost((void**) &host_ut_qop, max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost((void**) &host_ut_x, max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost((void**) &host_ut_tx, max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost((void**) &host_ut_z, max_number_of_events * UT::Constants::max_num_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost(
      (void**) &host_ut_track_velo_indices, max_number_of_events * UT::Constants::max_num_tracks * sizeof(int)));

    cudaCheck(cudaMallocHost(
      (void**) &host_scifi_tracks, max_number_of_events * UT::Constants::max_num_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track * sizeof(SciFi::TrackHits)));
    cudaCheck(cudaMallocHost((void**) &host_atomics_scifi, max_number_of_events * SciFi::num_atomics * sizeof(int)));

    cudaCheck(cudaMallocHost(
      (void**) &host_scifi_track_hit_number, max_number_of_events * SciFi::Constants::max_tracks * sizeof(uint)));
    cudaCheck(cudaMallocHost(
      (void**) &host_scifi_track_hits,
      max_number_of_events * SciFi::Constants::max_tracks * SciFi::Constants::max_track_size * sizeof(SciFi::Hit)));
    cudaCheck(
      cudaMallocHost((void**) &host_scifi_qop, max_number_of_events * SciFi::Constants::max_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost(
      (void**) &host_scifi_states, max_number_of_events * SciFi::Constants::max_tracks * sizeof(MiniState)));
    cudaCheck(cudaMallocHost(
      (void**) &host_scifi_track_ut_indices, max_number_of_events * SciFi::Constants::max_tracks * sizeof(uint)));

    cudaCheck(cudaMallocHost(
      (void**) &host_reconstructed_pvs, max_number_of_events * PV::max_number_vertices * sizeof(PV::Vertex)));
    cudaCheck(cudaMallocHost((void**) &host_number_of_vertex, max_number_of_events * sizeof(int)));
    cudaCheck(cudaMallocHost((void**) &host_number_of_seeds, max_number_of_events * sizeof(int)));
    cudaCheck(cudaMallocHost((void**) &host_zhisto, max_number_of_events * sizeof(float) * (zmax - zmin) / dz));

    cudaCheck(cudaMallocHost((void**) &host_peaks, max_number_of_events * sizeof(float) * PV::max_number_vertices));
    cudaCheck(cudaMallocHost((void**) &host_number_of_peaks, max_number_of_events * sizeof(uint)));

    cudaCheck(cudaMallocHost(
      (void**) &host_reconstructed_multi_pvs, max_number_of_events * PV::max_number_vertices * sizeof(PV::Vertex)));
    cudaCheck(cudaMallocHost((void**) &host_number_of_multivertex, max_number_of_events * sizeof(int)));

    cudaCheck(cudaMallocHost(
      (void**) &host_kf_tracks,
      max_number_of_events * SciFi::Constants::max_tracks * sizeof(ParKalmanFilter::FittedTrack)));
    cudaCheck(cudaMallocHost((void**)&host_muon_catboost_output, max_number_of_events * SciFi::Constants::max_tracks * sizeof(float)));
    cudaCheck(cudaMallocHost((void**)&host_is_muon, max_number_of_events * SciFi::Constants::max_tracks * sizeof(bool)));

    cudaCheck(cudaMallocHost(
      (void**) &host_one_track_decisions,
      max_number_of_events * SciFi::Constants::max_tracks * sizeof(bool)));
    // For some reason this is being exceeded? This seems like a bug.
    //int n_max_svs = SciFi::Constants::max_tracks * (SciFi::Constants::max_tracks - 1) / 2;
    int n_max_svs = SciFi::Constants::max_tracks * SciFi::Constants::max_tracks;
    cudaCheck(cudaMallocHost(
      (void**) &host_sv_offsets,
      (max_number_of_events + 1) * sizeof(uint)));
    cudaCheck(cudaMallocHost(
      (void**) &host_two_track_decisions,
      max_number_of_events * n_max_svs * sizeof(bool)));
    cudaCheck(cudaMallocHost(
      (void**) & host_secondary_vertices,
      n_max_svs * sizeof(VertexFit::Vertex)));
  }
}

size_t HostBuffers::velo_track_hit_number_size() const { return host_number_of_reconstructed_velo_tracks[0] + 1; }

size_t HostBuffers::ut_track_hit_number_size() const { return host_number_of_reconstructed_ut_tracks[0] + 1; }

size_t HostBuffers::scifi_track_hit_number_size() const { return host_number_of_reconstructed_scifi_tracks[0] + 1; }

uint32_t HostBuffers::scifi_hits_uints() const
{
  return (sizeof(SciFi::Hit) / sizeof(uint32_t) + 1) * host_accumulated_number_of_scifi_hits[0];
}
