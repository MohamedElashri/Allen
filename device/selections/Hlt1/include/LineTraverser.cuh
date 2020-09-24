/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct TraverseLinesImpl;

  template<typename U>
  struct TraverseLinesImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I);
      TraverseLinesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct TraverseLines {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct TraverseLinesNamesImpl;

  template<typename U>
  struct TraverseLinesNamesImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I, T::name);
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct TraverseLinesNames {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesNamesImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct TraverseLinesScaleFactorsImpl;

  template<typename U>
  struct TraverseLinesScaleFactorsImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesScaleFactorsImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {\
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I, T::scale_factor);
      TraverseLinesScaleFactorsImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct TraverseLinesScaleFactorsImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesScaleFactorsImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct TraverseLinesScaleFactors {
    template<typename F>
    constexpr static void traverse(const F& lambda_fn)
    {
      TraverseLinesScaleFactorsImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };
} // namespace Hlt1
