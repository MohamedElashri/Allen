#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "Handler.cuh"
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

namespace Configuration {
  namespace ut_search_windows_t {
    extern __constant__ float min_momentum;
    extern __constant__ float min_pt;
    extern __constant__ float y_tol;
    extern __constant__ float y_tol_slope;
  } // namespace ut_search_windows_t
} // namespace Configuration

ALGORITHM(ut_search_windows,
          ut_search_windows_t,
          ARGUMENTS(
            dev_ut_hits,
            dev_ut_hit_offsets,
            dev_atomics_velo,
            dev_velo_track_hit_number,
            dev_velo_track_hits,
            dev_velo_states,
            dev_ut_windows_layers,
            dev_accepted_velo_tracks,
            dev_ut_active_tracks),
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
          Property<float>
            m_ytol {this, "y_tol", Configuration::ut_search_windows_t::y_tol, 0.5f * Gaudi::Units::mm, "y tol [mm]"};
          Property<float>
            m_yslope {this, "y_tol_slope", Configuration::ut_search_windows_t::y_tol_slope, 0.08f, "y tol slope [mm]"};)
