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
  uint32_t number_of_raw_banks = 0;
  const char* data = nullptr;

  // For Allen format
  __device__ __host__ CaloRawEvent(char const* event_data, uint32_t const* offsets, unsigned const event_number)
  {
    data = event_data + offsets[event_number];
    number_of_raw_banks = reinterpret_cast<uint32_t const*>(data)[0];
  }

  __device__ __host__ CaloRawBank bank(unsigned const n)
  {
    uint32_t const* bank_offsets = reinterpret_cast<uint32_t const*>(data) + 1;
    return CaloRawBank {data + (number_of_raw_banks + 2) * sizeof(uint32_t) + bank_offsets[n],
                        bank_offsets[n + 1] - bank_offsets[n]};
  }
};

struct CaloMepEvent {
  uint32_t number_of_raw_banks = 0;
  const char* blocks = nullptr;
  const uint32_t* offsets = nullptr;
  const unsigned event = 0;

  // For Allen format
  __device__ __host__ CaloMepEvent(const char* b, const uint32_t* o, unsigned const event_number) :
    number_of_raw_banks {MEP::number_of_banks(o)}, blocks {b}, offsets {o}, event {event_number}
  {}

  __device__ __host__ CaloRawBank bank(unsigned const n)
  {
    return MEP::raw_bank<CaloRawBank>(blocks, offsets, event, n);
  }
};
