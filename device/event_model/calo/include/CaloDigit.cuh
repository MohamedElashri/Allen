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

#include "BackendCommon.h"
#include <climits>

struct CaloDigit {
  int16_t adc = 0;

  __device__ __host__ inline uint8_t area(uint16_t cellID) { return (cellID >> 12) & 0x3; }

  __device__ __host__ inline uint8_t row(uint16_t cellID) { return (cellID >> 6) & 0x3F; }

  __device__ __host__ inline uint8_t col(uint16_t cellID) { return cellID & 0x3F; }
};
