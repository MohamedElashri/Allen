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

#include <iostream>

#include "MuonDefinitions.cuh"

namespace Allen {
  namespace LumiCounterOffsets {
    enum counterOffset : unsigned {
      // All values are in bits - the required size of the array may be determined
      // by dividing the largest offset by 8*sizeof(unsigned), i.e. 32, and rounding up.
      // Fields must be contained within a single element of the array, e.g. an
      // offset of 24 would allow for a maximum size of 8.
      /// ODIN info
      ODINStart = 0,
      t0LowSize = 32,
      t0LowOffset = ODINStart + 0, // event time offset low 32 bits
      t0HighSize = 32,
      t0HighOffset = ODINStart + t0LowSize, // event time offset high 32 bits
      bcidLowSize = 32,
      bcidLowOffset = ODINStart + t0LowSize + t0HighSize, // re-mapped bcid low 32 bits
      bcidHighSize = 14,
      bcidHighOffset = ODINStart + t0LowSize + t0HighSize + bcidLowSize, // re-mapped bcid high 14 bits
      bxTypeSize = 2,
      bxTypeOffset = ODINStart + t0LowSize + t0HighSize + bcidLowSize + bcidHighSize, // bunch crossing type
      ODINEnd = ODINStart + t0LowSize + t0HighSize + bcidLowSize + bcidHighSize + bxTypeSize,
      /// Global Event Cut
      GecStart = ODINEnd,
      GecSize = 1,
      GecOffset = GecStart,
      GecEnd = GecStart + GecSize,
      /// Velo counters
      VeloCountersStart = GecEnd,
      VeloTracksSize = 15,
      VeloTracksOffset = VeloCountersStart + 0, // number of Velo tracks
      VeloVerticesSize = 6,
      VeloVerticesOffset = VeloCountersStart + VeloTracksSize, // number of Velo vertices
      VeloCountersEnd = VeloCountersStart + VeloTracksSize + VeloVerticesSize,
      /// RICH counters
      RichCountersStart = VeloCountersEnd,
      RichCountersEnd = RichCountersStart + 0,
      /// SciFi counters
      SciFiCountersStart = RichCountersEnd,
      SciFiClustersSize = 15,
      SciFiClustersOffset = SciFiCountersStart + 0, // number of SciFi Clusters
      SciFiCountersEnd = SciFiCountersStart + SciFiClustersSize,
      /// CALO counters
      CaloCountersStart = SciFiCountersEnd,
      CaloCountersEnd = CaloCountersStart + 0,
      /// Muon counters
      MuonCountersStart = CaloCountersEnd,
      M2R2Size = 11,
      M2R2Offset = MuonCountersStart, // M2R2 hits
      M2R3Size = 11,
      M2R3Offset = MuonCountersStart + M2R2Size, // M2R3 hits
      M3R2Size = 11,
      M3R2Offset = MuonCountersStart + M2R2Size + M2R3Size, // M3R2 hits
      M3R3Size = 10,
      M3R3Offset = MuonCountersStart + M2R2Size + M2R3Size + M3R2Size, // M3R3 hits
      MuonCountersEnd = MuonCountersStart + M2R2Size + M2R3Size + M3R2Size + M3R3Size,
      /// the largest offset rounded up to the next multiple of 32
      TotalSize = ((MuonCountersEnd - 1) / 32 + 1) * 32
    }; // enum CounterOffsets

    enum muonStationRegionOffset : unsigned {
      M2R2 =
        MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        Muon::Constants::n_layouts * Muon::Constants::n_quarters,
      M2R3 =
        MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        2 * Muon::Constants::n_layouts * Muon::Constants::n_quarters,
      M2R4 =
        MatchUpstreamMuon::M2 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        3 * Muon::Constants::n_layouts * Muon::Constants::n_quarters,
      M3R2 =
        MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        Muon::Constants::n_layouts * Muon::Constants::n_quarters,
      M3R3 =
        MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        2 * Muon::Constants::n_layouts * Muon::Constants::n_quarters,
      M3R4 =
        MatchUpstreamMuon::M3 * Muon::Constants::n_layouts * Muon::Constants::n_regions * Muon::Constants::n_quarters +
        3 * Muon::Constants::n_layouts * Muon::Constants::n_quarters
    }; // enum muonStationRegionOffset
  }    // namespace LumiCounterOffsets
} // namespace Allen
