/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_search_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_OUTPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    PROPERTY(min_momentum_t, "min_momentum", "min momentum cut [MeV/c]", float) min_momentum;
    PROPERTY(min_pt_t, "min_pt", "min pT cut [MeV/c]", float) min_pt;
    PROPERTY(y_tol_t, "y_tol", "y tol [mm]", float) y_tol;
    PROPERTY(y_tol_slope_t, "y_tol_slope", "y tol slope [mm]", float) y_tol_slope;
    PROPERTY(block_dim_y_t, "block_dim_y_t", "block dimension Y", unsigned) block_dim_y;
  };

  __global__ void ut_search_windows(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_ut_dxDy,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs);

  struct ut_search_windows_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<min_momentum_t> m_mom {this, 1.5f * Gaudi::Units::GeV};
    Property<min_pt_t> m_pt {this, 300.f};
    Property<y_tol_t> m_ytol {this, 0.5f * Gaudi::Units::mm};
    Property<y_tol_slope_t> m_yslope {this, 0.08f};
    Property<block_dim_y_t> m_block_dim_y {this, 64};
  };
} // namespace ut_search_windows
