/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "BackendCommon.h"

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

  // Check if an algorithm has a check member function
  template<class T, typename... Args>
  using constructor_t = decltype(T {std::declval<const Args&>()...});

  template<class T, typename... Args>
  using has_constructor = is_detected<constructor_t, T, Args...>;

  namespace detail {
    template<class Bank, typename... Args, std::enable_if_t<has_constructor<Bank, Args...>::value>* = nullptr>
    __host__ __device__ inline Bank
    raw_bank(char const* blocks, unsigned int const* offsets, unsigned int const event, unsigned int const bank)
    {
      auto const source_id = offsets[2 + bank];
      auto const n_banks = offsets[0];
      auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
      auto const* fragment_end = blocks + offsets[offset_index(n_banks, event + 1, bank)];
      return {source_id, fragment, fragment_end};
    }

    template<class Bank, typename... Args, std::enable_if_t<!has_constructor<Bank, Args...>::value>* = nullptr>
    __host__ __device__ inline Bank
    raw_bank(char const* blocks, unsigned int const* offsets, unsigned int const event, unsigned int const bank)
    {
      auto const source_id = offsets[2 + bank];
      auto const n_banks = offsets[0];
      auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
      return {source_id, fragment};
    }
  } // namespace detail

  template<class Bank>
  __host__ __device__ inline Bank
  raw_bank(char const* blocks, unsigned int const* offsets, unsigned int const event, unsigned int const bank)
  {
    return detail::raw_bank<Bank, uint32_t const, char const*, char const*>(blocks, offsets, event, bank);
  }

  template<class Bank>
  struct RawEvent {
  private:
    const char* m_raw_input;
    const unsigned* m_raw_input_offsets;
    unsigned m_event_number;

  public:
    __host__ __device__
    RawEvent(const char* raw_input, const unsigned* raw_input_offsets, const unsigned event_number) :
      m_raw_input(raw_input),
      m_raw_input_offsets(raw_input_offsets), m_event_number(event_number)
    {}

    __host__ __device__ unsigned number_of_raw_banks() const { return m_raw_input_offsets[0]; }

    __host__ __device__ Bank raw_bank(const unsigned index) const
    {
      return MEP::raw_bank<Bank>(m_raw_input, m_raw_input_offsets, m_event_number, index);
    }

    __host__ __device__ unsigned bank_size(const unsigned index) const
    {
      const auto n_raw_banks = number_of_raw_banks();
      const auto offset_index = 2 + n_raw_banks * (1 + m_event_number);
      return m_raw_input_offsets[offset_index + index + n_raw_banks] - m_raw_input_offsets[offset_index + index];
    }
  };
} // namespace MEP
