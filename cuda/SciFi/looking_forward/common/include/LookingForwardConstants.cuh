#pragma once

#include "SystemOfUnits.h"
#include "SciFiDefinitions.cuh"

#include <cstdint>

namespace LookingForward {

  // constants for dx_calc (used by both algorithms)
  constexpr float dx_slope = 1e5f;
  constexpr float dx_min = 300.f;
  constexpr float dx_weight = 0.6f;
  constexpr float tx_slope = 1250.f;
  constexpr float tx_min = 300.f;
  constexpr float tx_weight = 0.4f;
  constexpr float max_window_layer0 = 600.f;
  constexpr float max_window_layer1 = 2.f;
  constexpr float max_window_layer2 = 2.f;
  constexpr float max_window_layer3 = 20.f;

  /*=====================================
    Constants for looking forward
    ======================================*/
  constexpr float chi2_cut = 4.f;

  /**
   * Station where seeding starts from
   */
  constexpr uint seeding_station = 3;
  constexpr int seeding_first_layer = 8;

  /**
   * Form seeds from candidates
   */
  constexpr int maximum_iteration_l3_window = 4;
  constexpr int track_candidates_per_window = 1;

  // z distance between various layers of a station
  // FIXME_GEOMETRY_HARDCODING
  constexpr float dz_layers_station = 70.f * Gaudi::Units::mm;
  constexpr float dz_x_layers = 3.f * dz_layers_station;
  constexpr float inverse_dz_x_layers = 1.f / dz_x_layers;
  constexpr float dz_x_u_layers = 1.f * dz_layers_station;
  constexpr float dz_x_v_layers = 2.f * dz_layers_station;

  // detector limits
  constexpr float xMin = -4090.f;
  constexpr float xMax = 4090.f;
  constexpr float yUpMin = -50.f;
  constexpr float yUpMax = 3030.f;
  constexpr float yDownMin = -3030.f;
  constexpr float yDownMax = 50.f;

  // ==================================
  // Constants for lf search by triplet
  // ==================================
  constexpr int number_of_x_layers = 6;
  constexpr int number_of_uv_layers = 6;
  constexpr int maximum_number_of_candidates = 16;
  constexpr int maximum_number_of_candidates_per_ut_track = 40;
  constexpr int maximum_number_of_candidates_per_ut_track_after_x_filter = 40;
  constexpr int maximum_number_of_triplets_per_h1 = 2;
  constexpr int n_threads_triplet_seeding = 32;
  constexpr int n_triplet_seeds = 2;
  constexpr int tile_size = 16;
  constexpr int tile_size_mask = 0xF;
  constexpr int tile_size_shift_div = 4;

  constexpr int num_atomics = 1;
  constexpr float track_min_quality = 0.05f;
  constexpr int track_min_hits = 9;
  constexpr float filter_x_max_xAtRef_spread = 10.f;

  // z at the center of the magnet
  constexpr float z_magnet = 5212.38f; // FIXME_GEOMETRY_HARDCODING

  constexpr float z_last_UT_plane = 2642.f; // FIXME_GEOMETRY_HARDCODING

  // z difference between reference plane and end of SciFi
  constexpr float zReferenceEndTDiff = SciFi::Constants::ZEndT - SciFi::Tracking::zReference;

  // Parameter for forwarding through SciFi layers
  constexpr float forward_param = 2.41902127e-02;
  // constexpr float forward_param = 0.04518205911571838;
  constexpr float d_ratio = -0.00017683181567234045f * forward_param;
  // constexpr float d_ratio = -2.62e-04 * forward_param;
  // constexpr float d_ratio = -8.585717012100695e-06;

  // Chi2 cuts for triplet of three x hits and when extending to other x and uv layers
  constexpr float chi2_max_triplet_single = 12.f;                  // 5.f;
  constexpr float chi2_max_extrapolation_to_x_layers_single = 4.f; // 2.f; // 4.f;
  constexpr float chi2_max_extrapolation_to_uv_layers_single = 10.f;

  // ======================================
  // Constants for various parametrizations
  // ======================================

  // Reference z plane
  constexpr float z_mid_t = 8520.f * Gaudi::Units::mm;

