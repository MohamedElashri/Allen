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

#include "UTDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "AlgorithmTypes.cuh"

namespace ut_search_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_OUTPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
  };

  __global__ void ut_search_windows(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const UT::Constants::PerLayerInfo* dev_mean_layer_info,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs,
    const float y_tol,
    const float y_tol_slope,
    const float min_pt,
    const float min_momentum);

  struct ut_search_windows_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_mom {this, "min_momentum", 1500.f * Gaudi::Units::MeV, "min momentum cut [MeV/c]"};
    Allen::Property<float> m_pt {this, "min_pt", 300.f * Gaudi::Units::MeV, "min pT cut [MeV/c]"};
    Allen::Property<float> m_ytol {this, "y_tol", 0.5f * Gaudi::Units::mm, "y tol [mm]"};
    Allen::Property<float> m_yslope {this, "y_tol_slope", 0.08f, "y tol slope [mm]"};
    Allen::Property<unsigned> m_block_dim_y {this, "block_dim_y_t", 128, "block dimension Y"};
  };
} // namespace ut_search_windows
