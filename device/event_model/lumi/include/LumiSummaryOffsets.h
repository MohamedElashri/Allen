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

namespace LHCb {
  namespace LumiSummaryOffsets {
    namespace V2 {
      enum counterOffsets : unsigned {
        // All values are in bits - the required size of the array may be determined
        // by dividing the largest offset by 8*sizeof(unsigned), i.e. 32, and rounding up.
        // Fields must be contained within a single element of the array, e.g. an
        // offset of 24 would allow for a maximum size of 8.
        // The encoding key stores a hash of the JSON representation of all counter offsets and sizes.
        // If a non-default encoding key is present, then all other counters should be decoded using
        // the scheme stored in the ANN for that key rather than the default values in this header.
        encodingKeyOffset = 0,
        encodingKeySize = 32,
        T0LowOffset = 32,
        T0LowSize = 32,
        T0HighOffset = 64,
        T0HighSize = 32,
        BCIDLowOffset = 96,
        BCIDLowSize = 32,
        PlumeLumiOverthrLowOffset = 128,
        PlumeLumiOverthrLowSize = 22,
        MuonHitsM3R2Offset = 150,
        MuonHitsM3R2Size = 10,
        PlumeLumiOverthrHighOffset = 160,
        PlumeLumiOverthrHighSize = 22,
        MuonHitsM4R1Offset = 182,
        MuonHitsM4R1Size = 10,
        SciFiClustersS3M45Offset = 192,
        SciFiClustersS3M45Size = 16,
        SciFiClustersOffset = 208,
        SciFiClustersSize = 16,
        SciFiClustersS2M123Offset = 224,
        SciFiClustersS2M123Size = 16,
        SciFiClustersS3M123Offset = 240,
        SciFiClustersS3M123Size = 16,
        ECalETOffset = 256,
        ECalETSize = 16,
        ECalEInnerTopOffset = 272,
        ECalEInnerTopSize = 16,
        ECalEMiddleTopOffset = 288,
        ECalEMiddleTopSize = 16,
        ECalEOuterTopOffset = 304,
        ECalEOuterTopSize = 16,
        ECalEInnerBottomOffset = 320,
        ECalEInnerBottomSize = 16,
        ECalEMiddleBottomOffset = 336,
        ECalEMiddleBottomSize = 16,
        ECalEOuterBottomOffset = 352,
        ECalEOuterBottomSize = 16,
        MuonHitsM2R1Offset = 368,
        MuonHitsM2R1Size = 16,
        MuonHitsM2R2Offset = 384,
        MuonHitsM2R2Size = 16,
        MuonHitsM2R3Offset = 400,
        MuonHitsM2R3Size = 16,
        VeloTracksOffset = 416,
        VeloTracksSize = 15,
        BCIDHighOffset = 431,
        BCIDHighSize = 14,
        BXTypeOffset = 445,
        BXTypeSize = 2,
        GECOffset = 447,
        GECSize = 1,
        SciFiClustersS1M45Offset = 448,
        SciFiClustersS1M45Size = 13,
        SciFiClustersS2M45Offset = 461,
        SciFiClustersS2M45Size = 13,
        VeloVerticesOffset = 474,
        VeloVerticesSize = 6,
        PlumeAvgLumiADCOffset = 480,
        PlumeAvgLumiADCSize = 12,
        MuonHitsM2R4Offset = 492,
        MuonHitsM2R4Size = 11,
        MuonHitsM3R1Offset = 512,
        MuonHitsM3R1Size = 11,
        MuonHitsM3R3Offset = 523,
        MuonHitsM3R3Size = 11,
        MuonHitsM4R4Offset = 534,
        MuonHitsM4R4Size = 10,
        MuonHitsM3R4Offset = 544,
        MuonHitsM3R4Size = 11,
        MuonHitsM4R2Offset = 555,
        MuonHitsM4R2Size = 11,
        MuonHitsM4R3Offset = 576,
        MuonHitsM4R3Size = 11,
        TotalSize = 608
      }; // enum CounterOffsets
    }    // namespace V2
  }      // namespace LumiSummaryOffsets
} // namespace LHCb
