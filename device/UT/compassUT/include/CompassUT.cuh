/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "UTMagnetToolDefinitions.h"
#include "UTDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

//=========================================================================
// Function definitions
//=========================================================================
namespace compass_ut {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_ut_hits_t, char), dev_ut_hits), // actual hit contents
    (DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned), dev_ut_hit_offsets),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo), // prefixsum, offset to tracks
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_states_t, char), dev_velo_states),
    (DEVICE_OUTPUT(dev_ut_tracks_t, UT::TrackHits), dev_ut_tracks),
    (DEVICE_OUTPUT(dev_atomics_ut_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_ut_windows_layers_t, short), dev_ut_windows_layers),
    (DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_with_windows_t, unsigned), dev_ut_number_of_selected_velo_tracks),
    (DEVICE_INPUT(dev_ut_selected_velo_tracks_with_windows_t, unsigned), dev_ut_selected_velo_tracks),
    (PROPERTY(sigma_velo_slope_t, "sigma_velo_slope", "sigma velo slope [radians]", float), sigma_velo_slope),
    (PROPERTY(min_momentum_final_t, "min_momentum_final", "final min momentum cut [MeV/c]", float), min_momentum_final),
    (PROPERTY(min_pt_final_t, "min_pt_final", "final min pT cut [MeV/c]", float), min_pt_final),
    (PROPERTY(hit_tol_2_t, "hit_tol_2", "hit_tol_2 [mm]", float), hit_tol_2),
    (PROPERTY(delta_tx_2_t, "delta_tx_2", "delta_tx_2", float), delta_tx_2),
    (PROPERTY(max_considered_before_found_t, "max_considered_before_found", "max_considered_before_found", unsigned), max_considered_before_found))

  __global__ void compass_ut(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_magnet_polarity,
    const float* dev_ut_dxDy,
    const unsigned* dev_unique_x_sector_layer_offsets);

  struct compass_ut_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<sigma_velo_slope_t> m_slope {this, 0.1f * Gaudi::Units::mrad};
    Property<min_momentum_final_t> m_mom_fin {this, 2500.f};
    Property<min_pt_final_t> m_pt_fin {this, 425.f};
    Property<hit_tol_2_t> m_hit_tol_2 {this, 0.8f * Gaudi::Units::mm};
    Property<delta_tx_2_t> m_delta_tx_2 {this, 0.018f};
    Property<max_considered_before_found_t> m_max_considered_before_found {this, 6};
  };
} // namespace compass_ut
