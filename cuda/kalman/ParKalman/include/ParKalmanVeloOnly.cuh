#pragma once

#include "KalmanParametrizations.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanMethods.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "States.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "PackageKalman.cuh"
#include "PV_Definitions.cuh"

typedef Vector<10> Vector10;
typedef Vector<2> Vector2;
typedef SquareMatrix<true, 2> SymMatrix2x2;
typedef SquareMatrix<false, 2> Matrix2x2;

static constexpr float scatterSensorParameters[4] = {0.54772, 1.478845, 0.626634, -0.78};
static constexpr float scatterFoilParameters[2] = {1.67, 20.};
static constexpr float pixelErr = 0.0125;

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
  float& chi2);

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
  FittedTrack& track);

__device__ void propagate_to_beamline(FittedTrack& track);

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
    DEVICE_INPUT(dev_velo_pv_ip_t, char) dev_velo_pv_ip;
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_OUTPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void kalman_velo_only(Parameters, const char* dev_scifi_geometry);
  __global__ void kalman_pv_ipchi2(Parameters parameters);
  
  template<typename T, char... S>
  struct kalman_velo_only_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(kalman_velo_only)) kalman_function {kalman_velo_only};
    decltype(global_function(kalman_pv_ipchi2)) assoc_function {kalman_pv_ipchi2};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      auto n_scifi_tracks = value<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      set_size<dev_kf_tracks_t>(arguments, n_scifi_tracks);
      set_size<dev_kalman_pv_ipchi2_t>(arguments, Associate::Consolidated::table_size(n_scifi_tracks));

    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      kalman_function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
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
                    begin<dev_velo_pv_ip_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments),
                    begin<dev_multi_fit_vertices_t>(arguments),
                    begin<dev_number_of_multi_fit_vertices_t>(arguments),
                    begin<dev_kalman_pv_ipchi2_t>(arguments),
                    begin<dev_is_muon_t>(arguments)},
        constants.dev_scifi_geometry);
      
      assoc_function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
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
                    begin<dev_velo_pv_ip_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments),
                    begin<dev_multi_fit_vertices_t>(arguments),
                    begin<dev_number_of_multi_fit_vertices_t>(arguments),
                    begin<dev_kalman_pv_ipchi2_t>(arguments),
                    begin<dev_is_muon_t>(arguments)});

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_kf_tracks,
        begin<dev_kf_tracks_t>(arguments),
        size<dev_kf_tracks_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace kalman_velo_only