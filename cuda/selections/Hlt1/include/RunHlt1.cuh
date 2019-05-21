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

  void (*line) (const T& candidate, bool& decision);

  __device__ LineHandler(
    void (*m_line) (const T& candidate, bool& decision));

  __device__ void operator()(
    const T* candidates,
    const int n_candidates,
    bool* results);
  
};

template<typename T>
__device__ LineHandler<T>::LineHandler(
  void (*m_line) (const T& candidate, bool& decision))
{
  line = m_line;
}

template<typename T>
__device__ void LineHandler<T>::operator()(
  const T* candidates,
  const int n_candidates,
  bool* results)
{
  for (int i_cand = threadIdx.x; i_cand < n_candidates; i_cand += blockDim.x) {
    line(candidates[i_cand], results[i_cand]);
  }
}                                           

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::Vertex* dev_secondary_vertices,
  const int* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results);

ALGORITHM(
  run_hlt1,
  run_hlt1_t,
  ARGUMENTS(
    dev_kf_tracks,
    dev_secondary_vertices,
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results))
