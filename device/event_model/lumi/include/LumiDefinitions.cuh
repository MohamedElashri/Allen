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
    static constexpr unsigned M5R1 =
      MatchUpstreamMuon::M5 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned MuonBankSize = Muon::Constants::n_layouts * Muon::Constants::n_stations *
                                             Muon::Constants::n_regions * Muon::Constants::n_quarters;
    static constexpr unsigned n_muon_station_regions = 12u;

    static constexpr unsigned n_plume_channels = 32u;
    static constexpr unsigned n_plume_lumi_channels = 22u;

    static constexpr unsigned n_basic_counters = 6u;
    static constexpr unsigned n_velo_counters = 10u;
    static constexpr unsigned n_pv_counters = 5u;
    static constexpr unsigned n_scifi_counters = 38u;
    static constexpr unsigned n_calo_counters = 8u;
    static constexpr unsigned n_muon_counters = 13u;
    static constexpr unsigned n_plume_counters = 47u;

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
                                                                         "MuonHitsM4R4",
                                                                         "MuonTracks"};
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
      "PlumeLumiADC42",  "PlumeLumiADC43"};
  } // namespace Constants

  struct LumiInfo {
    unsigned size;
    unsigned offset;
    unsigned value;
  };
} // namespace Lumi
