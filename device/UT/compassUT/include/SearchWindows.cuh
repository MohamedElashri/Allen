#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_search_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, uint) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, uint) dev_ut_selected_velo_tracks;
    DEVICE_OUTPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    PROPERTY(min_momentum_t, float, "min_momentum", "min momentum cut [MeV/c]") min_momentum;
    PROPERTY(min_pt_t, float, "min_pt", "min pT cut [MeV/c]") min_pt;
    PROPERTY(y_tol_t, float, "y_tol", "y tol [mm]") y_tol;
    PROPERTY(y_tol_slope_t, float, "y_tol_slope", "y tol slope [mm]") y_tol_slope;
    PROPERTY(block_dim_y_t, uint, "block_dim_y_t", "block dimension Y");
  };

  __global__ void ut_search_windows(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_ut_dxDy,
    const uint* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs);

  template<typename T>
  struct ut_search_windows_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(ut_search_windows)) function {ut_search_windows};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_windows_layers_t>(
        arguments,
        CompassUT::num_elems * UT::Constants::n_layers * value<host_number_of_reconstructed_velo_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_ut_windows_layers_t>(arguments, 0, cuda_stream);

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        dim3(UT::Constants::n_layers, property<block_dim_y_t>()),
        cuda_stream)(
        Parameters {begin<dev_ut_hits_t>(arguments),
                    begin<dev_ut_hit_offsets_t>(arguments),
                    begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_states_t>(arguments),
                    begin<dev_ut_number_of_selected_velo_tracks_t>(arguments),
                    begin<dev_ut_selected_velo_tracks_t>(arguments),
                    begin<dev_ut_windows_layers_t>(arguments),
                    property<min_momentum_t>(),
                    property<min_pt_t>(),
                    property<y_tol_t>(),
                    property<y_tol_slope_t>()},
        constants.dev_ut_magnet_tool,
        constants.dev_ut_dxDy.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_sector_xs.data());
    }

  private:
    Property<min_momentum_t> m_mom {this, 1.5f * Gaudi::Units::GeV};
    Property<min_pt_t> m_pt {this, 300.f};
    Property<y_tol_t> m_ytol {this, 0.5f * Gaudi::Units::mm};
    Property<y_tol_slope_t> m_yslope {this, 0.08f};
    Property<block_dim_y_t> m_block_dim_y {this, 64};
  };
} // namespace ut_search_windows
