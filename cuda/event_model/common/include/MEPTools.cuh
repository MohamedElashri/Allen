#pragma once

#include "Common.h"
#include "CudaCommon.h"

namespace MEP {

__forceinline__ __device__ unsigned int source_id(unsigned int const* offsets, unsigned int const bank) {
  return offsets[2 + bank];
}

__forceinline__ __device__ unsigned int number_of_banks(unsigned int const* offsets) {
  return offsets[0];
}

__forceinline__ __device__ unsigned int offset_index(unsigned int const n_banks, unsigned int const event,
                                                     unsigned int const bank) {
  return 2 + n_banks * (1 + event) + bank;
}

// Check if an algorithm has a check member function
template <class T, typename... Args>
using constructor_t = decltype(T{std::declval<const Args&>()...});

template <class T, typename... Args>
using has_constructor = is_detected<constructor_t, T, Args...>;

namespace detail {
  template <class Bank, typename... Args, std::enable_if_t<has_constructor<Bank, Args...>::value>* = nullptr>
  __forceinline__ __device__ Bank raw_bank(char const* blocks, unsigned int const* offsets,
                               unsigned int const event, unsigned int const bank) {
    auto const source_id = offsets[2 + bank];
    auto const n_banks = offsets[0];
    auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
    auto const* fragment_end = blocks + offsets[offset_index(n_banks, event + 1, bank)];
    return {source_id, fragment, fragment_end};
  }

  template <class Bank, typename... Args, std::enable_if_t<!has_constructor<Bank, Args...>::value>* = nullptr>
  __forceinline__ __device__ Bank raw_bank(char const* blocks, unsigned int const* offsets,
                               unsigned int const event, unsigned int const bank) {
    auto const source_id = offsets[2 + bank];
    auto const n_banks = offsets[0];
    auto const* fragment = blocks + offsets[offset_index(n_banks, event, bank)];
    return {source_id, fragment};
  }
}

template <class Bank>
__forceinline__ __device__ Bank raw_bank(char const* blocks, unsigned int const* offsets,
                             unsigned int const event, unsigned int const bank) {
  return detail::raw_bank<Bank, uint32_t const, char const*, char const*>(blocks, offsets, event, bank);
}

}
