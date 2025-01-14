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
#include "Constants.cuh"
#include "UTDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "ClusteringDefinitions.cuh"
#include "KalmanParametrizations.cuh"
#include "LookingForwardConstants.cuh"
#include "TrackMatchingConstants.cuh"
#include "MuonEventModel.cuh"
#include "MuonGeometry.cuh"
#include "MuonTables.cuh"

void Constants::reserve_constants()
{
  Allen::malloc((void**) &dev_inv_clus_res, host_inv_clus_res.size() * sizeof(float));
  Allen::malloc((void**) &dev_kalman_params, sizeof(ParKalmanFilter::KalmanParametrizations));
  Allen::malloc((void**) &dev_looking_forward_constants, sizeof(LookingForward::Constants));
  Allen::malloc((void**) &dev_magnet_parametrization, sizeof(TrackMatchingConsts::MagnetParametrization));
  Allen::malloc((void**) &dev_muon_foi, sizeof(Muon::Constants::FieldOfInterest));
  Allen::malloc((void**) &dev_muon_momentum_cuts, 3 * sizeof(float));
  Allen::malloc((void**) &dev_muonmatch_search_muon_chambers, sizeof(MatchUpstreamMuon::MuonChambers));
  Allen::malloc((void**) &dev_muonmatch_search_windows, sizeof(MatchUpstreamMuon::SearchWindows));
  Allen::malloc((void**) &dev_match_windows, sizeof(Muon::Constants::MatchWindows));

  host_ut_region_offsets.resize(UT::Constants::n_layers * UT::Constants::n_regions_in_layer + 1);
  host_ut_dxDy.resize(UT::Constants::n_layers);
  host_unique_x_sector_layer_offsets.resize(UT::Constants::n_layers + 1);
}

void Constants::initialize_constants(
  const std::vector<float>& muon_field_of_interest_params,
  const std::string& param_file_location)
{
  // SciFi constants
  host_inv_clus_res = {1 / 0.05, 1 / 0.08, 1 / 0.11, 1 / 0.14, 1 / 0.17, 1 / 0.20, 1 / 0.23, 1 / 0.26, 1 / 0.29};
  Allen::memcpy(
    dev_inv_clus_res, &host_inv_clus_res, host_inv_clus_res.size() * sizeof(float), Allen::memcpyHostToDevice);

  host_looking_forward_constants = new LookingForward::Constants {};

  // Kalman filter constants.
  ParKalmanFilter::KalmanParametrizations host_kalman_params;
  host_kalman_params.SetParameters(param_file_location, ParKalmanFilter::Polarity::Down);
  Allen::memcpy(
    dev_kalman_params, &host_kalman_params, sizeof(ParKalmanFilter::KalmanParametrizations), Allen::memcpyHostToDevice);

  Allen::memcpy(
    dev_looking_forward_constants,
    host_looking_forward_constants,
    sizeof(LookingForward::Constants),
    Allen::memcpyHostToDevice);

  // Track matching constants
  host_magnet_parametrization = new TrackMatchingConsts::MagnetParametrization {};
  Allen::memcpy(
    dev_magnet_parametrization,
    host_magnet_parametrization,
    sizeof(TrackMatchingConsts::MagnetParametrization),
    Allen::memcpyHostToDevice);

  // Muon constants
  Muon::Constants::FieldOfInterest host_muon_foi;
  std::copy_n(
    muon_field_of_interest_params.data(),
    Muon::Constants::n_regions * Muon::Constants::n_stations * Muon::Constants::FoiParams::n_parameters *
      Muon::Constants::FoiParams::n_coordinates,
    host_muon_foi.params_begin());

  Allen::memcpy(dev_muon_momentum_cuts, &Muon::Constants::momentum_cuts, 3 * sizeof(float), Allen::memcpyHostToDevice);
  Allen::memcpy(dev_muon_foi, &host_muon_foi, sizeof(Muon::Constants::FieldOfInterest), Allen::memcpyHostToDevice);

  // VeloMuon
  Muon::Constants::MatchWindows host_match_windows;
  Allen::memcpy(
    dev_match_windows, &host_match_windows, sizeof(Muon::Constants::MatchWindows), Allen::memcpyHostToDevice);

  // Velo-UT-muon
  MatchUpstreamMuon::MuonChambers host_muonmatch_search_muon_chambers;
  MatchUpstreamMuon::SearchWindows host_muonmatch_search_windows;
  Allen::memcpy(
    dev_muonmatch_search_muon_chambers,
    &host_muonmatch_search_muon_chambers,
    sizeof(MatchUpstreamMuon::MuonChambers),
    Allen::memcpyHostToDevice);

  Allen::memcpy(
    dev_muonmatch_search_windows,
    &host_muonmatch_search_windows,
    sizeof(MatchUpstreamMuon::SearchWindows),
    Allen::memcpyHostToDevice);
}