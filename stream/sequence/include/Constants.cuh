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
  struct KalmanParametrizationsStruct;
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
  struct UTLayerGeometry;
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

  // Velo related
  VeloGeometry* dev_velo_geometry = nullptr;

  // UT related
  std::vector<char> host_ut_geometry;
  std::vector<char> host_ut_boards;
  std::vector<uint16_t> host_ut_board_geometry_map;
  std::vector<uint8_t> host_ut_board_to_sector_group_map;
  std::vector<unsigned> host_ut_sector_to_group_map;

  gsl::span<char> dev_ut_geometry;
  gsl::span<char> dev_ut_boards;
  gsl::span<uint16_t> dev_ut_board_geometry_map;
  gsl::span<uint8_t> dev_ut_board_to_sector_group_map;
  gsl::span<unsigned> dev_ut_sector_to_group_map;

  UTMagnetTool* dev_ut_magnet_tool = nullptr;

  UT::Constants::UTLayerGeometry* host_ut_layer_geometry = nullptr;
  UT::Constants::UTLayerGeometry* dev_ut_layer_geometry = nullptr;

  // SciFi
  char* dev_scifi_geometry = nullptr;
  std::vector<char> host_scifi_geometry;
  std::array<float, 9> host_inv_clus_res;
  float* dev_inv_clus_res;

  // Beam location
  std::vector<float> host_beamline;

  // Beam location
  std::vector<float> host_gen_crossing_angles;

  // Magnet polarity
  gsl::span<float> dev_magnet_polarity;
  std::vector<float> host_magnet_polarity;

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

  LookingForward::Constants* dev_looking_forward_constants = nullptr;

  // TrackMaching
  TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization = nullptr;

  // Kalman filter
  ParKalmanFilter::KalmanParametrizationsStruct* dev_kalman_params = nullptr;

  float* host_VP_pars_MD = nullptr;
  float* host_VPUT_pars_MD = nullptr;
  float* host_UT_pars_MD = nullptr;
  float* host_T_pars_MD = nullptr;
  float* host_TFT_pars_MD = nullptr;
  float* host_UTTF_pars_MD = nullptr;
  float* host_VP_pars_MU = nullptr;
  float* host_VPUT_pars_MU = nullptr;
  float* host_UT_pars_MU = nullptr;
  float* host_T_pars_MU = nullptr;
  float* host_UTT_META_MU = nullptr;
  float* host_TFT_pars_MU = nullptr;
  float* host_UTTF_pars_MU = nullptr;
  float* host_UT_Layers = nullptr;
  float* host_T_Layers = nullptr;
  float* host_UTT_META_MD = nullptr;

  // Rich
  std::vector<char> host_rich_pdmdb_mapping;
  std::vector<char> host_rich_cable_mapping;
  char* dev_rich_pdmdb_mapping;
  char* dev_rich_cable_mapping;

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

  void initialize_kalman_pars_constants(
    const std::vector<float>& VP_pars_MD,
    const std::vector<float>& VPUT_pars_MD,
    const std::vector<float>& UT_pars_MD,
    const std::vector<float>& T_pars_MD,
    const std::vector<float>& TFT_pars_MD,
    const std::vector<float>& UTTF_pars_MD,
    const std::vector<float>& VP_pars_MU,
    const std::vector<float>& VPUT_pars_MU,
    const std::vector<float>& UT_pars_MU,
    const std::vector<float>& T_pars_MU,
    const std::vector<float>& TFT_pars_MU,
    const std::vector<float>& UTTF_pars_MU,
    const std::vector<float>& UT_Layers,
    const std::vector<float>& T_Layers,
    const std::vector<float>& UTT_META_MD,
    const std::vector<float>& UTT_META_MU);
};
