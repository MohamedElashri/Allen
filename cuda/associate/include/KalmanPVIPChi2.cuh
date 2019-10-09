#pragma once

// Associate Kalman-fitted long tracks to PVs using IP chi2 and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsMuon.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "States.cuh"

__global__ void kalman_pv_ipchi2(
  ParKalmanFilter::FittedTrack* dev_kf_tracks,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  char* dev_kalman_pv_ipchi2,
  const bool* dev_is_muon);

ALGORITHM(
  kalman_pv_ipchi2,
  kalman_pv_ipchi2_t,
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
    dev_is_muon))
