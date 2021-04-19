/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include <iostream>
#include <iomanip>

#include "BackendCommon.h"

struct CaloGeometry {
  uint32_t code_offset = 0;
  uint32_t card_channels = 0;
  uint32_t max_index = 0;
  float pedestal = 0;
  uint16_t* channels = nullptr;
  uint16_t* neighbors = nullptr;
  float* xy = nullptr;
  float* gain = nullptr;

  __device__ __host__ CaloGeometry(const char* raw_geometry)
  {
    const char* p = raw_geometry;
    code_offset = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip code offset.
    card_channels = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip card_channels.
    max_index = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip max_index.
    pedestal = *((float*) p);
    p += sizeof(float); // Skip pedestal
    const auto channels_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip channel size
    channels = (uint16_t*) p;
    p += sizeof(uint16_t) * channels_size;
    const auto neighbors_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip neighbours size
    neighbors = (uint16_t*) p;
    p += sizeof(uint16_t) * neighbors_size;
    const uint32_t xy_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip xy size
    xy = (float*) p;
    p += sizeof(float) * xy_size;
    // const uint32_t gain_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip gain size
    gain = (float*) p;
  }

  __device__ __host__ inline float getX(uint16_t cellid) const { return xy[2 * cellid]; }

  __device__ __host__ inline float getY(uint16_t cellid) const { return xy[2 * cellid + 1]; }
};