  struct Constants {

    int xZones[12] {0, 6, 8, 14, 16, 22, 1, 7, 9, 15, 17, 23};
    int uvZones[12] {2, 4, 10, 12, 18, 20, 3, 5, 11, 13, 19, 21};

    float Zone_zPos[12] {7826.f, 7896.f, 7966.f, 8036.f, 8508.f, 8578.f, 8648.f, 8718.f, 9193.f, 9263.f, 9333.f, 9403.f};
    float Zone_zPos_xlayers[6] {7826.f, 8036.f, 8508.f, 8718.f, 9193.f, 9403.f};
    float Zone_zPos_uvlayers[6] {7896.f, 7966.f, 8578.f, 8648.f, 9263.f, 9333.f};
    float zMagnetParams[4] {5212.38f, 406.609f, -1102.35f, -498.039f};
    float Zone_dxdy[4] {0.f, 0.0874892f, -0.0874892f, 0.f};
    float Zone_dxdy_uvlayers[2] {0.0874892f, -0.0874892f};

    /*=====================================
    Constant arrays for looking forward
    ======================================*/
    float extrapolation_stddev[8] {3.63f, 3.73f, 3.51f, 2.99f, 1.50f, 2.34f, 2.30f, 1.f};
    float chi2_extrap_mean[8] {13.21f, 13.93f, 12.34f, 8.96f, 2.29f, 5.52f, 5.35f, 1.03f};
    float chi2_extrap_stddev[8] {116.5f, 104.5f, 98.35f, 80.66f, 24.11f, 35.91f, 36.7f, 9.72f};

    /*=====================================
    Constant arrays for search by triplet
    ======================================*/

    // Triplet creation
    uint8_t triplet_seeding_layers[n_triplet_seeds][3] {
      {0, 2, 4},
      {1, 3, 5}
      // {2, 3, 4},
      // {3, 4, 5}
      // {0, 2, 4},
      // {0, 3, 5},
      // {1, 3, 4},
      // {1, 2, 5}
    };

    // Extrapolation
    float chi2_stddev_extrapolation_to_x_layers[3] {6.33f, 5.09f, 7.42f};

    // Extrapolation to UV
    uint8_t x_layers[6] {0, 3, 4, 7, 8, 11};
    uint8_t extrapolation_uv_layers[6] {1, 2, 5, 6, 9, 10};    
    float extrapolation_uv_stddev[6] {1.112f, 1.148f, 2.139f, 2.566f, 6.009f, 6.683f};

    // TODO optimize then umber of parameters

    float ds_multi_param[3 * 5 * 5] {1.17058336e+03f, 0.00000000e+00f, 6.39200125e+03f, 0.00000000e+00f, -1.45707998e+05f,
                                    0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,
                                    7.35087335e+03f, 0.00000000e+00f, -3.23044958e+05f, 0.00000000e+00f, 6.70953953e+06f,
                                    0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,
                                    -3.32975119e+04f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,

                                   1.21404549e+03f, 0.00000000e+00f, 6.39849243e+03f, 0.00000000e+00f, -1.48282139e+05f,
                                    0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,
                                    7.06915986e+03f, 0.00000000e+00f, -2.39992852e+05f, 0.00000000e+00f, 4.48409294e+06f,
                                    0.00000000e+00f, 3.21303132e+04f, 0.00000000e+00f, -1.77557653e+06f, 0.00000000e+00f,
                                    -4.05086623e+04f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,

                                   1.23813318e+03f, 0.00000000e+00f, 6.68779400e+03f, 0.00000000e+00f, -1.51815852e+05f,
                                    0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,
                                    6.72420095e+03f, 0.00000000e+00f, -3.25320622e+05f, 0.00000000e+00f, 6.32694612e+06f,
                                    0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f,
                                    -4.04562789e+04f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f, 0.00000000e+00f};

    float uv_dx[6] = {1.6739478541449213f,
                      1.6738495069872612f,
                      1.935683825160498f,
                      1.9529279746403518f,
                      2.246931985749485f,
                      2.2797556995480273f};
  };
} // namespace LookingForward
