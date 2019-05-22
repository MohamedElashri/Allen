#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "PV_Definitions.cuh"
#include "SciFiConsolidated.cuh"
#include "AssociateConsolidated.cuh"

#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsVertex.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSelections.cuh"

namespace VertexFit {

  __device__ bool poca(
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB,
    float& x,
    float& y,
    float& z);

  __device__ float addToDerivatives(
    const ParKalmanFilter::FittedTrack& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22);

  __device__ float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22);

  __device__ bool doFit(
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB,
    Vertex& vertex);

  __device__ void fill_extra_info(
    Vertex& sv,
    const PV::Vertex& pv,
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB);
}

__global__ void fit_secondary_vertices(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  int* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  char* dev_scifi_consolidated_hits,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  char* dev_kalman_pv_ipchi2,
  uint* dev_sv_offsets,
  VertexFit::Vertex* dev_secondary_vertices);

ALGORITHM(
  fit_secondary_vertices,
  fit_secondary_vertices_t,
  ARGUMENTS(
    dev_kf_tracks,
    dev_atomics_scifi,
    dev_scifi_track_hit_number,
    dev_scifi_track_hits,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_multi_fit_vertices,
    dev_number_of_multi_fit_vertices,
    dev_kalman_pv_ipchi2,
    dev_sv_offsets,
    dev_secondary_vertices))
