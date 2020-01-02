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
  const VertexFit::TrackMVAVertex* dev_consolidated_svs,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  bool* dev_sel_results,
  uint* dev_sel_results_atomics);

ALGORITHM(
  run_hlt1,
  run_hlt1_t,
  ARGUMENTS(
    dev_kf_tracks,
    dev_consolidated_svs,
    dev_atomics_scifi,
    dev_sv_atomics,
    dev_sel_results,
    dev_sel_results_atomics))
