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

#include <array>
#include <cstdint>
#include <algorithm>
#include <numeric>
#include <gsl/gsl>
#include <chrono>
#include "BackendCommon.h"
#include "Logger.h"
#include "NeuralNetworkDefinition.cuh"

// Forward declarations
struct VeloGeometry;
struct UTMagnetTool;
namespace Muon {
  class MuonGeometry;
  class MuonTables;
  namespace Constants {
    struct FieldOfInterest;
    struct MatchWindows;
  } // namespace Constants
} // namespace Muon
namespace LookingForward {
  struct Constants;
}
namespace ParKalmanFilter {
  struct KalmanParametrizations;
}
namespace MatchUpstreamMuon {
  struct MuonChambers;
  struct SearchWindows;
} // namespace MatchUpstreamMuon
namespace TrackMatchingConsts {
  struct MagnetParametrization;
}
namespace Rich::Future::DAQ::Allen {
  class PDMDBDecodeMapping;
  class Tel40CableMapping;
} // namespace Rich::Future::DAQ::Allen

namespace UT::Constants {
  struct PerLayerInfo;
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
  std::vector<char> host_ut_boards;
  std::vector<float> host_mean_ut_layer_zs;
  std::vector<uint16_t> host_ut_board_geometry_map;

  gsl::span<char> dev_ut_geometry;
  gsl::span<float> dev_ut_dxDy;
  gsl::span<unsigned> dev_unique_x_sector_layer_offsets;
  gsl::span<unsigned> dev_unique_x_sector_offsets;
  //   gsl::span<unsigned> dev_ut_region_offsets;
  gsl::span<float> dev_unique_sector_xs;
  gsl::span<float> dev_mean_ut_layer_zs;
  char* dev_ut_boards;
  UTMagnetTool* dev_ut_magnet_tool = nullptr;
  gsl::span<uint16_t> dev_ut_board_geometry_map;

  std::array<float, 9> host_inv_clus_res;
  float* dev_inv_clus_res;

  char* dev_scifi_geometry = nullptr;
  std::vector<char> host_scifi_geometry;

  // Beam location
  gsl::span<float> dev_beamline;

  // Magnet polarity
  gsl::span<float> dev_magnet_polarity;

  // Looking forward
  LookingForward::Constants* host_looking_forward_constants;

  // Track matching
  TrackMatchingConsts::MagnetParametrization* host_magnet_parametrization;

  // Calo
  std::vector<char> host_ecal_geometry;
  char* dev_ecal_geometry = nullptr;

  // Muon
  char* dev_muon_geometry_raw = nullptr;
  char* dev_muon_lookup_tables_raw = nullptr;
  std::vector<char> host_muon_geometry_raw;
  std::vector<char> host_muon_lookup_tables_raw;
  Muon::MuonGeometry* dev_muon_geometry = nullptr;
  Muon::MuonTables* dev_muon_tables = nullptr;
  Muon::Constants::MatchWindows* dev_match_windows = nullptr;

  // Velo-UT-muon
  MatchUpstreamMuon::MuonChambers* dev_muonmatch_search_muon_chambers = nullptr;
  MatchUpstreamMuon::SearchWindows* dev_muonmatch_search_windows = nullptr;

  // Muon classification model constants
  Muon::Constants::FieldOfInterest* dev_muon_foi = nullptr;
  float* dev_muon_momentum_cuts = nullptr;
  int muon_catboost_n_trees;
  int* dev_muon_catboost_tree_depths = nullptr;
  int* dev_muon_catboost_tree_offsets = nullptr;
  int* dev_muon_catboost_split_features = nullptr;
  float* dev_muon_catboost_split_borders = nullptr;
  float* dev_muon_catboost_leaf_values = nullptr;
  int* dev_muon_catboost_leaf_offsets = nullptr;

  // Two track mva constants
  float* host_two_track_mva_weights = nullptr;
  float* host_two_track_mva_biases = nullptr;
  int* dev_two_track_mva_layer_sizes = nullptr;
  int dev_two_track_mva_n_layers = 0;
  float* dev_two_track_mva_monotone_constraints = nullptr;
  float dev_two_track_mva_lambda = 0;
  float dev_two_track_mva_nominal_cut = 0;

  // ElectronID mva constants
  float* host_electronid_mva_weights = nullptr;
  float* host_electronid_mva_biases = nullptr;
  int* dev_electronid_mva_layer_sizes = nullptr;
  int dev_electronid_mva_n_layers = 0;
  float* dev_electronid_mva_monotone_constraints = nullptr;
  float* dev_electronid_mva_min_rescales = nullptr;
  float* dev_electronid_mva_max_rescales = nullptr;
  float dev_electronid_mva_lambda = 0;
  float dev_electronid_mva_nominal_cut = 0;
  // MuonID mva constants
  float* host_muonid_mva_weights = nullptr;
  float* host_muonid_mva_biases = nullptr;
  int* dev_muonid_mva_layer_sizes = nullptr;
  int dev_muonid_mva_n_layers = 0;
  float* dev_muonid_mva_monotone_constraints = nullptr;
  float* dev_muonid_mva_min_rescales = nullptr;
  float* dev_muonid_mva_max_rescales = nullptr;
  float dev_muonid_mva_lambda = 0;
  float dev_muonid_mva_nominal_cut = 0;

