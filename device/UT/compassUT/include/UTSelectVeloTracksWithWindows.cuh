/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "AlgorithmTypes.cuh"

namespace ut_select_velo_tracks_with_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_OUTPUT(dev_ut_number_of_selected_velo_tracks_with_windows_t, unsigned)
    dev_ut_number_of_selected_velo_tracks_with_windows;
    DEVICE_OUTPUT(dev_ut_selected_velo_tracks_with_windows_t, unsigned) dev_ut_selected_velo_tracks_with_windows;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void ut_select_velo_tracks_with_windows(Parameters);

  struct ut_select_velo_tracks_with_windows_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace ut_select_velo_tracks_with_windows