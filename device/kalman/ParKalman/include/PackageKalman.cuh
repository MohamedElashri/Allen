/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
#include "States.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace package_kalman_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_atomics_velo_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void package_kalman_tracks(Parameters);

  struct package_kalman_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace package_kalman_tracks
