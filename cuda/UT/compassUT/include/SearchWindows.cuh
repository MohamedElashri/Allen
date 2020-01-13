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
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_OUTPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    DEVICE_OUTPUT(dev_ut_active_tracks_t, uint) dev_ut_active_tracks;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
  };

  __global__ void ut_search_windows(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_ut_dxDy,
    const uint* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs);

  template<typename T>
  struct ut_search_windows_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"ut_search_windows_t"};
    decltype(global_function(ut_search_windows)) function {ut_search_windows};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_windows_layers_t>(
        arguments,
        CompassUT::num_elems * UT::Constants::n_layers * value<host_number_of_reconstructed_velo_tracks_t>(arguments));
      set_size<dev_ut_active_tracks_t>(arguments, runtime_options.number_of_events);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_ut_active_tracks_t>(arguments), 0, size<dev_ut_active_tracks_t>(arguments), cuda_stream));

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        dim3(UT::Constants::n_layers, UT::Constants::num_thr_searchwin),
        cuda_stream)(
        Parameters {offset<dev_ut_hits_t>(arguments),
                   offset<dev_ut_hit_offsets_t>(arguments),
                   offset<dev_atomics_velo_t>(arguments),
                   offset<dev_velo_track_hit_number_t>(arguments),
                   offset<dev_velo_states_t>(arguments),
                   offset<dev_ut_windows_layers_t>(arguments),
                   offset<dev_ut_active_tracks_t>(arguments),
                   offset<dev_accepted_velo_tracks_t>(arguments)},
        constants.dev_ut_magnet_tool,
        constants.dev_ut_dxDy.data(),
        constants.dev_unique_x_sector_layer_offsets.data(),
        constants.dev_unique_sector_xs.data());
    }

  private:
    Property<float> m_mom {this,
                           "min_momentum",
                           Configuration::ut_search_windows_t::min_momentum,
                           1.5f * Gaudi::Units::GeV,
                           "min momentum cut [MeV/c]"};
    Property<float> m_pt {this,
                          "min_pt",
                          Configuration::ut_search_windows_t::min_pt,
                          0.3f * Gaudi::Units::GeV,
                          "min pT cut [MeV/c]"};
    Property<float> m_ytol {this,
                            "y_tol",
                            Configuration::ut_search_windows_t::y_tol,
                            0.5f * Gaudi::Units::mm,
                            "y tol [mm]"};
    Property<float> m_yslope {this,
                              "y_tol_slope",
                              Configuration::ut_search_windows_t::y_tol_slope,
                              0.08f,
                              "y tol slope [mm]"};
  };
} // namespace ut_search_windows