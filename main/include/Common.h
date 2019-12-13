#pragma once

#include <vector>
#include <set>
#include <type_traits>
#include <iostream>
#include <utility>
#include <functional>

#include "SystemOfUnits.h"

/**
 * Generic StrException launcher
 */
struct StrException : public std::exception {
  std::string s;
  StrException(std::string ss) : s(ss) {}
  ~StrException() throw() {} // Updated
  const char* what() const throw() override { return s.c_str(); }
};

struct MemoryException : public StrException {
  MemoryException(std::string s) : StrException(s) {}
  ~MemoryException() throw() {}
};

using EventID = std::tuple<unsigned int, unsigned long>;
using EventIDs = std::vector<EventID>;

template<typename T>
void hash_combine(std::size_t& seed, T const& key)
{
  std::hash<T> hasher;
  seed ^= hasher(key) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
}

// Hash std::pair and std::tuple
namespace std {
  template<typename T1, typename T2>
  struct hash<std::pair<T1, T2>> {
    std::size_t operator()(std::pair<T1, T2> const& p) const
    {
      std::size_t seed = 0;
      ::hash_combine(seed, p.first);
      ::hash_combine(seed, p.second);
      return seed;
    }
  };

  template<typename... T>
  class hash<std::tuple<T...>> {
  private:
    typedef std::tuple<T...> tuple_t;

    template<int N>
    size_t operator()(tuple_t const&) const
    {
      return 0;
    }

    template<int N, typename H, typename... R>
    size_t operator()(tuple_t const& value) const
    {
      constexpr int index = N - sizeof...(R) - 1;
      std::size_t seed = 0;
      ::hash_combine(seed, hash<H> {}(std::get<index>(value)));
      ::hash_combine(seed, operator()<N, R...>(value));
      return seed;
    }

  public:
    size_t operator()(tuple_t value) const { return operator()<sizeof...(T), T...>(value); }
  };
} // namespace std

// Utility to apply a function to a tuple of things
template<class T>
constexpr std::make_index_sequence<std::tuple_size<T>::value> get_indexes(T const&)
{
  return {};
}

//
template<class F, class... Args>
void for_each_arg(F&& f, Args&&... args)
{
  using discard = int[];
  (void) discard {0, ((void) (f(std::forward<Args>(args))), 0)...};
}

template<size_t... Is, class Tuple, class F>
void for_each(std::index_sequence<Is...>, Tuple&& tup, F&& f)
{
  using std::get;
  for_each_arg(std::forward<F>(f), get<Is>(std::forward<Tuple>(tup))...);
}

template<class Tuple, class F>
void for_each(Tuple&& tup, F&& f)
{
  auto indexes = get_indexes(tup);
  for_each(indexes, std::forward<Tuple>(tup), std::forward<F>(f));
}

// Detection idiom
template<class... Ts>
using void_t = void;

namespace detail {
  template<template<class...> class Trait, class Enabler, class... Args>
  struct is_detected : std::false_type {
  };

  template<template<class...> class Trait, class... Args>
  struct is_detected<Trait, void_t<Trait<Args...>>, Args...> : std::true_type {
  };
} // namespace detail

template<template<class...> class Trait, class... Args>
using is_detected = typename detail::is_detected<Trait, void, Args...>::type;
