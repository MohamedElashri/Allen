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
#include "AssociateConsolidated.cuh"
#include "States.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "PackageKalman.cuh"
#include "PV_Definitions.cuh"
#include "ParticleTypes.cuh"

typedef Vector<10> Vector10;
typedef Vector<2> Vector2;
typedef SquareMatrix<true, 2> SymMatrix2x2;
typedef SquareMatrix<false, 2> Matrix2x2;

static constexpr float pixelErr = 0.0125f;

static constexpr float scatterSensorParameter_VPHit2VPHit_cms = 1.48;
static constexpr float scatterSensorParameter_VPHit2VPHit_etaxx = 0.643;
static constexpr float scatterSensorParameter_VPHit2VPHit_etaxtx = 0.526;
static constexpr float scatterSensorParameter_VPHit2VPHit_Eloss = 0.592;

static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_cms = 2.91;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_etaxx = 0.808;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_etaxtx = 0.793;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_Eloss = 1.29;

static constexpr float rffoilscatter = 0.6;

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
  const unsigned n_velo_hits,
  const KalmanFloat init_qop,
  const KalmanParametrizations* kalman_params,
  FittedTrack& track);

__device__ void simplified_fit(
  const Allen::Views::Velo::Consolidated::Track& velo_track,
  const KalmanFloat init_qop,
  FittedTrack& track);

__device__ void propagate_to_beamline(FittedTrack& track);

namespace kalman_velo_only {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_OUTPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_OUTPUT(dev_kalman_fit_results_t, char) dev_kalman_fit_results;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_kalman_states_view_t,
      DEPENDENCIES(dev_kalman_fit_results_t),
      Allen::Views::Physics::KalmanStates)
    dev_kalman_states_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_kalman_pv_tables_t,
      DEPENDENCIES(dev_kalman_pv_ipchi2_t),
      Allen::Views::Physics::PVTable)
    dev_kalman_pv_tables;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void kalman_velo_only(Parameters parameters);

  __global__ void kalman_pv_ipchi2(Parameters parameters);

  struct kalman_velo_only_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace kalman_velo_only
