/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
#include "PackageKalmanTracks.cuh"
#include "PV_Definitions.cuh"
#include "ParticleTypes.cuh"

typedef Vector<10> Vector10;
typedef Vector<2> Vector2;
typedef SquareMatrix<true, 2> SymMatrix2x2;
typedef SquareMatrix<false, 2> Matrix2x2;

static constexpr float pixelErr = 0.0125f;

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

__device__ void simplified_fit(
  const Allen::Views::Velo::Consolidated::Track& velo_track,
  const KalmanFloat init_qop,
  FittedTrack& track);

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
    DEVICE_OUTPUT(dev_kalman_pv_ip_t, char) dev_kalman_pv_ip;
    DEVICE_OUTPUT(dev_kalman_fit_results_t, char) dev_kalman_fit_results;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_kalman_states_view_t,
      DEPENDENCIES(dev_kalman_fit_results_t),
      Allen::Views::Physics::KalmanStates)
    dev_kalman_states_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_kalman_pv_tables_t,
      DEPENDENCIES(dev_kalman_pv_ip_t),
      Allen::Views::Physics::PVTable)
    dev_kalman_pv_tables;
  };

  __global__ void kalman_velo_only(Parameters parameters);

  __global__ void kalman_pv_ip(Parameters parameters);

  struct kalman_velo_only_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace kalman_velo_only
