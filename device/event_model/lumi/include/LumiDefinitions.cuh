/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "MuonDefinitions.cuh"

namespace Lumi {
  namespace Constants {
    // muon banks offsets, used to calculate muon clusters
    static constexpr unsigned M2R1 =
      MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned M2R2 =
      MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M2R3 =
      MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      2 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M2R4 =
      MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      3 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M3R1 =
      MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned M3R2 =
      MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M3R3 =
      MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      2 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M3R4 =
      MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      3 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M4R1 =
      MatchUpstreamMuon::M4 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned M4R2 =
      MatchUpstreamMuon::M4 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M4R3 =
      MatchUpstreamMuon::M4 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      2 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned M4R4 =
      MatchUpstreamMuon::M4 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
      3 * Muon::Constants::n_layouts * Muon::Constants::n_quarters;
    static constexpr unsigned MuonBankSize = Muon::Constants::n_layouts * Muon::Constants::n_stations *
                                             Muon::Constants::n_regions * Muon::Constants::n_quarters;

    static constexpr unsigned n_plume_channels = 32u;
    static constexpr unsigned n_plume_lumi_channels = 22u;

    static constexpr unsigned n_basic_counters = 6u;
    static constexpr unsigned n_velo_counters = 10u;
    static constexpr unsigned n_pv_counters = 5u;
    static constexpr unsigned n_scifi_counters = 6u;
    static constexpr unsigned n_calo_counters = 8u;
    static constexpr unsigned n_muon_counters = 12u;
    static constexpr unsigned n_plume_counters = 3u;

    // number of velo eta bins edges
    static constexpr unsigned n_velo_eta_bin_edges = 7u;

    // number of sub info, used for info aggregating in make_lumi_summary
    static constexpr unsigned n_sub_infos = 6u;

    const std::array<std::string, n_basic_counters> basic_counter_names =
      {"T0Low", "T0High", "BCIDLow", "BCIDHigh", "BXType", "GEC"};
    const std::array<std::string, n_velo_counters> velo_counter_names = {"VeloTracks",
                                                                         "VeloFiducialTracks",
                                                                         "VeloTracksEtaBin0",
                                                                         "VeloTracksEtaBin1",
                                                                         "VeloTracksEtaBin2",
                                                                         "VeloTracksEtaBin3",
                                                                         "VeloTracksEtaBin4",
                                                                         "VeloTracksEtaBin5",
                                                                         "VeloTracksEtaBin6",
                                                                         "VeloTracksEtaBin7"};
    const std::array<std::string, n_pv_counters> pv_counter_names = {"VeloVertices",
                                                                     "FiducialVeloVertices",
                                                                     "VeloVertexX",
                                                                     "VeloVertexY",
                                                                     "VeloVertexZ"};
    const std::array<std::string, n_scifi_counters> scifi_counter_names = {"SciFiClusters",
                                                                           "SciFiClustersS2M123",
                                                                           "SciFiClustersS3M123",
                                                                           "SciFiClustersS1M45",
                                                                           "SciFiClustersS2M45",
                                                                           "SciFiClustersS3M45"};
    const std::array<std::string, n_calo_counters> calo_counter_names = {"ECalET",
                                                                         "ECalEtot",
                                                                         "ECalETOuterTop",
                                                                         "ECalETMiddleTop",
                                                                         "ECalETInnerTop",
                                                                         "ECalETOuterBottom",
                                                                         "ECalETMiddleBottom",
                                                                         "ECalETInnerBottom"};
    const std::array<std::string, n_muon_counters> muon_counter_names = {"MuonHitsM2R1",
                                                                         "MuonHitsM2R2",
                                                                         "MuonHitsM2R3",
                                                                         "MuonHitsM2R4",
                                                                         "MuonHitsM3R1",
                                                                         "MuonHitsM3R2",
                                                                         "MuonHitsM3R3",
                                                                         "MuonHitsM3R4",
                                                                         "MuonHitsM4R1",
                                                                         "MuonHitsM4R2",
                                                                         "MuonHitsM4R3",
                                                                         "MuonHitsM4R4"};
    const std::array<std::string, n_plume_counters> plume_counter_names = {"PlumeAvgLumiADC",
                                                                           "PlumeLumiOverthrLow",
                                                                           "PlumeLumiOverthrHigh"};
  } // namespace Constants

  struct LumiInfo {
    unsigned size;
    unsigned offset;
    unsigned value;
  };
} // namespace Lumi
