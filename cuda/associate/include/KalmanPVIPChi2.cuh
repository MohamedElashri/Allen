#pragma once

// Associate Kalman-fitted long tracks to PVs using IP chi2 and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
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

struct kalman_pv_ipchi2_t : public DeviceAlgorithm {
  constexpr static auto name {"kalman_pv_ipchi2_t"};
  decltype(global_function(kalman_pv_ipchi2)) function {kalman_pv_ipchi2};
  using Arguments = std::tuple<
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
    dev_is_muon>;

  void set_arguments_size(
    ArgumentRefManager<T> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<T>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
