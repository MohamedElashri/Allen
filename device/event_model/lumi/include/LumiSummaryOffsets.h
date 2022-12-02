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
        SciFiClustersS3M45Offset = 128,
        SciFiClustersS3M45Size = 16,
        SciFiClustersOffset = 144,
        SciFiClustersSize = 16,
        SciFiClustersS2M123Offset = 160,
        SciFiClustersS2M123Size = 16,
        SciFiClustersS3M123Offset = 176,
        SciFiClustersS3M123Size = 16,
        ECalETOffset = 192,
        ECalETSize = 16,
        ECalEInnerTopOffset = 208,
        ECalEInnerTopSize = 16,
        ECalEMiddleTopOffset = 224,
        ECalEMiddleTopSize = 16,
        ECalEOuterTopOffset = 240,
        ECalEOuterTopSize = 16,
        ECalEInnerBottomOffset = 256,
        ECalEInnerBottomSize = 16,
        ECalEMiddleBottomOffset = 272,
        ECalEMiddleBottomSize = 16,
        ECalEOuterBottomOffset = 288,
        ECalEOuterBottomSize = 16,
        MuonHitsM2R1Offset = 304,
        MuonHitsM2R1Size = 16,
        MuonHitsM2R2Offset = 320,
        MuonHitsM2R2Size = 16,
        MuonHitsM2R3Offset = 336,
        MuonHitsM2R3Size = 16,
        VeloTracksOffset = 352,
        VeloTracksSize = 15,
        BCIDHighOffset = 367,
        BCIDHighSize = 14,
        BXTypeOffset = 381,
        BXTypeSize = 2,
        GECOffset = 383,
        GECSize = 1,
        SciFiClustersS1M45Offset = 384,
        SciFiClustersS1M45Size = 13,
        SciFiClustersS2M45Offset = 397,
        SciFiClustersS2M45Size = 13,
        VeloVerticesOffset = 410,
        VeloVerticesSize = 6,
        MuonHitsM2R4Offset = 416,
        MuonHitsM2R4Size = 11,
        MuonHitsM3R1Offset = 427,
        MuonHitsM3R1Size = 11,
        MuonHitsM3R2Offset = 438,
        MuonHitsM3R2Size = 10,
        MuonHitsM3R3Offset = 448,
        MuonHitsM3R3Size = 11,
        MuonHitsM3R4Offset = 459,
        MuonHitsM3R4Size = 11,
        MuonHitsM4R1Offset = 470,
        MuonHitsM4R1Size = 10,
        MuonHitsM4R2Offset = 480,
        MuonHitsM4R2Size = 11,
        MuonHitsM4R3Offset = 491,
        MuonHitsM4R3Size = 11,
        MuonHitsM4R4Offset = 502,
        MuonHitsM4R4Size = 10,
        VeloVertexXOffset = 512,
        VeloVertexXSize = 10,
        VeloVertexYOffset = 522,
        VeloVertexYSize = 10,
        VeloVertexZOffset = 532,
        VeloVertexZSize = 10,
        TotalSize = 544
      }; // enum CounterOffsets
    }    // namespace V2
  }      // namespace LumiSummaryOffsets
} // namespace LHCb
