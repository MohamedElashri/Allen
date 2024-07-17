/***************************************************************************** \
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Avoid wrong warnings from nvcc:
// Warning #940-D: missing return statement at end of non-void function "LHCb::ODINImplementation::details::get_bits"
#ifdef __CUDACC__
#pragma push
#if __CUDACC_VER_MAJOR__ > 11 || (__CUDACC_VER_MAJOR__ == 11 && __CUDACC_VER_MINOR__ >= 5)
#pragma nv_diag_suppress = 940
#else
#pragma diag_suppress = 940
#endif
#endif
#include <Event/ODIN.h>
#ifdef __CUDACC__
#pragma pop
#endif
#include <Event/RawBank.h>

#include "Common.h"
#include "BackendCommon.h"

namespace Allen {
  namespace detail {
    template<typename R>
    __host__ __device__ inline R const* offsets_to_content(unsigned int const* offsets, unsigned const event)
    {
      auto const offset = offsets[event];
      return reinterpret_cast<R const*>(offsets) + offset;
    }
  } // namespace detail

  __host__ __device__ inline unsigned short const* bank_sizes(unsigned int const* sizes, unsigned const event)
  {
    return detail::offsets_to_content<unsigned short>(sizes, event);
  }

  __host__ __device__ inline unsigned short
  bank_size(unsigned int const* sizes, unsigned const event, unsigned const bank)
  {
    return bank_sizes(sizes, event)[bank];
  }

  __host__ __device__ inline unsigned char const* bank_types(unsigned int const* types_offsets, unsigned const event)
  {
    return detail::offsets_to_content<unsigned char>(types_offsets, event);
  }

  __host__ __device__ inline unsigned char
  bank_type(unsigned int const* types_offsets, unsigned const event, unsigned const bank)
  {
    return bank_types(types_offsets, event)[bank];
  }

  __host__ __device__ inline unsigned int
  number_of_banks(char const* data, unsigned const* offsets, unsigned const event_number)
  {
    // In Allen layout the offsets are indexed using the event number
    char const* event_data = data + offsets[event_number];
    // The first 4 bytes of the event data is the number of banks in the event
    return reinterpret_cast<unsigned const*>(event_data)[0];
  }

  static constexpr uint8_t LastBankType = static_cast<uint8_t>(to_integral(LHCb::RawBank::LastType));
} // namespace Allen

namespace MEP {

  __host__ __device__ inline unsigned int source_id(unsigned int const* offsets, unsigned int const bank)
  {
    return offsets[2 + bank];
  }

  __host__ __device__ inline unsigned int number_of_banks(unsigned int const* offsets) { return offsets[0]; }

  __host__ __device__ inline unsigned int
  offset_index(unsigned int const n_banks, unsigned int const event, unsigned int const bank)
  {
    return 2 + n_banks * (1 + event) + bank;
  }

  __host__ __device__ inline unsigned short const*
  bank_sizes(char const*, unsigned int const* sizes, unsigned const bank_number)
  {
    // NOTE: Once we move to copying large chunks of the MEP into a
    // separate piece of device memory, this will have to change.
    return Allen::bank_sizes(sizes, bank_number);
  }

  __host__ __device__ inline unsigned short
  bank_size(char const*, unsigned int const* sizes, unsigned const event, unsigned const bank)
  {
    // NOTE: Once we move to copying large chunks of the MEP into a
    // separate piece of device memory, this will have to change.
    return Allen::bank_size(sizes, bank, event);
  }

  __host__ __device__ inline unsigned char const*
  bank_types(char const*, unsigned int const* types_offsets, unsigned const bank_number)
  {
    // NOTE: Once we move to copying large chunks of the MEP into a
    // separate piece of device memory, this will have to change.
    return Allen::bank_types(types_offsets, bank_number);
  }

  __host__ __device__ inline unsigned char
  bank_type(char const*, unsigned int const* types_offsets, unsigned const event, unsigned const bank)
  {
    // NOTE: Once we move to copying large chunks of the MEP into a
    // separate piece of device memory, this will have to change.
    return Allen::bank_type(types_offsets, bank, event);
  }

  // Check if an algorithm has a check member function
  template<class T, typename... Args>
  using constructor_t = decltype(T {std::declval<const Args&>()...});

  template<class T, typename... Args>
  using has_constructor = is_detected<constructor_t, T, Args...>;

  namespace detail {
    template<class Bank, typename... Args, std::enable_if_t<has_constructor<Bank, Args...>::value>* = nullptr>
    __host__ __device__ inline Bank raw_bank(
      char const* blocks,
      unsigned int const* offsets,
      unsigned int const* sizes_offsets,
      unsigned int const* types_offsets,
      unsigned int const event,
      unsigned int const bank)
    {
      auto const source_id = offsets[2 + bank];
      auto const n_banks = offsets[0];
      auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
      auto const type =
        types_offsets == nullptr ? Allen::LastBankType : MEP::bank_type(blocks, types_offsets, event, bank);
      return {source_id, fragment, MEP::bank_size(blocks, sizes_offsets, event, bank), type};
    }

    template<class Bank, typename... Args, std::enable_if_t<!has_constructor<Bank, Args...>::value>* = nullptr>
    __host__ __device__ inline Bank raw_bank(
      char const* blocks,
      unsigned int const* offsets,
      unsigned int const*,
      unsigned int const* types_offsets,
      unsigned int const event,
      unsigned int const bank)
    {
      auto const source_id = offsets[2 + bank];
      auto const n_banks = offsets[0];
      auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
      auto const type =
        types_offsets == nullptr ? Allen::LastBankType : MEP::bank_type(blocks, types_offsets, event, bank);
      return {source_id, fragment, type};
    }
  } // namespace detail

  template<class Bank>
  __host__ __device__ inline Bank raw_bank(
    char const* blocks,
    unsigned int const* offsets,
    unsigned const* sizes_offsets,
    unsigned const* types_offsets,
    unsigned int const event,
    unsigned int const bank)
  {
    return detail::raw_bank<Bank, uint32_t const, char const*, uint16_t, uint8_t>(
      blocks, offsets, sizes_offsets, types_offsets, event, bank);
  }

  template<class Bank>
  struct RawEvent {
  private:
    const char* m_raw_input = nullptr;
    const unsigned* m_raw_input_sizes = nullptr;
    const unsigned* m_raw_input_types = nullptr;
    const unsigned* m_raw_input_offsets = nullptr;
    unsigned m_event_number = 0;

  public:
    // Temporary until all subdetector raw events support types
    __host__ __device__ RawEvent(
      const char* raw_input,
      const unsigned* raw_input_offsets,
      const unsigned* raw_input_sizes,
      const unsigned event_number) :
      m_raw_input(raw_input),
      m_raw_input_sizes(raw_input_sizes), m_raw_input_offsets(raw_input_offsets), m_event_number(event_number)
    {}

    __host__ __device__ RawEvent(
      const char* raw_input,
      const unsigned* raw_input_offsets,
      const unsigned* raw_input_sizes,
      const unsigned* raw_input_types,
      const unsigned event_number) :
      m_raw_input(raw_input),
      m_raw_input_sizes(raw_input_sizes), m_raw_input_types(raw_input_types), m_raw_input_offsets(raw_input_offsets),
      m_event_number(event_number)
    {}

    __host__ __device__ unsigned number_of_raw_banks() const { return m_raw_input_offsets[0]; }

    __host__ __device__ Bank raw_bank(const unsigned index) const
    {
      return MEP::raw_bank<Bank>(
        m_raw_input, m_raw_input_offsets, m_raw_input_sizes, m_raw_input_types, m_event_number, index);
    }

    __host__ __device__ unsigned short bank_size(const unsigned index) const
    {
      return MEP::bank_size(m_raw_input, m_raw_input_sizes, m_event_number, index);
    }

    __host__ __device__ unsigned char bank_type(const unsigned index) const
    {
      return m_raw_input_types == nullptr ? Allen::LastBankType :
                                            MEP::bank_type(m_raw_input, m_raw_input_types, m_event_number, index);
    }
  };
} // namespace MEP

namespace Allen {
  struct RawBank {
    uint32_t source_id = 0;
    uint16_t size = 0;
    uint8_t const* data = nullptr;
    uint8_t const type;

    // For Allen format
    __device__ __host__ RawBank(const char* raw_bank, const uint16_t s, const uint8_t t) :
      RawBank {*reinterpret_cast<uint32_t const*>(raw_bank), raw_bank + sizeof(uint32_t), s, t}
    {}

    // For MEP format
    __device__ __host__ RawBank(const uint32_t sid, const char* fragment, const uint16_t s, const uint8_t t) :
      source_id {sid}, size {s}, data {reinterpret_cast<uint8_t const*>(fragment)}, type {t}
    {}
  };

  template<bool mep_layout>
  struct RawEvent {

    uint32_t number_of_raw_banks = 0;
    const char* data = nullptr;
    const uint32_t* offsets = nullptr;
    typename std::conditional_t<mep_layout, uint32_t const, uint16_t const>* sizes = nullptr;
    typename std::conditional_t<mep_layout, uint32_t const, uint8_t const>* types = nullptr;
    const unsigned event = 0;

    // For Allen format
    __device__ __host__
    RawEvent(char const* d, uint32_t const* o, uint32_t const* s, uint32_t const* t, unsigned const event_number) :
      offsets {o},
      event {event_number}
    {
      if constexpr (mep_layout) {
        data = d;
        number_of_raw_banks = MEP::number_of_banks(o);
        sizes = s;
        types = t;
      }
      else {
        data = d + offsets[event];
        number_of_raw_banks = reinterpret_cast<uint32_t const*>(data)[0];
        sizes = Allen::bank_sizes(s, event);
        types = Allen::bank_types(t, event);
      }
    }

    __device__ __host__ RawBank raw_bank(unsigned const n) const
    {
      if constexpr (mep_layout) {
        return MEP::raw_bank<RawBank>(data, offsets, sizes, types, event, n);
      }
      else {
        uint32_t const* bank_offsets = reinterpret_cast<uint32_t const*>(data) + 1;
        return RawBank {data + (number_of_raw_banks + 2) * sizeof(uint32_t) + bank_offsets[n], sizes[n], types[n]};
      }
    }
  };
} // namespace Allen
