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

#include <Event/LumiSummaryOffsets_V2.h>
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

    static constexpr unsigned n_velo_counters = 1u;
    static constexpr unsigned n_pv_counters = 1u;
    static constexpr unsigned n_SciFi_counters = 6u;
    static constexpr unsigned n_calo_counters = 7u;
    static constexpr unsigned n_muon_counters = 12u;

    // give the length of a lumi summary in unsigned
    static constexpr unsigned lumi_length = LHCb::LumiSummaryOffsets::V2::TotalSize / 8u / sizeof(unsigned);
  } // namespace Constants

  struct LumiInfo {
    LHCb::LumiSummaryOffsets::V2::counterOffsets size;
    LHCb::LumiSummaryOffsets::V2::counterOffsets offset;
    unsigned value;
  };
} // namespace Lumi
