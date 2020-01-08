#pragma once

#include "KalmanParametrizations.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanMethods.cuh"

#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"

#include "States.cuh"
#include "SciFiDefinitions.cuh"

#include "DeviceAlgorithm.cuh"
#include "ArgumentsMuon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"

typedef Vector<10> Vector10;
typedef Vector<2> Vector2;
typedef SquareMatrix<true, 2> SymMatrix2x2;
typedef SquareMatrix<false, 2> Matrix2x2;

__device__ void simplified_step(
  const float z,
  const float zhit,
  const float xhit,
  const float winv,
  float& x,
  float& tx,
  float& qop,
  float& covXX,
  float& covXTx,
  float& covTxTx,
  float& chi2,
  const ParKalmanFilter::KalmanParametrizations* params);

__device__ void extrapolate_velo_only(
  KalmanFloat zFrom,
  KalmanFloat zTo,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  const ParKalmanFilter::KalmanParametrizations* params);

__device__ void predict_velo_only(
  const Velo::Consolidated::Hits& hits,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  const ParKalmanFilter::KalmanParametrizations* params);

__device__ void
update_velo_only(const Velo::Consolidated::Hits& hits, int nHit, Vector5& x, SymMatrix5x5& C, KalmanFloat& chi2);

__device__ void velo_only_fit(
  const Velo::Consolidated::Hits& velo_hits,
  const uint n_velo_hits,
  const KalmanFloat init_qop,
  const KalmanParametrizations* kalman_params,
  FittedTrack& track);

__device__ void simplified_fit(
  const Velo::Consolidated::Hits& velo_hits,
  const uint n_velo_hits,
  const KalmanFloat init_qop,
  const KalmanParametrizations* kalman_params,
  FittedTrack& track);

__global__ void kalman_velo_only(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  char* dev_velo_track_hits,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  uint* dev_velo_indices,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const char* dev_scifi_geometry,
  const ParKalmanFilter::KalmanParametrizations* dev_kalman_params);

__global__ void package_kalman_tracks(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  uint* dev_velo_indices,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  char* dev_velo_kalman_beamline_states,
  bool* dev_is_muon,
  ParKalmanFilter::FittedTrack* dev_kf_tracks);

struct kalman_velo_only_t : public DeviceAlgorithm {
  constexpr static auto name {"kalman_velo_only_t"};
  decltype(global_function(kalman_velo_only)) function {kalman_velo_only};
  using Arguments = std::tuple<
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_track_hits,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_atomics_scifi,
    dev_scifi_track_hit_number,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_kf_tracks>;

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

struct package_kalman_tracks_t : public DeviceAlgorithm {
  constexpr static auto name {"package_kalman_tracks_t"};
  decltype(global_function(package_kalman_tracks)) function {package_kalman_tracks};
  using Arguments = std::tuple<
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_atomics_scifi,
    dev_scifi_track_hit_number,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_velo_kalman_beamline_states,
    dev_is_muon,
    dev_kf_tracks>;

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
