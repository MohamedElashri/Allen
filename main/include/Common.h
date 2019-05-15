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
  const char* what() const throw() { return s.c_str(); }
};

// Utility to apply a function to a tuple of things
template<class T>
constexpr std::make_index_sequence<std::tuple_size<T>::value>
get_indexes( T const& )
{ return {}; }

//
template<class F, class...Args>
void for_each_arg(F&&f,Args&&...args){
  using discard=int[];
  (void)discard{0,((void)(
    f(std::forward<Args>(args))
  ),0)...};
}

template<size_t... Is, class Tuple, class F>
void for_each( std::index_sequence<Is...>, Tuple&& tup, F&& f ) {
  using std::get;
  for_each_arg(
    std::forward<F>(f),
    get<Is>(std::forward<Tuple>(tup))...
  );
}

template<class Tuple, class F>
void for_each( Tuple&& tup, F&& f ) {
  auto indexes = get_indexes(tup);
  for_each(indexes, std::forward<Tuple>(tup), std::forward<F>(f) );
}
