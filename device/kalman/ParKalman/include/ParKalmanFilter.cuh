/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // General method for updating states.
  __device__ void UpdateState(
    const unsigned n_velo_hits,
    const unsigned n_ut_layers,
    const unsigned n_scifi_layers,
    int forward,
    int i_hit,
    Vector5& x,
    SymMatrix5x5& C,
    KalmanFloat& lastz,
    trackInfo& tI);

  //----------------------------------------------------------------------
  // General method for predicting states.
  __device__ void PredictState(
    const Velo::Consolidated::Hits& velo_hits,
    const unsigned n_velo_hits,
    const UT::Consolidated::Hits& ut_hits,
    const unsigned n_ut_layers,
    const SciFi::Consolidated::Hits& scifi_hits,
    const unsigned n_scifi_layers,
    int forward,
    int i_hit,
    Vector5& x,
    SymMatrix5x5& C,
    KalmanFloat& lastz,
    trackInfo& tI);

  //----------------------------------------------------------------------
  // Forward fit iteration.
  __device__ void ForwardFit(
    const Velo::Consolidated::Hits& velo_hits,
    const unsigned n_velo_hits,
    const UT::Consolidated::Hits& ut_hits,
    const unsigned n_ut_layers,
    const SciFi::Consolidated::Hits& scifi_hits,
    const unsigned n_scifi_layers,
    Vector5& x,
    SymMatrix5x5& C,
    KalmanFloat& lastz,
    trackInfo& tI);

  //----------------------------------------------------------------------
  // Backward fit iteration.
  __device__ void BackwardFit(
    const Velo::Consolidated::Hits& velo_hits,
    const unsigned n_velo_hits,
    const UT::Consolidated::Hits& ut_hits,
    const unsigned n_ut_layers,
    const SciFi::Consolidated::Hits& scifi_hits,
    const unsigned n_scifi_layers,
    Vector5& x,
    SymMatrix5x5& C,
    KalmanFloat& lastz,
    trackInfo& tI);

  //----------------------------------------------------------------------
  // Create the output track.
  __device__ void MakeTrack(
    const Velo::Consolidated::Hits& velo_hits,
    const unsigned n_velo_hits,
    const UT::Consolidated::Hits& ut_hits,
    const unsigned n_ut_layers,
    const SciFi::Consolidated::Hits& scifi_hits,
    const unsigned n_scifi_layers,
    const Vector5& x,
    const SymMatrix5x5& C,
    const KalmanFloat& z,
    const trackInfo& tI,
    FittedTrack& track);

  //----------------------------------------------------------------------
  // Run the Kalman filter on a track.
  __device__ FittedTrack fit(
    const Velo::Consolidated::Hits& velo_hits,
    const unsigned n_velo_hits,
    const UT::Consolidated::Hits& ut_hits,
    const unsigned n_ut_hits,
    const SciFi::Consolidated::Hits& scifi_hits,
    const unsigned n_scifi_hits,
    const KalmanFloat init_qop,
    const KalmanParametrizations& kalman_params,
    FittedTrack& track);

} // namespace ParKalmanFilter

namespace kalman_filter {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_atomics_velo_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_track_hits_t, char), dev_velo_track_hits),
    (DEVICE_INPUT(dev_atomics_ut_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_ut_track_hit_number_t, unsigned), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_ut_track_hits_t, char), dev_ut_track_hits),
    (DEVICE_INPUT(dev_ut_qop_t, float), dev_ut_qop),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned), dev_ut_track_velo_indices),
    (DEVICE_INPUT(dev_atomics_scifi_t, unsigned), dev_atomics_scifi),
    (DEVICE_INPUT(dev_scifi_track_hit_number_t, unsigned), dev_scifi_track_hit_number),
    (DEVICE_INPUT(dev_scifi_track_hits_t, char), dev_scifi_track_hits),
    (DEVICE_INPUT(dev_scifi_qop_t, float), dev_scifi_qop),
    (DEVICE_INPUT(dev_scifi_states_t, MiniState), dev_scifi_states),
    (DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned), dev_scifi_track_ut_indices),
    (DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  //--------------------------------------------------
  // Main execution of the parametrized Kalman Filter.
  //--------------------------------------------------
  __global__ void kalman_filter(
    Parameters,
    const char* dev_scifi_geometry,
    const float* dev_inv_clus_res,
    const ParKalmanFilter::KalmanParametrizations* dev_kalman_params);

  struct kalman_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace kalman_filter