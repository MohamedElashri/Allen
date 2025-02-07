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

#include "UTMagnetToolDefinitions.h"
#include "UTDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "UTEventModel.cuh"

//=========================================================================
// Function definitions
//=========================================================================
namespace compass_ut {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits; // actual hit contents
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_with_windows_t, unsigned)
    dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_with_windows_t, unsigned) dev_ut_selected_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_OUTPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    DEVICE_OUTPUT(dev_offsets_ut_tracks_t, unsigned) dev_offsets_ut_tracks;
    HOST_OUTPUT(host_number_of_reconstructed_ut_tracks_t, unsigned) host_number_of_reconstructed_ut_tracks;
  };

  __global__ void compass_ut(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_magnet_polarity,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float min_momentum_final,
    const float min_pt_final,
    const unsigned max_considered_before_found,
    const float delta_tx_2,
    const float hit_tol_2,
    const float sigma_velo_slope,
    const float min_ld_3_hit,
    const float min_ld_4_hit);

  struct compass_ut_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_slope {this, "sigma_velo_slope", 0.1f * Gaudi::Units::mrad, "sigma velo slope [radians]"};
    Allen::Property<float> m_mom_fin {this, "min_momentum_final", 2500.f, "final min momentum cut [MeV/c]"};
    Allen::Property<float> m_pt_fin {this, "min_pt_final", 425.f, "final min pT cut [MeV/c]"};
    Allen::Property<float> m_hit_tol_2 {this, "hit_tol_2", 0.8f * Gaudi::Units::mm, "hit_tol_2 [mm]"};
    Allen::Property<float> m_delta_tx_2 {this, "delta_tx_2", 0.018f, "delta_tx_2"};
    Allen::Property<unsigned> m_max_considered_before_found {this,
                                                             "max_considered_before_found",
                                                             6,
                                                             "max_considered_before_found"};
    Allen::Property<float> m_min_ld_3_hit {this, "min_ld_3_hit", -0.5f, "min_ld_3_hit"};
    Allen::Property<float> m_min_ld_4_hit {this, "min_ld_4_hit", -0.5f, "min_ld_4_hit"};
  };
} // namespace compass_ut
