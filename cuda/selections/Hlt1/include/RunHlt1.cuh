#pragma once

#include "TrackMVALines.cuh"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"

#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

template<typename T>
struct LineHandler {

  bool (*m_line)(const T& candidate);

  __device__ LineHandler(bool (*line)(const T& candidate));

  __device__ void operator()(const T* candidates, const int n_candidates, bool* results);
};

template<typename T>
__device__ LineHandler<T>::LineHandler(bool (*line)(const T& candidate))
{
  m_line = line;
}

template<typename T>
__device__ void LineHandler<T>::operator()(const T* candidates, const int n_candidates, bool* results)
{
  for (int i_cand = threadIdx.x; i_cand < n_candidates; i_cand += blockDim.x) {
    results[i_cand] = m_line(candidates[i_cand]);
  }
}

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_secondary_vertices,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results,
  bool* dev_single_muon_results,
  bool* dev_disp_dimuon_results,
  bool* dev_high_mass_dimuon_results);

ALGORITHM(
  run_hlt1,
  run_hlt1_t,
  ARGUMENTS(
    dev_kf_tracks,
    dev_secondary_vertices,
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results))
