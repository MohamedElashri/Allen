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
#pragma once

#include <cstdint>

namespace LongTrack {
  // Parametrization from SciFiTrackForwarding.cpp , found to work better than FastMomentumEstimate.cpp
  // https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/SciFiTrackForwarding/src/SciFiTrackForwarding.cpp#L321
  //
  // @jzhuo (24/05/2024): update the same parametrization format with Sim10aU1 MinBias simulation (MD+MU),
  //                      the term related to txT^4 and tyV^4 are deprecated because it increase the
  //                      mean square error.
  __device__ inline float computeQoverP(
    const float txV,
    const float tyV,
    const float txT,
    const float magSign,
    const std::array<float, 16> momentum_parameters)
  {
    // Pick parametrisation from polarity condition
    // magSign is -1*dev_magnet_polarity so negative sign is MagUp
    const float* params = momentum_parameters.data() + (magSign < 0 ? 0 : 8);

    const auto dslope = txT - txV;
    const auto abs_p =
      params[0] + (params[1] + params[2] * (txT * txT) + params[3] * (txT * txT * txT * txT) + params[4] * (txT * txV) +
                   params[5] * (tyV * tyV) + params[6] * (tyV * tyV * tyV * tyV) + params[7] * (txV * txV)) /
                    fabsf(dslope);

    const auto charge = ((dslope > 0) ? 1.f : -1.f) * magSign;
    return charge / abs_p;
  }
} // namespace LongTrack