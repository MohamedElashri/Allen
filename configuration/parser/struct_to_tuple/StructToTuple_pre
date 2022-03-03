/**
 * @brief This file implements struct to tuple conversion with structured bindings.
 */

#include <tuple>
#include <type_traits>
#include <cassert>

namespace details {
  /// Implementation of the detection idiom (negative case).
  template<typename AlwaysVoid, template<typename...> class Op, typename... Args>
  struct detector {
    constexpr static bool value = false;
  };

  /// Implementation of the detection idiom (positive case).
  template<template<typename...> class Op, typename... Args>
  struct detector<std::void_t<Op<Args...>>, Op, Args...> {
    constexpr static bool value = true;
  };
} // namespace details

template<template<class...> class Op, class... Args>
using is_detected_st = details::detector<void, Op, Args...>;

template<template<class...> class Op, class... Args>
inline constexpr bool is_detected_st_v = is_detected_st<Op, Args...>::value;

template<typename T, typename... Args>
using braced_init = decltype(T {std::declval<Args>()...});

// This is not even my final form
template<typename... Args>
inline constexpr bool is_braces_constructible = is_detected_st_v<braced_init, Args...>;

struct any_type {
  template<class T>
  constexpr operator T(); // non explicit
};

// Avoid wrong warnings from nvcc:
// Warning #940-D: missing return statement at end of non-void function "struct_to_tuple(T &&)""
#ifdef __CUDACC__
#pragma push
#pragma diag_suppress = 940
#endif

/**
 * @brief Struct to tuple conversion using structured binding.
 */
template<class T>
auto struct_to_tuple(T&& object) noexcept
{
  using type = std::decay_t<T>;
