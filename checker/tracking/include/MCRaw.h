/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <BackendCommon.h>
#include "MCEvent.h"
#include "InputProvider.h"

struct MCRawBank {
  __device__ __host__ MCRawBank(const char* raw_bank, const char* end)
  {
    const char* p = raw_bank;
    m_sourceID = *((uint32_t*) p);
    p += sizeof(uint32_t);
    m_data = (char*) p;
    m_last = (char*) end;
  }

  __device__ __host__ char* data() { return m_data; }
  __device__ __host__ const char* data() const { return m_data; }
  __device__ __host__ char* last() { return m_last; }
  __device__ __host__ const char* last() const { return m_last; }

private:
  uint32_t m_sourceID;
  char* m_data;
  char* m_last;
};

struct MCRawEvent {

  __device__ __host__ MCRawEvent(const char* event)
  {
    const char* p = event;
    m_number_of_raw_banks = *((uint32_t*) p);
    p += sizeof(uint32_t);
    m_raw_bank_offset = (uint32_t*) p;
    p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
    m_payload = (char*) p;
  }
  __device__ __host__ MCRawBank get_mc_raw_bank(const uint32_t index) const
  {
    MCRawBank bank(m_payload + m_raw_bank_offset[index], m_payload + m_raw_bank_offset[index + 1]);
    return bank;
  }

  __device__ __host__ uint32_t number_of_raw_banks() const { return m_number_of_raw_banks; }

private:
  uint32_t m_number_of_raw_banks;
  uint32_t* m_raw_bank_offset;
  char* m_payload;
};

MCEvents
mc_info_from_raw_banks_to_mc_events(IInputProvider const* input_provider, size_t idx, size_t first, size_t last);
