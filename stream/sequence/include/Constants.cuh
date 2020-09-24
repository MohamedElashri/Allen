/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <array>
#include <cstdint>
#include <algorithm>
#include <numeric>
#include <gsl/gsl>
#include "CudaCommon.h"
#include "Logger.h"

// Forward declarations
struct VeloGeometry;
struct UTMagnetTool;
namespace Muon {
  class MuonGeometry;
  class MuonTables;
  namespace Constants {
    struct FieldOfInterest;
  }
}
namespace LookingForward {
  struct Constants;
}
namespace ParKalmanFilter {
  struct KalmanParametrizations;
}
namespace MatchUpstreamMuon {
  struct MuonChambers;
  struct SearchWindows;
}

/**
 * @brief Struct intended as a singleton with constants defined on GPU.
 * @details __constant__ memory on the GPU has very few use cases.
 *          Instead, global memory is preferred. Hence, this singleton
 *          should allocate the requested buffers on GPU and serve the
 *          pointers wherever needed.
 *
 *          The pointers are hard-coded. Feel free to write more as needed.
 */
struct Constants {

  gsl::span<uint8_t> dev_velo_candidate_ks;
  gsl::span<uint8_t> dev_velo_sp_patterns;
  gsl::span<float> dev_velo_sp_fx;
  gsl::span<float> dev_velo_sp_fy;
  VeloGeometry* dev_velo_geometry = nullptr;

  std::vector<char> host_ut_geometry;
  std::vector<unsigned> host_ut_region_offsets;
  std::vector<float> host_ut_dxDy;
  std::vector<unsigned> host_unique_x_sector_layer_offsets;
  std::vector<unsigned> host_unique_x_sector_offsets;
  std::vector<float> host_unique_sector_xs;

  gsl::span<char> dev_ut_geometry;
  gsl::span<float> dev_ut_dxDy;
  gsl::span<unsigned> dev_unique_x_sector_layer_offsets;
  gsl::span<unsigned> dev_unique_x_sector_offsets;
  gsl::span<unsigned> dev_ut_region_offsets;
  gsl::span<float> dev_unique_sector_xs;
  gsl::span<char> dev_ut_boards;
  UTMagnetTool* dev_ut_magnet_tool = nullptr;

  std::array<float, 9> host_inv_clus_res;
  float* dev_inv_clus_res;

  // Geometry constants
  char* dev_scifi_geometry = nullptr;
  std::vector<char> host_scifi_geometry;

  // Beam location
  gsl::span<float> dev_beamline;

  // Magnet polarity
  gsl::span<float> dev_magnet_polarity;

  // Looking forward
  LookingForward::Constants* host_looking_forward_constants;

  // Muon
  char* dev_muon_geometry_raw = nullptr;
  char* dev_muon_lookup_tables_raw = nullptr;
  std::vector<char> host_muon_geometry_raw;
  std::vector<char> host_muon_lookup_tables_raw;
  Muon::MuonGeometry* dev_muon_geometry = nullptr;
  Muon::MuonTables* dev_muon_tables = nullptr;

  // Velo-UT-muon
  MatchUpstreamMuon::MuonChambers* dev_muonmatch_search_muon_chambers = nullptr;
  MatchUpstreamMuon::SearchWindows* dev_muonmatch_search_windows = nullptr;

  // Muon classification model constatns
  Muon::Constants::FieldOfInterest* dev_muon_foi = nullptr;
  float* dev_muon_momentum_cuts = nullptr;
  int muon_catboost_n_trees;
  int* dev_muon_catboost_tree_depths = nullptr;
  int* dev_muon_catboost_tree_offsets = nullptr;
  int* dev_muon_catboost_split_features = nullptr;
  float* dev_muon_catboost_split_borders = nullptr;
  float* dev_muon_catboost_leaf_values = nullptr;
  int* dev_muon_catboost_leaf_offsets = nullptr;
  LookingForward::Constants* dev_looking_forward_constants = nullptr;

  // Kalman filter
  ParKalmanFilter::KalmanParametrizations* dev_kalman_params = nullptr;

  /**
   * @brief Reserves and initializes constants.
   */
  void reserve_and_initialize(
    const std::vector<float>& muon_field_of_interest_params,
    const std::string& folder_params_kalman)
  {
    reserve_constants();
    initialize_constants(muon_field_of_interest_params, folder_params_kalman);
  }

  /**
   * @brief Reserves the constants of the GPU.
   */
  void reserve_constants();

  /**
   * @brief Initializes constants on the GPU.
   */
  void initialize_constants(
    const std::vector<float>& muon_field_of_interest_params,
    const std::string& folder_params_kalman);

  /**
   * @brief Initializes UT decoding constants.
   */
  void initialize_ut_decoding_constants(const std::vector<char>& ut_geometry);

  void initialize_muon_catboost_model_constants(
    const int n_trees,
    const std::vector<int>& tree_depths,
    const std::vector<int>& tree_offsets,
    const std::vector<float>& leaf_values,
    const std::vector<int>& leaf_offsets,
    const std::vector<float>& split_borders,
    const std::vector<int>& split_features);
};
