#pragma once

#include "CudaCommon.h"

template <class... Ts>
using void_t = void;


__forceinline__ __device__ unsigned int mep_source_id(unsigned int* offsets, unsigned int const bank) {
  return offsets[2 + bank];
}

__forceinline__ __device__ unsigned int mep_offset_index(unsigned int const n_banks, unsigned int const event, unsigned int const bank) {
  return 2 + n_banks * (1 + event) + bank;
}

namespace detail {
  template <template <class...> class Trait, class Enabler, class... Args>
  struct is_detected : std::false_type{};

  template <template <class...> class Trait, class... Args>
  struct is_detected<Trait, void_t<Trait<Args...>>, Args...> : std::true_type{};
}

template <template <class...> class Trait, class... Args>
using is_detected = typename detail::is_detected<Trait, void, Args...>::type;

// Check if an algorithm has a check member function
template <class T, typename... Args>
using constructor_t = decltype(T{std::declval<const Args&>()...});

template <class T, typename... Args>
using triple_arg_constructor = is_detected<constructor_t, T, Args...>;

namespace detail {
  template <class Bank, typename... Args, std::enable_if_t<triple_arg_constructor<Bank, Args...>::value>* = nullptr>
  __forceinline__ __device__ Bank mep_raw_bank(char const* blocks, unsigned int const* offsets,
                               unsigned int const event, unsigned int const bank) {
    auto const source_id = offsets[2 + bank];
    auto const n_banks = offsets[0];
    auto const* fragment = blocks + offsets[mep_offset_index(n_banks, event, bank)];
    auto const* fragment_end = blocks + offsets[mep_offset_index(n_banks, event + 1, bank)];
    return {source_id, fragment, fragment_end};
  }

  template <class Bank, typename... Args, std::enable_if_t<!triple_arg_constructor<Bank, Args...>::value>* = nullptr>
  __forceinline__ __device__ Bank mep_raw_bank(char const* blocks, unsigned int const* offsets,
                               unsigned int const event, unsigned int const bank) {
    auto const source_id = offsets[2 + bank];
    auto const n_banks = offsets[0];
    auto const* fragment = blocks + offsets[mep_offset_index(n_banks, event, bank)];
    return {source_id, fragment};
  }
}

template <class Bank>
__forceinline__ __device__ Bank mep_raw_bank(char const* blocks, unsigned int const* offsets,
                             unsigned int const event, unsigned int const bank) {
  return detail::mep_raw_bank<Bank, uint32_t const, char const*, char const*>(blocks, offsets, event, bank);
}
