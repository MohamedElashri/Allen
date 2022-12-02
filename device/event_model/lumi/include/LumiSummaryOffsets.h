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
        ECalEInnerTopOffset = 128,
        ECalEInnerTopSize = 22,
        VeloVertexXOffset = 150,
        VeloVertexXSize = 10,
        ECalEInnerBottomOffset = 160,
        ECalEInnerBottomSize = 22,
        VeloVertexYOffset = 182,
        VeloVertexYSize = 10,
        ECalETOffset = 192,
        ECalETSize = 21,
        VeloTracksOffset = 213,
        VeloTracksSize = 11,
        ECalEMiddleTopOffset = 224,
        ECalEMiddleTopSize = 21,
        SciFiClustersS3M45Offset = 245,
        SciFiClustersS3M45Size = 11,
        ECalEOuterTopOffset = 256,
        ECalEOuterTopSize = 21,
        VeloVertexZOffset = 277,
        VeloVertexZSize = 10,
        GECOffset = 287,
        GECSize = 1,
        ECalEMiddleBottomOffset = 288,
        ECalEMiddleBottomSize = 21,
        SciFiClustersS1M45Offset = 309,
        SciFiClustersS1M45Size = 10,
        ECalEOuterBottomOffset = 320,
        ECalEOuterBottomSize = 21,
        SciFiClustersS2M45Offset = 341,
        SciFiClustersS2M45Size = 10,
        BCIDHighOffset = 352,
        BCIDHighSize = 14,
        SciFiClustersOffset = 366,
        SciFiClustersSize = 13,
        BXTypeOffset = 379,
        BXTypeSize = 2,
        SciFiClustersS2M123Offset = 384,
        SciFiClustersS2M123Size = 13,
        SciFiClustersS3M123Offset = 397,
        SciFiClustersS3M123Size = 13,
        VeloVerticesOffset = 410,
        VeloVerticesSize = 6,
        MuonHitsM2R1Offset = 416,
        MuonHitsM2R1Size = 10,
        MuonHitsM2R2Offset = 426,
        MuonHitsM2R2Size = 10,
        MuonHitsM2R3Offset = 436,
        MuonHitsM2R3Size = 9,
        MuonHitsM3R1Offset = 448,
        MuonHitsM3R1Size = 9,
        MuonHitsM4R3Offset = 457,
        MuonHitsM4R3Size = 9,
        MuonHitsM2R4Offset = 466,
        MuonHitsM2R4Size = 8,
        MuonHitsM3R2Offset = 480,
        MuonHitsM3R2Size = 8,
        MuonHitsM3R3Offset = 488,
        MuonHitsM3R3Size = 8,
        MuonHitsM4R1Offset = 496,
        MuonHitsM4R1Size = 8,
        MuonHitsM4R4Offset = 504,
        MuonHitsM4R4Size = 8,
        MuonHitsM3R4Offset = 512,
        MuonHitsM3R4Size = 7,
        MuonHitsM4R2Offset = 519,
        MuonHitsM4R2Size = 7,
        TotalSize = 544
      }; // enum CounterOffsets
    }    // namespace V2
  }      // namespace LumiSummaryOffsets
} // namespace LHCb
