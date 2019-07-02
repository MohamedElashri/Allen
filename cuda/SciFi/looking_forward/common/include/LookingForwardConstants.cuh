#pragma once

#include "SystemOfUnits.h"
#include "SciFiDefinitions.cuh"

#include <cstdint>

namespace LookingForward {
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
  constexpr float chi2_cut = 4.f;

  /**
   * Station where seeding starts from
   */
  constexpr uint seeding_station = 3;
  constexpr int seeding_first_layer = 8;
  constexpr int seeding_second_layer = 11;

  // /**
  //  * Number of Y threads of form_seeds_from_first_layer_window
  //  */
  // constexpr int lf_form_seeds_from_first_layer_window_y_threads = 32;
  // constexpr int form_seeds_candidates_per_thread = 4;
  // constexpr int form_seeds_stop_after_number_of_candidates = 10;

  /**
   * Form seeds from candidates
   */
  constexpr int maximum_iteration_l3_window = 4;
  constexpr int track_candidates_per_window = 1;

  constexpr float x_diff_layer_qop_offset = 20.f * Gaudi::Units::mm;
  constexpr float x_diff_layer_qop_slope_a = 0.3e6;
  constexpr float x_diff_layer_qop_slope_b = 0.2e6;

  /**
   * Constants for lf search by triplet
   */
  constexpr int number_of_x_layers = 6;
  constexpr int number_of_uv_layers = 6;
  constexpr int maximum_number_of_candidates = 128; // 32;
  constexpr int maximum_number_of_candidates_per_ut_track = 128*4; // 32 * 2;
  constexpr int maximum_number_of_candidates_per_ut_track_after_x_filter = 128*4; // 32*2; // 2;
  constexpr int maximum_number_of_triplets_per_h1 = 10;
  constexpr int tile_size = 16;
  constexpr int tile_size_mask = 0xF;
  constexpr int tile_size_shift_div = 4;
  constexpr int num_atomics = 1;
  constexpr float track_min_quality = 0.05f;
  constexpr int track_min_hits = 9;
  constexpr float filter_x_max_chi2 = 1.f;
  constexpr float filter_x_max_xAtRef_spread = 1e9f; // 10.f;

  // cut on the difference between tx from the extrapolation and
  // tx from the hits in the two x layers
  constexpr float max_tx_diff = 0.05f * Gaudi::Units::mm;

  // z distance between various layers of a station
  // FIXME_GEOMETRY_HARDCODING
  constexpr float dz_layers_station = 70. * Gaudi::Units::mm;
  constexpr float dz_x_layers = 3.f * dz_layers_station;
  constexpr float inverse_dz_x_layers = 1.f / dz_x_layers;
  constexpr float dz_x_u_layers = 1.f * dz_layers_station;
  constexpr float dz_u_v_layers = 1.f * dz_layers_station;
  constexpr float dz_x_v_layers = 2.f * dz_layers_station;

  // z at the center of the magnet
  constexpr float z_magnet = 5212.38f; // FIXME_GEOMETRY_HARDCODING

  // z distance between various layers of different stations
  // FIXME_GEOMETRY_HARDCODING
  constexpr float dz_x_T1_0_T2_0 = 682 * Gaudi::Units::mm;
  constexpr float dz_x_T1_0_T2_3 = 892 * Gaudi::Units::mm;
  constexpr float dz_x_T1_0_T3_0 = 1367 * Gaudi::Units::mm;
  constexpr float dz_x_T1_0_T3_3 = 1577 * Gaudi::Units::mm;

  // cut on x difference between x- and u-/v-layers
  constexpr float dx_x_uv_layers = 200.f * Gaudi::Units::mm;
  constexpr float dx_x_uv_layers_slope = 2.f * Gaudi::Units::mm;

  // cut on x difference between T1 and T2/T3 x-layers
  constexpr float dx_x_T2_T3_offset = 500 * Gaudi::Units::mm;
  constexpr float dx_x_T2_T3_slope = 6.e6f;

  constexpr float z_last_UT_plane = 2642.f; // FIXME_GEOMETRY_HARDCODING

  // z difference between reference plane and end of SciFi
  constexpr float zReferenceEndTDiff = SciFi::Constants::ZEndT - SciFi::Tracking::zReference;

  // combinatorics cut-offs, to be tuned!!
  // max # of quadruplets per veloUT input track
  constexpr int max_quadruplets = 100;

