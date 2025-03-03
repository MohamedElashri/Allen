/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "DownstreamConstants.cuh"

namespace Downstream {
  namespace DownstreamEnums {
    enum LayerInfo : uint8_t {
      X0 = 0b0000'0001,
      U1 = 0b0000'0010,
      V2 = 0b0000'0100,
      X3 = 0b0000'1000,
      UV = 0b0000'0110
    };

    __device__ constexpr uint8_t layer_masks[4] = {X0, U1, V2, X3};
  } // namespace DownstreamEnums

  namespace DownstreamStructs {

    //
    // Selected seeds
    //
    struct SelectedSciFiTrack {
      unsigned scifi_idx;
      float tx, ty, y, chi2, xMagnet, zMagnet;
    };

    //
    // Candidate extrapolation data
    //
    struct ExtrapolationData {
      float xMagnet, yMagnet, zMagnet, tx, ty, qop;
    };

    //
    // UV hits CandidateCache
    //
    struct CandidateCache {
      ushort uhits[2], vhits[2];
      float uscores[2], vscores[2];
    };

    //
    // Output
    //
    struct DownstreamHits {
      constexpr static ushort INVALID_HIT = std::numeric_limits<ushort>::max();
      ushort hits[4];
      float score;
    };
  } // namespace DownstreamStructs
} // namespace Downstream