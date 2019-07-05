#pragma once

#include "SystemOfUnits.h"
#include "SciFiDefinitions.cuh"

namespace SciFi {
  namespace MomentumForward {

    // cut on difference between extrapolated x position and x position in
    // first layer of T1 / last layer of T3 as a function of qop
    // The cut is a straight line with offset and slope
    constexpr float dx_extrap_qop_offset_T1 = 20.f * Gaudi::Units::mm;
    constexpr float dx_extrap_qop_slope_T1 = 1.e6;
    constexpr float dx_extrap_qop_offset_T3 = 40.f * Gaudi::Units::mm;
    constexpr float dx_extrap_qop_slope_T3 = 1.5e6;

    // cut on difference between the x hit positions of the two x layers
    // in one station
    // The cut is based on two straight lines with different slopes containing
    // the interesting region
    constexpr float x_diff_layer_qop_offset = 20.f * Gaudi::Units::mm;
    constexpr float x_diff_layer_qop_slope_a = 0.3e6;
    constexpr float x_diff_layer_qop_slope_b = 0.2e6;

    // cut on the difference between tx from the extrapolation and
    // tx from the hits in the two x layers
    constexpr float max_tx_diff = 0.05f * Gaudi::Units::mm;

    // z distance between various layers of a station
    constexpr float dz_layers_station = 70. * Gaudi::Units::mm;
    constexpr float dz_x_layers = 3.f * dz_layers_station;
    constexpr float dz_x_u_layers = 1.f * dz_layers_station;
    constexpr float dz_x_v_layers = 2.f * dz_layers_station;

    // z distance between various layers of different stations
    constexpr float dz_x_T1_0_T2_0 = 682 * Gaudi::Units::mm;
    constexpr float dz_x_T1_0_T2_3 = 892 * Gaudi::Units::mm;
    constexpr float dz_x_T1_0_T3_0 = 1367 * Gaudi::Units::mm;
    constexpr float dz_x_T1_0_T3_3 = 1577 * Gaudi::Units::mm;

    // cut on x difference between x- and u-/v-layers
    constexpr float dx_x_uv_layers = 200.f * Gaudi::Units::mm;
    constexpr float dx_x_uv_layers_slope = 2.f * Gaudi::Units::mm;

    // cut on x difference between T1 and T2/T3 x-layers
    constexpr float dx_x_T2_T3_offset = 500 * Gaudi::Units::mm;
    constexpr float dx_x_T2_T3_slope = 6.e6;

    constexpr float z_last_UT_plane = 2642.f;

    // combinatorics cut-offs, to be tuned!!
    // max # of quadruplets per veloUT input track
    constexpr int max_quadruplets = 100;

    struct Track {
      int hit_indices[SciFi::Tracking::max_scifi_hits];
      float qop;
      int hitsNum = 0;
      float tx;

      __host__ __device__ void addHit(int hit)
      {
        assert(hitsNum < SciFi::Tracking::max_scifi_hits - 1);
        hit_indices[hitsNum++] = hit;
      }
    };
  } // namespace MomentumForward
} // namespace SciFi
