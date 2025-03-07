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
#include "ParKalmanFittedTrack.cuh"

#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"

#include "States.cuh"
#include "SciFiDefinitions.cuh"

#include "AlgorithmTypes.cuh"
#include "PV_Definitions.cuh"
#include "ParticleTypes.cuh"

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // Create the output track.
  __device__ void MakeTrack(
    const KalmanFloat& init_qop,
    const Vector5& x,
    const SymMatrix5x5& C,
    const trackInfo& tI,
    FittedTrack& track,
    const unsigned& velo_hits,
    unsigned& ut_hits,
    unsigned& scifi_hits);

  //----------------------------------------------------------------------
  // Run the Kalman filter on a track.
  __device__ void fit(
    const Allen::Views::Velo::Consolidated::Track& velo_track,
    const Allen::Views::UT::Consolidated::Track& ut_track,
    const Allen::Views::SciFi::Consolidated::Track& scifi_track,
    const KalmanFloat init_qop,
    const KalmanParametrizations* kalman_params,
    FittedTrack& track,
    const SciFi::SciFiGeometry scifi_geometry,
    const float* dev_UT_lay,
    const float* dev_T_lay,
    const float* dev_V_pars,
    const float* dev_VUT_par,
    const float* dev_UT_pars,
    const float* dev_UTTF_pars,
    const float* dev_T_par,
    const float* dev_TFT_par,
    const float* dev_UTT_META);

  __device__ void propagate_to_beamline(FittedTrack& track, float* dev_beamline);

} // namespace ParKalmanFilter

namespace kalman_filter {
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

  //--------------------------------------------------
  // Main execution of the parametrized Kalman Filter.
  //--------------------------------------------------
  __global__ void kalman_filter(
    Parameters,
    const float* dev_magnet_polarity,
    const ParKalmanFilter::KalmanParametrizationsStruct* dev_kalman_params);

  // Does this need to be reimplemented?
  __global__ void kalman_pv_ip(Parameters parameters);

  struct kalman_filter_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
  };
} // namespace kalman_filter