  // detector limits
  constexpr float xMin = -4090.f;
  constexpr float xMax = 4090.f;
  constexpr float yUpMin = -50.f;
  constexpr float yUpMax = 3030.f;
  constexpr float yDownMin = -3030.f;
  constexpr float yDownMax = 50.f;

  // Parameter for forwarding through SciFi layers
  constexpr float forward_param = 2.41902127e-02;
  constexpr float chi2_track_mean = 6.78f;
  constexpr float chi2_track_stddev = 45.28f;

  constexpr float zMagnetParams_0 = 5212.38f;
  constexpr float zMagnetParams_1 = 406.609f;
  constexpr float zMagnetParams_2 = -1102.35f;
  constexpr float zMagnetParams_3 = -498.039f;
  constexpr float xParams_0 = 18.6195f;
  constexpr float xParams_1 = -5.55793;

  constexpr float chi2_max_triplet_single = 500.f; // 24.f; // 12.f;
  constexpr float chi2_max_extrapolation_to_x_layers_single = 4.f;
  constexpr float chi2_max_extrapolation_to_uv_layers_single = 10.f;

  struct Constants {
    float extrapolation_stddev[8] {3.63f, 3.73f, 3.51f, 2.99f, 1.50f, 2.34f, 2.30f, 1.f};
    float chi2_extrap_mean[8] {13.21f, 13.93f, 12.34f, 8.96f, 2.29f, 5.52f, 5.35f, 1.03f};
    float chi2_extrap_stddev[8] {116.5f, 104.5f, 98.35f, 80.66f, 24.11f, 35.91f, 36.7f, 9.72f};

    int xZones[12] {0, 6, 8, 14, 16, 22, 1, 7, 9, 15, 17, 23};
    float Zone_zPos[12] {7826., 7896., 7966., 8036., 8508., 8578., 8648., 8718., 9193., 9263., 9333., 9403.};
    float Zone_zPos_xlayers[6] {7826., 8036., 8508., 8718., 9193., 9403.};
    float Zone_zPos_uvlayers[6] {7896., 7966., 8578., 8648., 9263., 9333.};
    float zMagnetParams[4] {5212.38, 406.609, -1102.35, -498.039};

    float Zone_dxdy[4] {0, 0.0874892, -0.0874892, 0};
    float Zone_dxdy_uvlayers[6] {0.0874892, -0.0874892};

    // Configuration of sbt
    // Triplet creation
    float dx_stddev_triplet[8] {53.01f, 117.1f, 97.43f, 42.68f, 39.89f, 88.74f, 77.55f, 33.79f};
    float chi2_mean_triplet[4] {2.35f, 3.14f, 2.17f, 3.95f};
    float chi2_stddev_triplet[4] {14.05f, 7.49f, 9.97f, 7.97f};

    // Extrapolation
    float dx_stddev_extrapolation_to_x_layers[3] {1.50f, 1.40f, 1.74f};
    float chi2_mean_extrapolation_to_x_layers[3] {3.09f, 1.98f, 3.89f};
    float chi2_stddev_extrapolation_to_x_layers[3] {6.33f, 5.09f, 7.42f};
    uint8_t max_candidates_triplets[4] {20, 20, 20, 20};

    // Extrapolation to UV
    uint8_t x_layers[6] {0, 3, 4, 7, 8, 11};
    uint8_t extrapolation_uv_layers[6] {1, 2, 5, 6, 9, 10};
    float extrapolation_uv_stddev[6] {1.112f, 1.148f, 2.139f, 2.566f, 6.009f, 6.683f};
    float chi2_extrapolation_uv_mean[6] {1.304f, 1.384f, 4.577f, 6.587f, 36.1f, 44.67f};
    float chi2_extrapolation_uv_stddev[6] {10.6f, 11.82f, 17.84f, 23.2f, 68.05f, 81.47f};

    uint8_t convert_layer[12] = {0, 0, 0, 1, 2, 2, 2, 3, 4, 4, 4, 5};

    float ds_p_param[12] {1080.88,
                          1076.73,
                          1112.94,
                          1081.53,
                          1090.73,
                          1085.53,
                          1086.62,
                          1092.9,
                          1108.92,
                          1109.86,
                          1110.35,
                          1107.57};

    float ds_p_param_layer_inv[6] {0.000765058, 0.000766336, 0.000766501, 0.000767106, 0.000828006, 0.000764088};

