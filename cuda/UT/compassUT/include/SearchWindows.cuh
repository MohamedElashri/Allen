#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"

__global__ void ut_search_windows(
  uint* dev_ut_hits,
  const uint* dev_ut_hit_offsets,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  char* dev_velo_states,
  UTMagnetTool* dev_ut_magnet_tool,
  const float* dev_ut_dxDy,
  const uint* dev_unique_x_sector_layer_offsets,
  const float* dev_unique_sector_xs,
  short* dev_windows_layers,
  uint* dev_active_tracks,
  bool* dev_accepted_velo_tracks);

struct ut_search_windows_t : public DeviceAlgorithm {
  constexpr static auto name {"ut_search_windows_t"};
  decltype(global_function(ut_search_windows)) function {ut_search_windows};
  using Arguments = std::tuple<
    dev_ut_hits,
    dev_ut_hit_offsets,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_track_hits,
    dev_velo_states,
    dev_ut_windows_layers,
    dev_accepted_velo_tracks,
    dev_ut_active_tracks>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;

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
