/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "States.cuh"
#include "BackendCommon.h"

namespace Downstream::Extrapolation {
  __device__ __host__ inline float get_zMagnet(const MiniState& scifi_state)
  {
    const float tx = scifi_state.tx();
    const float ty = scifi_state.ty();
    const float x = scifi_state.x();
    const float y = scifi_state.y();
    const float z = scifi_state.z();

    const float params[4] = {-6.34025f, -4.85287f, -12.4491f, 4.25461e-08f};
    const float x0 = x - tx * z;
    const float p = params[0] + params[1] * tx * tx + params[2] * ty * ty + params[3] * x0 * x0;
    const float invp = 1.f / (p * 1e6f);

    return (5.362780E+03f) + (1.028418E+04f) * invp + (-3.878377E+08f) * invp * invp + (4.366723E-03f) * fabsf(x) +
           (-1.904676E-05f) * fabsf(x) * fabsf(x) + (1.057300E-01f) * fabsf(y) +
           (-8.798887E-05f) * fabsf(y) * fabsf(y) + (3.358789E+01f) * fabsf(tx) +
           (8.376555E+02f) * fabsf(tx) * fabsf(tx) + (-7.903139E+02f) * fabsf(ty) +
           (4.627501E+03f) * fabsf(ty) * fabsf(ty);
  };

  __device__ __host__ inline float3 get_MagnetPoint(const MiniState& scifi_state)
  {
    float3 res;
    res.z = get_zMagnet(scifi_state);
    res.x = scifi_state.xAt(res.z);
    res.y = scifi_state.yAt(res.z);
    return res;
  };

  __device__ __host__ inline float
  get_qop(const float tx, const float ty, const float scifi_tx, const float magnet_polarity)
  {
    const auto dslope = scifi_tx - tx;
    const auto abs_p =
      (2.011328E+01f) +
      ((1.208754E+03f) + (5.222969E+02f) * (scifi_tx * scifi_tx) +
       (8.131686E+01f) * (scifi_tx * scifi_tx * scifi_tx * scifi_tx) + (5.099099E+02f) * (scifi_tx * tx) +
       (2.494386E+03f) * (ty * ty) + (-6.255134E+03f) * (ty * ty * ty * ty) + (1.891522E+02f) * (tx * tx)) /
        fabsf(dslope) +
      18.75f;
    const auto sign = -dslope * magnet_polarity > 0 ? 1.f : -1.f;
    return sign / abs_p;
  }
} // namespace Downstream::Extrapolation
