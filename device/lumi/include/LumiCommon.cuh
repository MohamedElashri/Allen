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

#include <LumiDefinitions.cuh>

inline __device__ void
fillLumiInfo(Lumi::LumiInfo& info, const unsigned offset, const unsigned size, const unsigned value)
{
  info.size = size;
  info.offset = offset;
  info.value = value;
}

inline __device__ void fillLumiInfo(
  Lumi::LumiInfo& info,
  const unsigned offset,
  const unsigned size,
  const float value,
  const float shift,
  const float multiplier = 1.f)
{
  float scaled_value = shift + value * multiplier;

  if (scaled_value < 0.f) {
    fillLumiInfo(info, offset, size, 0u);
  }
  else if (scaled_value >= (1ul << size)) {
    fillLumiInfo(info, offset, size, (1ul << size) - 1u);
  }
  else {
    fillLumiInfo(info, offset, size, static_cast<unsigned>(scaled_value));
  }
}
