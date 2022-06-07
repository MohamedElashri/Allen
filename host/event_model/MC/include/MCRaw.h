/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <BackendCommon.h>
#include <MEPTools.h>
#include "MCEvent.h"
#include "InputProvider.h"

struct MCRawBank {
  __device__ __host__ MCRawBank(const char* raw_bank, const uint16_t s)
  {
    char const* p = raw_bank;
    m_sourceID = reinterpret_cast<uint32_t const*>(p)[0];
    p += sizeof(uint32_t);
    m_data = p;
    m_last = p + s;
  }

  __device__ __host__ const char* data() const { return m_data; }
  __device__ __host__ const char* last() const { return m_last; }

private:
  uint32_t m_sourceID = 0;
  char const* m_data = nullptr;
  char const* m_last = nullptr;
};

struct MCRawEvent {

  __device__ __host__
  MCRawEvent(const char* event_data, const uint32_t* offsets, const uint32_t* sizes, const uint32_t event_number) :
    m_event_number {event_number},
    m_raw_bank_sizes {sizes}
  {
    const char* p = event_data + offsets[event_number];
    m_number_of_raw_banks = reinterpret_cast<uint32_t const*>(p)[0];
    p += sizeof(uint32_t);
    m_raw_bank_offset = reinterpret_cast<uint32_t const*>(p);
    p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
    m_payload = p;
  }

  __device__ __host__ MCRawBank get_mc_raw_bank(const uint32_t index) const
  {
    MCRawBank bank {m_payload + m_raw_bank_offset[index], Allen::bank_size(m_raw_bank_sizes, m_event_number, index)};
    return bank;
  }

  __device__ __host__ uint32_t number_of_raw_banks() const { return m_number_of_raw_banks; }

private:
  uint32_t m_event_number = 0;
  uint32_t m_number_of_raw_banks = 0;
  uint32_t const* m_raw_bank_offset = nullptr;
  uint32_t const* m_raw_bank_sizes = nullptr;
  char const* m_payload = nullptr;
};

MCEvents
mc_info_from_raw_banks_to_mc_events(IInputProvider const* input_provider, size_t idx, size_t first, size_t last);
