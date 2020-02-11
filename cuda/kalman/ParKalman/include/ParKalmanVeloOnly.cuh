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
#include "PackageKalman.cuh"

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

namespace kalman_velo_only {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void kalman_velo_only(
    Parameters,
    const char* dev_scifi_geometry,
    const ParKalmanFilter::KalmanParametrizations* dev_kalman_params);

  template<typename T, char... S>
  struct kalman_velo_only_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(kalman_velo_only)) function {kalman_velo_only};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_kf_tracks_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_track_hits_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_ut_qop_t>(arguments),
                    begin<dev_ut_track_velo_indices_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments)},
        constants.dev_scifi_geometry,
        constants.dev_kalman_params);
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace kalman_velo_only