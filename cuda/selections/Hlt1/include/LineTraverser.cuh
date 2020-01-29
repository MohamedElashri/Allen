#pragma once

#include <functional>
#include <tuple>
#include <utility>
#include <cstdio>
#include "LineInfo.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanDefinitions.cuh"

namespace Hlt1 {
  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Function, typename Iseq, typename Enabled = void>
  struct TraverseLinesImpl;

  template<typename U, typename F>
  struct TraverseLinesImpl<std::tuple<>, U, F, std::index_sequence<>, void> {
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    F,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I);
      TraverseLinesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    F,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!bool(std::is_base_of<U, T>::value)>::type> {
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U, typename F>
  struct TraverseLines {
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesImpl<T, U, F, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Function, typename Iseq, typename Enabled = void>
  struct TraverseLinesNamesImpl;

  template<typename U, typename F>
  struct TraverseLinesNamesImpl<std::tuple<>, U, F, std::index_sequence<>, void> {
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    F,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I, T::name);
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    F,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!bool(std::is_base_of<U, T>::value)>::type> {
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U, typename F>
  struct TraverseLinesNames {
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesNamesImpl<T, U, F, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };
} // namespace Hlt1
