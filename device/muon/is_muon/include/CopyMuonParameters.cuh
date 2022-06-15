/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "ParticleTypes.cuh"
#include "CheckerTracks.cuh"

namespace copy_muon_parameters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_long_tracks_t, unsigned) host_number_of_reconstructed_long_tracks;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_multi_event_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_long_tracks_view;
    DEVICE_INPUT(dev_is_muon_t, uint8_t) dev_is_muon;
    DEVICE_OUTPUT(dev_muon_checker_tracks_t, Checker::Track) dev_muon_checker_tracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void copy_muon_parameters(Parameters parameters);
  
  struct copy_muon_parameters_t : public DeviceAlgorithm, Parameters {
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
} // namespace copy_muon_parameters