  LookingForward::Constants* dev_looking_forward_constants = nullptr;

  // TrackMaching
  TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization = nullptr;

  // GhostKillers
  Allen::NeuralNetwork::Model::ForwardGhostKiller* dev_forward_ghost_killer = nullptr;
  Allen::NeuralNetwork::Model::MatchingGhostKiller* dev_matching_ghost_killer = nullptr;
  Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller* dev_matching_with_ut_ghost_killer = nullptr;
  Allen::NeuralNetwork::Model::MatchingWithUTV2GhostKiller* dev_matching_with_ut_v2_ghost_killer = nullptr;
  Allen::NeuralNetwork::Model::ForwardGhostKiller* dev_forward_no_ut_ghost_killer = nullptr;
  Allen::NeuralNetwork::Model::DownstreamGhostKiller* dev_downstream_ghost_killer = nullptr;

  // Downstream Utils
  Allen::NeuralNetwork::Model::TTrackSelector* dev_ttrack_selector = nullptr;
  Allen::NeuralNetwork::Model::DownstreaCompositeQuality* dev_downstream_composite_quality_evaluator = nullptr;

  // MVA selectors
  Allen::NeuralNetwork::Model::DownstreamLambdaSelector* dev_downstream_lambda_selector = nullptr;
  Allen::NeuralNetwork::Model::DownstreamKshortSelector* dev_downstream_kshort_selector = nullptr;
  Allen::NeuralNetwork::Model::DownstreamDetachedLambdaSelector* dev_downstream_detached_lambda_selector = nullptr;
  Allen::NeuralNetwork::Model::DownstreamDetachedKshortSelector* dev_downstream_detached_kshort_selector = nullptr;
  Allen::NeuralNetwork::Model::MatchingNoUTV2GhostKiller* dev_matching_no_ut_v2_ghost_killer = nullptr;

  // Kalman filter
  ParKalmanFilter::KalmanParametrizations* dev_kalman_params = nullptr;

  // Rich
  std::vector<char> host_rich_pdmdb_mapping;
  std::vector<char> host_rich_cable_mapping;
  char* dev_rich_pdmdb_mapping;
  char* dev_rich_cable_mapping;

  // UT per layer constant information
  UT::Constants::PerLayerInfo* host_ut_per_layer_info = nullptr;
  UT::Constants::PerLayerInfo* dev_ut_per_layer_info = nullptr;

  /**
   * @brief Reserves and initializes constants.
   */
  void reserve_and_initialize(
    const std::vector<float>& muon_field_of_interest_params,
    const std::string& param_file_location)
  {
    reserve_constants();
    initialize_constants(muon_field_of_interest_params, param_file_location);
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

  void initialize_two_track_mva_model_constants(
    const std::vector<float>& weights,
    const std::vector<float>& biases,
    const std::vector<int>& layer_sizes,
    const int n_layers,
    const std::vector<float>& monotone_constraints,
    float nominal_cut,
    float lambda);

  void initialize_electronid_mva_model_constants(
    const std::vector<float>& weights,
    const std::vector<float>& biases,
    const std::vector<int>& layer_sizes,
    const int n_layers,
    const std::vector<float>& monotone_constraints,
    const std::vector<float>& min_rescales,
    const std::vector<float>& max_rescales,
    float nominal_cut,
    float lambda);
  void initialize_muonid_mva_model_constants(
    const std::vector<float>& weights,
    const std::vector<float>& biases,
    const std::vector<int>& layer_sizes,
    const int n_layers,
    const std::vector<float>& monotone_constraints,
    const std::vector<float>& min_rescales,
    const std::vector<float>& max_rescales,
    float nominal_cut,
    float lambda);

  /**
   * @brief Initializes ghost killer constants.
   */
  void initialize_forward_no_ut_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_forward_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_matching_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_downstream_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_ttrack_selector_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_downstream_composite_quality_evaluator_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_downstream_kshort_selector_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_downstream_lambda_selector_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);

  void initialize_downstream_detached_kshort_selector_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_downstream_detached_lambda_selector_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);

  void initialize_matching_with_ut_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_matching_no_ut_v2_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
  void initialize_matching_with_ut_v2_ghostkiller_constants(
    const std::vector<float>& mean,
    const std::vector<float>& std,
    const std::vector<std::vector<float>>& weights1,
    const std::vector<float>& bias1,
    const std::vector<float>& weights2,
    const float& bias2);
};
