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

// fills a lumi counter of [size] bits
inline __device__ void
fillLumiInfo(Lumi::LumiInfo& info, const unsigned offset, const unsigned size, const unsigned value)
{
  info.size = size;
  info.offset = offset;
  info.value = value;
}

// fills a lumi counter of [size] bits
// shifts and scales are primarily intended for counters
// based on floats but may, in principle, be used for integer
// counters - supported explicitly to avoid loss of precision
// due to implicit casting to float and back to unsigned
inline __device__ void fillLumiInfo(
  Lumi::LumiInfo& info,
  const unsigned offset,
  const unsigned size,
  const unsigned value,
  const float shift,
  const float scale = 1.f)
{
  if (shift == 0.f && scale == 1.f) {
    fillLumiInfo(info, offset, size, value);
  }
  else if (shift + value * scale > 0.f) {
    fillLumiInfo(info, offset, size, static_cast<unsigned>(std::round(shift + value * scale)));
  }
  else {
    fillLumiInfo(info, offset, size, 0u);
  }
}

// fills a lumi counter of [size] bits
// shifts and scales are primarily intended for counters
// based on floats but may, in principle, be used for integer
// counters - supported explicitly to avoid implicit casting
inline __device__ void fillLumiInfo(
  Lumi::LumiInfo& info,
  const unsigned offset,
  const unsigned size,
  const int value,
  const float shift,
  const float scale = 1.f)
{
  if (shift == 0.f && scale == 1.f) {
    fillLumiInfo(info, offset, size, static_cast<unsigned>(value));
  }
  else {
    int scaled_value = static_cast<int>(shift + value * scale);

    if (scaled_value <= 0) {
      fillLumiInfo(info, offset, size, 0u);
    }
    else if (scaled_value >= (1l << size) - 1) {
      fillLumiInfo(info, offset, size, static_cast<unsigned>((1ul << size) - 1u));
    }
    else {
      fillLumiInfo(info, offset, size, static_cast<unsigned>(scaled_value));
    }
  }
}

// fills a lumi counter of [size] bits
// the values 0 and 2^[size] - 1 are reserved for under/overflow
// may represent values in the range [minimum,maximum) with
// minimum = (1 - [shift]) / [scale]
// maximum = (2^[size] - [shift] - 1) / [scale]
// resolution = [scale]
inline __device__ void fillLumiInfo(
  Lumi::LumiInfo& info,
  const unsigned offset,
  const unsigned size,
  const float value,
  const float shift = 0.f,
  const float scale = 1.f)
{
  float scaled_value = shift + value * scale;

  if (scaled_value < 1.f) {
    fillLumiInfo(info, offset, size, 0u);
  }
  else if (scaled_value >= (1ul << size) - 1u) {
    fillLumiInfo(info, offset, size, static_cast<unsigned>((1ul << size) - 1u));
  }
  else {
    fillLumiInfo(info, offset, size, static_cast<unsigned>(scaled_value));
  }
}

// avoid any implicit casts of the type of value
template<class T>
inline __device__ void fillLumiInfo(
  Lumi::LumiInfo& info,
  const unsigned offset,
  const unsigned size,
  const T value,
  const float shift = 0.f,
  const float scale = 1.f) = delete;
