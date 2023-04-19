/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloConsolidated.cuh"

namespace FilterVELOTracks {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;

    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_track_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_OUTPUT(dev_filtered_velo_track_idx_t, unsigned) dev_filtered_velo_track_idx;
    DEVICE_OUTPUT(dev_number_of_filtered_tracks_t, unsigned) dev_number_of_filtered_tracks;
    DEVICE_OUTPUT(dev_number_of_close_track_pairs_t, unsigned) dev_number_of_close_track_pairs;

    PROPERTY(beamdoca_r_t, "beamdoca_r", "radial doca to the beamspot", float) beamdoca_r;
    PROPERTY(
      max_doca_for_close_track_pairs_t,
      "max_doca_for_close_track_pairs",
      "doca to define close track pairs",
      float)
    max_doca_for_close_track_pairs;
    PROPERTY(block_dim_t, "block_dim", "block dimension", DeviceDimensions) block_dim;
  };

  __global__ void filter_velo_tracks(Parameters, float*);

  struct filter_velo_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<beamdoca_r_t> m_beamdoca_r {this, 3.5f};
    Property<max_doca_for_close_track_pairs_t> m_max_doca_for_close_track_pairs {this, 0.15f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };

} // namespace FilterVELOTracks