    float dp_y_mag_plus[12][3] {{-4.03134, -0.0407008, -0.000125335},
                                {-4.56306, -0.0419834, -0.000137366},
                                {5.49547, -0.0573392, -0.00010095},
                                {2.37975, -0.0742168, -0.000113757},
                                {-10.5447, 0.00312105, -0.000225384},
                                {2.26495, -0.086444, -0.000141695},
                                {0.832503, -0.070357, -0.00015239},
                                {-2.35574, -0.0476451, -0.00017992},
                                {9.8991, -0.0955959, -0.00017388},
                                {10.85, -0.130883, -0.000135029},
                                {10.7306, -0.116916, -0.000136706},
                                {9.40471, -0.119738, -0.000146085}};

    float dp_y_mag_minus[12][3] = {{4.90439, 0.0743195, 8.25883e-05},
                                   {5.1064, 0.0855036, 7.3564e-05},
                                   {-2.06204, 0.0614953, 9.03635e-05},
                                   {4.10235, 0.0808931, 9.28188e-05},
                                   {3.65445, 0.0952022, 0.000106498},
                                   {8.88392, 0.081089, 0.000112349},
                                   {6.3909, 0.103315, 0.00011248},
                                   {-0.235336, 0.121804, 9.87285e-05},
                                   {2.9996, 0.0943824, 0.00014551},
                                   {5.7045, 0.0763703, 0.00015718},
                                   {-0.202371, 0.109152, 0.000150647},
                                   {-0.166246, 0.137596, 0.000107092}};

    float dp_x_mag_plus[12][5] {{-4.33253, -0.029506, -8.63398e-05, 2.64756e-08, 4.38027e-11},
                                {-3.80873, -0.0334818, -9.12348e-05, 2.99515e-08, 4.7506e-11},
                                {-8.72604, -0.0320451, -8.08217e-05, 1.87344e-08, 3.67157e-11},
                                {-10.7031, -0.0316373, -0.000119356, 3.20288e-08, 6.00446e-11},
                                {7.23597, -0.0346955, -7.79692e-05, 2.34952e-08, 3.45765e-11},
                                {-12.6321, -0.0329862, -0.000130066, 4.80244e-08, 7.36979e-11},
                                {-10.9691, -0.0269025, -0.000124596, 3.44297e-08, 6.46541e-11},
                                {-5.09126, -0.0308414, -0.000100783, 3.75118e-08, 5.6831e-11},
                                {-15.2861, -0.0393007, -0.000139445, 5.27233e-08, 7.95029e-11},
                                {-17.5047, -0.032634, -0.000167568, 3.19135e-08, 7.81483e-11},
                                {-17.9782, -0.0486609, -0.000169477, 6.83501e-08, 9.89324e-11},
                                {-16.5908, -0.0529241, -0.000177866, 7.88524e-08, 1.08012e-10}};

    float dp_x_mag_minus[12][5] {{4.26031, -0.0415664, 0.000146422, 3.51598e-08, -8.27693e-11},
                                 {5.40441, -0.0477524, 0.000166125, 4.27807e-08, -9.58994e-11},
                                 {5.26677, -0.0427178, 0.000113941, 3.04528e-08, -6.46278e-11},
                                 {4.39713, -0.046353, 0.000167304, 4.09351e-08, -9.54856e-11},
                                 {4.85384, -0.0487524, 0.000191603, 4.84151e-08, -1.12059e-10},
                                 {1.47962, -0.0460985, 0.000207249, 4.20344e-08, -1.17115e-10},
                                 {4.58992, -0.0470858, 0.0001976, 4.82945e-08, -1.13505e-10},
                                 {8.81221, -0.0414332, 0.000208094, 4.34718e-08, -1.18516e-10},
                                 {4.60624, -0.0541308, 0.000201555, 4.75008e-08, -1.15571e-10},
                                 {0.782871, -0.047126, 0.000201297, 3.86795e-08, -1.14059e-10},
                                 {4.72645, -0.0518947, 0.000219339, 4.68011e-08, -1.24165e-10},
                                 {9.10178, -0.0566818, 0.00026297, 6.6007e-08, -1.58485e-10}};

    float dp_plus_offset[12] {19.3354,
                              22.3182,
                              46.002,
                              21.7518,
                              27.7576,
                              30.3437,
                              552.816,
                              28.3234,
                              37.037,
                              40.018,
                              37.6157,
                              35.6917};
    float dp_minus_offset[12] {-18.1339,
                               -21.0436,
                               -45.0591,
                               -20.4936,
                               -25.8877,
                               -28.3128,
                               -444.456,
                               -27.4285,
                               -35.0231,
                               -36.6656,
                               -38.7877,
                               -34.5437};
  };
} // namespace LookingForward
