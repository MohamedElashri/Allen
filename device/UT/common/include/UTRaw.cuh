/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>

struct UTRawBank_v4 {
  uint32_t sourceID;
  uint32_t number_of_hits;
  uint16_t* data;

  __device__ __host__ UTRawBank_v4(const char* ut_raw_bank, const uint32_t&)
  {
    uint32_t* p = (uint32_t*) ut_raw_bank;
    p += 1;//skip version
    sourceID = *p;
    p += 1;
    number_of_hits = *p & 0x0000FFFFU;
    p += 1;
    data = (uint16_t*) p;
  }

  __device__ __host__ UTRawBank_v4(const uint32_t sID, const char* ut_fragment, const uint32_t&)
  {
    sourceID = sID;
    uint32_t* p = (uint32_t*) ut_fragment;
    p += 1;//skip version
    number_of_hits = *p & 0x0000FFFFU;
    p += 1;
    data = (uint16_t*) p;
  }

  __device__ __host__ uint32_t get_n_hits() const
  {
    return number_of_hits;
  }

  __device__ __host__ uint32_t version() const
  {
    return 3;
  }

};

struct UTRawBank_v5 {
  uint32_t sourceID;
  std::array<uint32_t,6> number_of_hits_per_lane;
  uint16_t* data;

  __device__ __host__ UTRawBank_v5(const char* ut_raw_bank, const uint32_t& size)
  {
    uint32_t* p = (uint32_t*) ut_raw_bank;
    p += 1;//skip version
    sourceID = *p;
    p += 1;
    number_of_hits_per_lane[4] = (*p & 0xFFU) >> 0U;
    number_of_hits_per_lane[5] = (*p & 0xFF00U) >> 8U;
    p += 1;
    number_of_hits_per_lane[0] = (*p & 0xFFU) >> 0U;
    number_of_hits_per_lane[1] = (*p & 0xFF00U) >> 8U;
    number_of_hits_per_lane[2] = (*p & 0xFF0000U) >> 16U;
    number_of_hits_per_lane[3] = (*p & 0xFF000000U) >> 24U;
    p += 1;
    data = (uint16_t*) p;
    if(size < 40) number_of_hits_per_lane = {0,0,0,0,0,0}; // the header contains garbage if there are actually no words to decode
  }

  __device__ __host__ UTRawBank_v5(const uint32_t sID, const char* ut_fragment, const uint32_t& size)
  {
    sourceID = sID;
    uint32_t* p = (uint32_t*) ut_fragment;
    p += 1;//skip version
    number_of_hits_per_lane[4] = (*p & 0xFFU) >> 0U;
    number_of_hits_per_lane[5] = (*p & 0xFF00U) >> 8U;
    p += 1;
    number_of_hits_per_lane[0] = (*p & 0xFFU) >> 0U;
    number_of_hits_per_lane[1] = (*p & 0xFF00U) >> 8U;
    number_of_hits_per_lane[2] = (*p & 0xFF0000U) >> 16U;
    number_of_hits_per_lane[3] = (*p & 0xFF000000U) >> 24U;
    p += 1;
    data = (uint16_t*) p;
    if(size < 40) number_of_hits_per_lane = {0,0,0,0,0,0};
  }

  __device__ __host__ uint32_t get_n_hits() const
  {
    return number_of_hits_per_lane[0]+number_of_hits_per_lane[1]+number_of_hits_per_lane[2]+number_of_hits_per_lane[3]+number_of_hits_per_lane[4]+number_of_hits_per_lane[5];
  }

  // mstahl: not optimal, requires that https://gitlab.cern.ch/lhcb/LHCb/-/blob/a7260f691ea22625f9256dd8a60b6ec4504d7aa4/UT/UTKernel/Kernel/UTDAQDefinitions.h#L37 doesn't change
  __device__ __host__ uint32_t version() const
  {
    return 4;
  }

};

struct UTRawEvent {
  uint32_t number_of_raw_banks;
  uint32_t* raw_bank_offsets;
  char* data;

  __device__ __host__ UTRawEvent(const char* event)
  {
    const char* p = event;
    number_of_raw_banks = *((uint32_t*) p);
    p += sizeof(uint32_t);
    raw_bank_offsets = (uint32_t*) p;
    p += (number_of_raw_banks + 1) * sizeof(uint32_t);
    data = (char*) p;
  }

  __device__ __host__ uint32_t get_raw_bank_version(const uint32_t& index) const
  {
    return *((uint32_t*) (data+raw_bank_offsets[index]));
  }

  template<typename UTRawBank>
  __device__ __host__ UTRawBank getUTRawBank(const uint32_t& index) const
  {
    const uint32_t offset = raw_bank_offsets[index];
    return UTRawBank(data+offset, raw_bank_offsets[index+1]-offset);
  }
};
