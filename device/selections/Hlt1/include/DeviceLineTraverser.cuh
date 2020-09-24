/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// #include "LineTraverser.cuh"

namespace Hlt1 {
  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct DeviceTraverseLinesImpl;

  template<typename U>
  struct DeviceTraverseLinesImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    __device__ constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I);
      DeviceTraverseLinesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct DeviceTraverseLines {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct DeviceTraverseLinesNamesImpl;

  template<typename U>
  struct DeviceTraverseLinesNamesImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    __device__ constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I, T::name);
      DeviceTraverseLinesNamesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesNamesImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesNamesImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct DeviceTraverseLinesNames {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesNamesImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct Devicethat iterates over the lines according to their signature
  template<typename Tuple, typename Linetype, typename Iseq, typename Enabled = void>
  struct DeviceTraverseLinesScaleFactorsImpl;

  template<typename U>
  struct DeviceTraverseLinesScaleFactorsImpl<std::tuple<>, U, std::index_sequence<>, void> {
    template<typename F>
    __device__ constexpr static void traverse(const F&) {}
  };

  // If the line inherits from U, execute the lambda with the index of the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesScaleFactorsImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<U, T>::value>::type> {\
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      lambda_fn(I, T::scale_factor);
      DeviceTraverseLinesScaleFactorsImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // If the line does not inherit from U, ignore the line
  template<typename T, typename... OtherLines, typename U, unsigned long I, unsigned long... Is>
  struct DeviceTraverseLinesScaleFactorsImpl<
    std::tuple<T, OtherLines...>,
    U,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<U, T>::value>::type> {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesScaleFactorsImpl<std::tuple<OtherLines...>, U, std::index_sequence<Is...>>::traverse(lambda_fn);
    }
  };

  // Traverse lines that inherit from U
  template<typename T, typename U>
  struct DeviceTraverseLinesScaleFactors {
    template<typename F>
    __device__ constexpr static void traverse(const F& lambda_fn)
    {
      DeviceTraverseLinesScaleFactorsImpl<T, U, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(lambda_fn);
    }
  };

  // Struct Devicethat iterates over the lines according to their signature
  template<typename T, typename I, typename Enabled = void>
  struct TraverseImpl;

  template<>
  struct TraverseImpl<std::tuple<>, std::index_sequence<>, void> {
    __device__ constexpr static void traverse(
      bool*,
      const unsigned*,
      const unsigned*,
      const unsigned*,
      const ParKalmanFilter::FittedTrack*,
      const VertexFit::TrackMVAVertex*,
      const char*,
      const unsigned,
      const unsigned,
      const unsigned,
      const unsigned)
    {}
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<OneTrackLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_offsets_forward_tracks,
      const unsigned* dev_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const char* event_odin_data,
      const unsigned number_of_velo_tracks,
      const unsigned event_number,
      const unsigned number_of_tracks_in_event,
      const unsigned number_of_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + dev_offsets_forward_tracks[event_number];

      for (unsigned i = threadIdx.x; i < number_of_tracks_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_tracks[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        number_of_velo_tracks,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<VeloLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_offsets_forward_tracks,
      const unsigned* dev_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const char* event_odin_data,
      const unsigned number_of_velo_tracks,
      const unsigned event_number,
      const unsigned number_of_tracks_in_event,
      const unsigned number_of_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + event_number;

      if (threadIdx.x == 0) {
        decisions[0] = T::function(number_of_velo_tracks);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        number_of_velo_tracks,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<TwoTrackLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_offsets_forward_tracks,
      const unsigned* dev_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const char* event_odin_data,
      const unsigned number_of_velo_tracks,
      const unsigned event_number,
      const unsigned number_of_tracks_in_event,
      const unsigned number_of_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + dev_sv_offsets[event_number];

      for (unsigned i = threadIdx.x; i < number_of_vertices_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_vertices[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        number_of_velo_tracks,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<SpecialLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_offsets_forward_tracks,
      const unsigned* dev_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const char* event_odin_data,
      const unsigned number_of_velo_tracks,
      const unsigned event_number,
      const unsigned number_of_tracks_in_event,
      const unsigned number_of_vertices_in_event)
    {
      // Ignore the special lines
      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        number_of_velo_tracks,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  };

  template<typename T>
  struct Traverse {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_offsets_forward_tracks,
      const unsigned* dev_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const char* event_odin_data,
      const unsigned number_of_velo_tracks,
      const unsigned event_number,
      const unsigned number_of_tracks_in_event,
      const unsigned number_of_vertices_in_event)
    {
      TraverseImpl<T, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        number_of_velo_tracks,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  };

  // Struct that iterates over the lines according to their signature
  template<typename T, typename I, typename Enabled = void>
  struct SpecialLineTraverseImpl;

  template<>
  struct SpecialLineTraverseImpl<std::tuple<>, std::index_sequence<>, void> {
    __device__ constexpr static void traverse(bool*, const unsigned*, const unsigned*, const char*, const unsigned) {}
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct SpecialLineTraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<!std::is_base_of<SpecialLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_odin_raw_input_offsets,
      const char* dev_odin_raw_input,
      const unsigned number_of_events)
    {
      SpecialLineTraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results, dev_sel_results_offsets, dev_odin_raw_input_offsets, dev_odin_raw_input, number_of_events);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct SpecialLineTraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<SpecialLine, T>::value>::type> {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_odin_raw_input_offsets,
      const char* dev_odin_raw_input,
      const unsigned number_of_events)
    {
      bool* decision = dev_sel_results + dev_sel_results_offsets[I];

      for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
        decision[i] = T::function(dev_odin_raw_input + dev_odin_raw_input_offsets[i]);
      }

      SpecialLineTraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results, dev_sel_results_offsets, dev_odin_raw_input_offsets, dev_odin_raw_input, number_of_events);
    }
  };

  template<typename T>
  struct SpecialLineTraverse {
    __device__ constexpr static void traverse(
      bool* dev_sel_results,
      const unsigned* dev_sel_results_offsets,
      const unsigned* dev_odin_raw_input_offsets,
      const char* dev_odin_raw_input,
      const unsigned number_of_events)
    {
      SpecialLineTraverseImpl<T, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(
        dev_sel_results, dev_sel_results_offsets, dev_odin_raw_input_offsets, dev_odin_raw_input, number_of_events);
    }
  };
} // namespace Hlt1
