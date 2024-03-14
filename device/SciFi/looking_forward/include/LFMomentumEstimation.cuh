
/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "BackendCommon.h"
#include "LookingForwardConstants.cuh"

namespace LookingForward::MomentumEstimation {
  __device__ inline float qop_calculation(
    LookingForward::Constants const* dev_looking_forward_constants,
    float const magSign,
    float const z0SciFi,
    float const x0SciFi,
    float const y0SciFi,
    float const xVelo,
    float const yVelo,
    float const zVelo,
    float const txO,
    float const tyO,
    float const txSciFi,
    float const tySciFi)
  {
    const auto zMatch = (x0SciFi - xVelo + txO * zVelo - txSciFi * z0SciFi) / (txO - txSciFi);
    const auto xMatch = xVelo + txO * (zMatch - zVelo);
    const auto yMatch = yVelo + tyO * (zMatch - zVelo);
    const auto xVelo_at0 = xVelo - txO * zVelo;
    const auto yVelo_at0 = yVelo - tyO * zVelo;
    const auto FLIGHTPATH_MAGNET_SCI_SQ = (x0SciFi - xMatch) * (x0SciFi - xMatch) +
                                          (y0SciFi - yMatch) * (y0SciFi - yMatch) +
                                          (z0SciFi - zMatch) * (z0SciFi - zMatch);
    const auto FLIGHTPATH_VELO_MAGNET_SQ =
      (xVelo_at0 - xMatch) * (xVelo_at0 - xMatch) + (yVelo_at0 - yMatch) * (yVelo_at0 - yMatch) + zMatch * zMatch;
    const auto FLIGHTPATH = 0.001f * sqrtf(FLIGHTPATH_MAGNET_SCI_SQ + FLIGHTPATH_VELO_MAGNET_SQ);
    const auto MAGFIELD = FLIGHTPATH * cosf(asinf(tyO));
    const auto DSLOPE =
      txSciFi / (sqrtf(1.f + txSciFi * txSciFi + tySciFi * tySciFi)) - txO / (sqrtf(1.f + txO * txO + tyO * tyO));

    const auto txO2 = txO * txO;
    const auto txO3 = txO * txO * txO;
    const auto txO4 = txO * txO * txO * txO;
    const auto txO5 = txO * txO * txO * txO * txO;
    const auto txO6 = txO * txO * txO * txO * txO * txO;
    const auto txO7 = txO * txO * txO * txO * txO * txO * txO;
    const auto tyO2 = tyO * tyO;
    const auto tyO4 = tyO * tyO * tyO * tyO;
    const auto tyO5 = tyO * tyO * tyO * tyO * tyO;
    const auto tyO6 = tyO * tyO * tyO * tyO * tyO * tyO;

    const auto C0 = dev_looking_forward_constants->C0[0] + dev_looking_forward_constants->C0[1] * txO2 +
                    dev_looking_forward_constants->C0[2] * txO4 + dev_looking_forward_constants->C0[3] * tyO2 +
                    dev_looking_forward_constants->C0[4] * tyO4 + dev_looking_forward_constants->C0[5] * txO2 * tyO2 +
                    dev_looking_forward_constants->C0[6] * txO6 + dev_looking_forward_constants->C0[7] * tyO5 +
                    dev_looking_forward_constants->C0[8] * txO4 * tyO2 +
                    dev_looking_forward_constants->C0[9] * txO2 * tyO4;
    const auto C1 =
      dev_looking_forward_constants->C1[0] + dev_looking_forward_constants->C1[1] * txO +
      dev_looking_forward_constants->C1[2] * txO3 + dev_looking_forward_constants->C1[3] * txO5 +
      dev_looking_forward_constants->C1[4] * txO7 + dev_looking_forward_constants->C1[5] * tyO2 +
      dev_looking_forward_constants->C1[6] * tyO4 + dev_looking_forward_constants->C1[7] * tyO6 +
      dev_looking_forward_constants->C1[8] * txO * tyO2 + dev_looking_forward_constants->C1[9] * txO * tyO4 +
      dev_looking_forward_constants->C1[10] * txO * tyO6 + dev_looking_forward_constants->C1[11] * txO3 * tyO2 +
      dev_looking_forward_constants->C1[12] * txO3 * tyO4 + dev_looking_forward_constants->C1[13] * txO5 * tyO2;
    const auto C2 = dev_looking_forward_constants->C2[0] + dev_looking_forward_constants->C2[1] * txO2 +
                    dev_looking_forward_constants->C2[2] * txO4 + dev_looking_forward_constants->C2[3] * tyO2 +
                    dev_looking_forward_constants->C2[4] * tyO4 + dev_looking_forward_constants->C2[5] * txO2 * tyO2 +
                    dev_looking_forward_constants->C2[6] * txO6 + dev_looking_forward_constants->C2[7] * tyO5 +
                    dev_looking_forward_constants->C2[8] * txO4 * tyO2 +
                    dev_looking_forward_constants->C2[9] * txO2 * tyO4;
    const auto C3 =
      dev_looking_forward_constants->C3[0] + dev_looking_forward_constants->C3[1] * txO +
      dev_looking_forward_constants->C3[2] * txO3 + dev_looking_forward_constants->C3[3] * txO5 +
      dev_looking_forward_constants->C3[4] * txO7 + dev_looking_forward_constants->C3[5] * tyO2 +
      dev_looking_forward_constants->C3[6] * tyO4 + dev_looking_forward_constants->C3[7] * tyO6 +
      dev_looking_forward_constants->C3[8] * txO * tyO2 + dev_looking_forward_constants->C3[9] * txO * tyO4 +
      dev_looking_forward_constants->C3[10] * txO * tyO6 + dev_looking_forward_constants->C3[11] * txO3 * tyO2 +
      dev_looking_forward_constants->C3[12] * txO3 * tyO4 + dev_looking_forward_constants->C3[13] * txO5 * tyO2;
    const auto C4 = dev_looking_forward_constants->C4[0] + dev_looking_forward_constants->C4[1] * txO2 +
                    dev_looking_forward_constants->C4[2] * txO4 + dev_looking_forward_constants->C4[3] * tyO2 +
                    dev_looking_forward_constants->C4[4] * tyO4 + dev_looking_forward_constants->C4[5] * txO2 * tyO2 +
                    dev_looking_forward_constants->C4[6] * txO6 + dev_looking_forward_constants->C4[7] * tyO5 +
                    dev_looking_forward_constants->C4[8] * txO4 * tyO2 +
                    dev_looking_forward_constants->C4[9] * txO2 * tyO4;

    const auto MAGFIELD_updated = MAGFIELD * magSign *
                                  (C0 + C1 * DSLOPE + C2 * DSLOPE * DSLOPE + C3 * DSLOPE * DSLOPE * DSLOPE +
                                   C4 * DSLOPE * DSLOPE * DSLOPE * DSLOPE);
    const auto qop = DSLOPE / MAGFIELD_updated;
    return qop;
  }
} // namespace LookingForward::MomentumEstimation
