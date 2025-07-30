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

#include "MuonEventModel.cuh"

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
    static constexpr unsigned M5R1 =
      MatchUpstreamMuon::M5 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned MuonBankSize = Muon::Constants::n_layouts * Muon::Constants::n_stations *
                                             Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned n_muon_station_regions = 12u;

    static constexpr unsigned n_plume_channels = 32u;
    static constexpr unsigned n_plume_lumi_channels = 22u;

    static constexpr unsigned n_basic_counters = 6u;
    static constexpr unsigned n_velo_counters = 70u;
    static constexpr unsigned n_pv_counters = 15u;
    static constexpr unsigned n_pv_z_stored = 10u;
    static constexpr unsigned n_scifi_counters = 38u;
    static constexpr unsigned n_calo_counters = 8u;
    // 1u for muon tracks
    static constexpr unsigned n_muon_counters = n_muon_station_regions + 1u + Muon::Constants::maxTell40Number;
    static constexpr unsigned n_plume_counters = 79u;

    // number of velo eta bins edges
    static constexpr unsigned n_velo_eta_bin_edges = 7u;
    // number of velo counters requires reconstruction
    constexpr unsigned n_velo_reco_counters = 3u + n_velo_eta_bin_edges;
    constexpr unsigned n_velo_cluster_counters = n_velo_counters - n_velo_reco_counters;

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
                                                                         "VeloTracksEtaBin7",
                                                                         "VeloClustersInnerS00",
                                                                         "VeloClustersOuterS00",
                                                                         "VeloClustersInnerS01",
                                                                         "VeloClustersOuterS01",
                                                                         "VeloClustersInnerS02",
                                                                         "VeloClustersOuterS02",
                                                                         "VeloClustersInnerS03",
                                                                         "VeloClustersOuterS03",
                                                                         "VeloClustersInnerS04",
                                                                         "VeloClustersOuterS04",
                                                                         "VeloClustersInnerS05",
                                                                         "VeloClustersOuterS05",
                                                                         "VeloClustersInnerS06",
                                                                         "VeloClustersOuterS06",
                                                                         "VeloClustersInnerS07",
                                                                         "VeloClustersOuterS07",
                                                                         "VeloClustersInnerS08",
                                                                         "VeloClustersOuterS08",
                                                                         "VeloClustersInnerS09",
                                                                         "VeloClustersOuterS09",
                                                                         "VeloClustersInnerS10",
                                                                         "VeloClustersOuterS10",
                                                                         "VeloClustersInnerS11",
                                                                         "VeloClustersOuterS11",
                                                                         "VeloClustersInnerS12",
                                                                         "VeloClustersOuterS12",
                                                                         "VeloClustersInnerS13",
                                                                         "VeloClustersOuterS13",
                                                                         "VeloClustersInnerS14",
                                                                         "VeloClustersOuterS14",
                                                                         "VeloClustersInnerS15",
                                                                         "VeloClustersOuterS15",
                                                                         "VeloClustersInnerS16",
                                                                         "VeloClustersOuterS16",
                                                                         "VeloClustersInnerS17",
                                                                         "VeloClustersOuterS17",
                                                                         "VeloClustersInnerS18",
                                                                         "VeloClustersOuterS18",
                                                                         "VeloClustersInnerS19",
                                                                         "VeloClustersOuterS19",
                                                                         "VeloClustersInnerS20",
                                                                         "VeloClustersOuterS20",
                                                                         "VeloClustersInnerS21",
                                                                         "VeloClustersOuterS21",
                                                                         "VeloClustersInnerS22",
                                                                         "VeloClustersOuterS22",
                                                                         "VeloClustersInnerS23",
                                                                         "VeloClustersOuterS23",
                                                                         "VeloClustersInnerS24",
                                                                         "VeloClustersOuterS24",
                                                                         "VeloClustersInnerS25",
                                                                         "VeloClustersOuterS25",
                                                                         "VeloClustersInnerBin00",
                                                                         "VeloClustersOuterBin00",
                                                                         "VeloClustersInnerBin01",
                                                                         "VeloClustersOuterBin01",
                                                                         "VeloClustersInnerBin02",
                                                                         "VeloClustersOuterBin02",
                                                                         "VeloClustersInnerBin03",
                                                                         "VeloClustersOuterBin03"};
    const std::array<std::string, n_pv_counters> pv_counter_names = {"VeloVertices",
                                                                     "FiducialVeloVertices",
                                                                     "VeloVertexX",
                                                                     "VeloVertexY",
                                                                     "VeloVertexZ",
                                                                     "VeloVertexZ_00",
                                                                     "VeloVertexZ_01",
                                                                     "VeloVertexZ_02",
                                                                     "VeloVertexZ_03",
                                                                     "VeloVertexZ_04",
                                                                     "VeloVertexZ_05",
                                                                     "VeloVertexZ_06",
                                                                     "VeloVertexZ_07",
                                                                     "VeloVertexZ_08",
                                                                     "VeloVertexZ_09"};
    const std::array<std::string, n_scifi_counters> scifi_counter_names = {
      "SciFiT1M123",  "SciFiT2M123",  "SciFiT3M123",  "SciFiT1M4",    "SciFiT2M4",    "SciFiT3M45",   "SciFiT1Q02M0",
      "SciFiT1Q13M0", "SciFiT1Q02M1", "SciFiT1Q13M1", "SciFiT1Q02M2", "SciFiT1Q13M2", "SciFiT1Q02M3", "SciFiT1Q13M3",
      "SciFiT1Q02M4", "SciFiT1Q13M4", "SciFiT2Q02M0", "SciFiT2Q13M0", "SciFiT2Q02M1", "SciFiT2Q13M1", "SciFiT2Q02M2",
      "SciFiT2Q13M2", "SciFiT2Q02M3", "SciFiT2Q13M3", "SciFiT2Q02M4", "SciFiT2Q13M4", "SciFiT3Q02M0", "SciFiT3Q13M0",
      "SciFiT3Q02M1", "SciFiT3Q13M1", "SciFiT3Q02M2", "SciFiT3Q13M2", "SciFiT3Q02M3", "SciFiT3Q13M3", "SciFiT3Q02M4",
      "SciFiT3Q13M4", "SciFiT3Q02M5", "SciFiT3Q13M5"};
    const std::array<std::string, n_calo_counters> calo_counter_names = {"ECalET",
                                                                         "ECalEtot",
                                                                         "ECalETOuterTop",
                                                                         "ECalETMiddleTop",
                                                                         "ECalETInnerTop",
                                                                         "ECalETOuterBottom",
                                                                         "ECalETMiddleBottom",
                                                                         "ECalETInnerBottom"};
    const std::array<std::string, n_muon_counters> muon_counter_names = {
      "MuonHitsM2R1",   "MuonHitsM2R2",   "MuonHitsM2R3",   "MuonHitsM2R4",   "MuonHitsM3R1",   "MuonHitsM3R2",
      "MuonHitsM3R3",   "MuonHitsM3R4",   "MuonHitsM4R1",   "MuonHitsM4R2",   "MuonHitsM4R3",   "MuonHitsM4R4",
      "MuonTracks",     "MuonHitsTell01", "MuonHitsTell02", "MuonHitsTell03", "MuonHitsTell04", "MuonHitsTell05",
      "MuonHitsTell06", "MuonHitsTell07", "MuonHitsTell08", "MuonHitsTell09", "MuonHitsTell10", "MuonHitsTell11",
      "MuonHitsTell12", "MuonHitsTell13", "MuonHitsTell14", "MuonHitsTell15", "MuonHitsTell16", "MuonHitsTell17",
      "MuonHitsTell18", "MuonHitsTell19", "MuonHitsTell20", "MuonHitsTell21", "MuonHitsTell22"};
    const std::array<std::string, n_plume_counters> plume_counter_names = {
      "PlumeAvgLumiADC", "PlumeLumiOverthrLow", "PlumeLumiOverthrHigh", "PlumeLumiADC00", "PlumeLumiADC01",
      "PlumeLumiADC02",  "PlumeLumiADC03",      "PlumeLumiADC04",       "PlumeLumiADC05", "PlumeLumiADC06",
      "PlumeLumiADC07",  "PlumeLumiADC08",      "PlumeLumiADC09",       "PlumeLumiADC10", "PlumeLumiADC11",
      "PlumeLumiADC12",  "PlumeLumiADC13",      "PlumeLumiADC14",       "PlumeLumiADC15", "PlumeLumiADC16",
      "PlumeLumiADC17",  "PlumeLumiADC18",      "PlumeLumiADC19",       "PlumeLumiADC20", "PlumeLumiADC21",
      "PlumeLumiADC22",  "PlumeLumiADC23",      "PlumeLumiADC24",       "PlumeLumiADC25", "PlumeLumiADC26",
      "PlumeLumiADC27",  "PlumeLumiADC28",      "PlumeLumiADC29",       "PlumeLumiADC30", "PlumeLumiADC31",
      "PlumeLumiADC32",  "PlumeLumiADC33",      "PlumeLumiADC34",       "PlumeLumiADC35", "PlumeLumiADC36",
      "PlumeLumiADC37",  "PlumeLumiADC38",      "PlumeLumiADC39",       "PlumeLumiADC40", "PlumeLumiADC41",
      "PlumeLumiADC42",  "PlumeLumiADC43",      "PlumeTiming00",        "PlumeTiming01",  "PlumeTiming02",
      "PlumeTiming03",   "PlumeTiming04",       "PlumeTiming05",        "PlumeTiming06",  "PlumeTiming07",
      "PlumeTiming08",   "PlumeTiming09",       "PlumeTiming10",        "PlumeTiming11",  "PlumeTiming12",
      "PlumeTiming13",   "PlumeTiming14",       "PlumeTiming15",        "PlumeTiming16",  "PlumeTiming17",
      "PlumeTiming18",   "PlumeTiming19",       "PlumeTiming20",        "PlumeTiming21",  "PlumeTiming22",
      "PlumeTiming23",   "PlumeTiming24",       "PlumeTiming25",        "PlumeTiming26",  "PlumeTiming27",
      "PlumeTiming28",   "PlumeTiming29",       "PlumeTiming30",        "PlumeTiming31"};

  } // namespace Constants

  struct LumiInfo {
    unsigned size;
    unsigned offset;
    unsigned value;
  };
} // namespace Lumi
