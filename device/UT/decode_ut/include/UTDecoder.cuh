/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "BackendCommon.h"
#include "UTRaw.cuh"
#include <MEPTools.h>

//
// Helper clases
//
namespace UTDecoding {
  struct PredecodeHitInfo {
    using DataType = uint32_t;
    __host__ __device__ PredecodeHitInfo(uint32_t _data) : data(_data) {}
    __host__ __device__ PredecodeHitInfo(uint16_t word, uint16_t board_idx) :
      data(word | (static_cast<uint32_t>(board_idx) << 16))
    {}
    __host__ __device__ uint16_t word() { return data & 0xFFFF; }
    __host__ __device__ uint16_t board_idx() { return data >> 16; }
    uint32_t data;
  };

  struct UTStripInfo {
    using DataType = uint32_t;
    __host__ __device__ UTStripInfo(uint32_t _data) : data(_data) {}
    __host__ __device__ UTStripInfo(bool flip, uint16_t strip_id, uint16_t adc_count) :
      data((flip << 15) | (strip_id & 0x7FFF) | (static_cast<uint32_t>(adc_count) << 16))
    {}
    __host__ __device__ uint16_t strip_id() { return data & 0x7FFF; }
    __host__ __device__ uint16_t signed_strip_id() { return data & 0xFFFF; }
    __host__ __device__ uint16_t sign() { return (data >> 15) & 1; }
    __host__ __device__ uint16_t adc_count() { return data >> 16; }
    uint32_t data;
  };

  struct UTClusterInfo {
    using DataType = uint64_t;
    __host__ __device__ UTClusterInfo(uint64_t _data) : data(_data) {}
    __host__ __device__ UTClusterInfo(uint32_t predecoded_hit, float mean_strip) :
      data((static_cast<uint64_t>(predecoded_hit) << 32) | Allen::device::bit_cast<uint32_t>(mean_strip))
    {}
    __host__ __device__ uint16_t word() { return (data >> 32) & 0xFFFF; }
    __host__ __device__ uint16_t board_idx() { return (data >> 48) & 0xFFFF; }
    __host__ __device__ float mean_strip()
    {
      return Allen::device::bit_cast<float>(static_cast<uint32_t>(data & 0xFFFFFFFF));
    }
    uint64_t data;
  };

  struct UTClusterKeyInfo {
    using DataType = uint64_t;
    __host__ __device__ UTClusterKeyInfo(uint64_t _data) : data(_data) {}
    __host__ __device__ UTClusterKeyInfo(float xAtYEq0, uint32_t tiebreak)
    {
      const uint32_t uint32_xAtYEq0 = Allen::device::bit_cast<uint32_t>(xAtYEq0);
      const uint64_t ordered_xAtYEq0 = (uint32_xAtYEq0 & 0x80000000) ? ~uint32_xAtYEq0 : (uint32_xAtYEq0 | 0x80000000);
      data = ordered_xAtYEq0 << 32 | tiebreak;
    }
    __host__ __device__ float xAtYEq0()
    {
      const uint32_t data_xAtYEq0 = data >> 32;
      const uint32_t uint32_xAtYEq0 = (data_xAtYEq0 & 0x80000000) ? (data_xAtYEq0 & ~(1 << 31)) : ~data_xAtYEq0;
      return Allen::device::bit_cast<float>(uint32_xAtYEq0);
    }
    __host__ __device__ uint32_t tiebreak() { return data & 0xFFFFFFFF; }
    uint64_t data;
  };
} // namespace UTDecoding
