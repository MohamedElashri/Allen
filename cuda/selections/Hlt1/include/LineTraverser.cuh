#pragma once

#include <functional>
#include <tuple>
#include <utility>
#include <cstdio>
#include "RunHlt1Parameters.cuh"
#include "LineInfo.cuh"

namespace Hlt1 {
  // Struct that iterates over the lines according to their signature
  template<typename T, typename I, typename Enabled = void>
  struct TraverseImpl;

  template<>
  struct TraverseImpl<std::tuple<>, std::index_sequence<>, void> {
    constexpr static void traverse(
      const run_hlt1::Parameters& parameters,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event)
    {}
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<OneTrackLine, T>::value>::type> {
    constexpr static void traverse(
      const run_hlt1::Parameters& parameters,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event)
    {
      bool* decisions = parameters.dev_sel_results + parameters.dev_sel_results_offsets[I] +
                        parameters.dev_offsets_forward_tracks[event_number];

      for (uint i = threadIdx.x; i < number_of_tracks_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_tracks[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        parameters, event_tracks, event_vertices, event_number, number_of_tracks_in_event, number_of_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<TwoTrackLine, T>::value>::type> {
    constexpr static void traverse(
      const run_hlt1::Parameters& parameters,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event)
    {
      bool* decisions =
        parameters.dev_sel_results + parameters.dev_sel_results_offsets[I] + parameters.dev_sv_offsets[event_number];

      for (uint i = threadIdx.x; i < number_of_vertices_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_vertices[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        parameters, event_tracks, event_vertices, event_number, number_of_tracks_in_event, number_of_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<SpecialLine, T>::value>::type> {
    constexpr static void traverse(
      const run_hlt1::Parameters& parameters,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event)
    {
      // Ignore special lines
      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        parameters, event_tracks, event_vertices, event_number, number_of_tracks_in_event, number_of_vertices_in_event);
    }
  };

  template<typename T>
  struct Traverse {
    constexpr static void traverse(
      const run_hlt1::Parameters& parameters,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event)
    {
      TraverseImpl<T, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(
        parameters, event_tracks, event_vertices, event_number, number_of_tracks_in_event, number_of_vertices_in_event);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Function, typename Iseq, typename Enabled = void>
  struct TraverseLinesImpl;

  template<typename U, typename F>
  struct TraverseLinesImpl<std::tuple<>, U, F, std::index_sequence<>, void> {
    constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<std::tuple<T, OtherLines...>, U, F, std::index_sequence<I, Is...>, typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    constexpr static void traverse(const F& lambda_fn) {
      lambda_fn(I);
      TraverseLinesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesImpl<std::tuple<T, OtherLines...>, U, F, std::index_sequence<I, Is...>, typename std::enable_if<!bool(std::is_base_of<U, T>::value)>::type> {
    constexpr static void traverse(const F& lambda_fn) {
      TraverseLinesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U, typename F>
  struct TraverseLines {
    constexpr static void traverse(const F& lambda_fn) {
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
  struct TraverseLinesNamesImpl<std::tuple<T, OtherLines...>, U, F, std::index_sequence<I, Is...>, typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    constexpr static void traverse(const F& lambda_fn) {
      lambda_fn(I, T::name);
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, typename F, unsigned long I, unsigned long... Is>
  struct TraverseLinesNamesImpl<std::tuple<T, OtherLines...>, U, F, std::index_sequence<I, Is...>, typename std::enable_if<!bool(std::is_base_of<U, T>::value)>::type> {
    constexpr static void traverse(const F& lambda_fn) {
      TraverseLinesNamesImpl<std::tuple<OtherLines...>, U, F, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U, typename F>
  struct TraverseLinesNames {
    constexpr static void traverse(const F& lambda_fn) {
      TraverseLinesNamesImpl<T, U, F, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };
}
