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
#include "CaloRawBanks.cuh"
#include "MEPTools.h"

struct CaloRawEvent {
  uint32_t number_of_raw_banks;
  const char* data;
  const uint32_t* offsets;

  // For Allen format
  __device__ __host__ CaloRawEvent(const char* events, const uint32_t* o) :
    number_of_raw_banks {((uint32_t*) (events + o[0]))[0]}, data {events}, offsets {o}
  {}

  __device__ __host__ CaloRawBank bank(unsigned event, unsigned n)
  {
    const char* event_data = data + offsets[event];
    uint32_t* bank_offsets = ((uint32_t*) event_data) + 1;
    return CaloRawBank {event_data + (number_of_raw_banks + 2) * sizeof(uint32_t) + bank_offsets[n],
                        bank_offsets[n + 1] - bank_offsets[n]};
  }
};

struct CaloMepEvent {
  uint32_t number_of_raw_banks;
  const char* blocks;
  const uint32_t* offsets;

  // For Allen format
  __device__ __host__ CaloMepEvent(const char* b, const uint32_t* o) :
    number_of_raw_banks {MEP::number_of_banks(o)}, blocks {b}, offsets {o}
  {}

  __device__ __host__ CaloRawBank bank(unsigned event, unsigned n)
  {
    return MEP::raw_bank<CaloRawBank>(blocks, offsets, event, n);
  }
};
