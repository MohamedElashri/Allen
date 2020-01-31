#include "LineTraverser.cuh"

namespace Hlt1 {
  // Struct that iterates over the lines according to their signature
  template<typename T, typename I, typename Enabled = void>
  struct TraverseImpl;

  template<>
  struct TraverseImpl<std::tuple<>, std::index_sequence<>, void> {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {}
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<OneTrackLine, T>::value>::type> {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + dev_offsets_forward_tracks[event_number];

      for (uint i = threadIdx.x; i < number_of_tracks_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_tracks[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        dev_mf_sv_offsets,
        event_tracks,
        event_vertices,
        event_mf_vertices,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event,
        number_of_mf_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<TwoTrackLine, T>::value>::type> {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + dev_sv_offsets[event_number];

      for (uint i = threadIdx.x; i < number_of_vertices_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_vertices[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        dev_mf_sv_offsets,
        event_tracks,
        event_vertices,
        event_mf_vertices,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event,
        number_of_mf_vertices_in_event);
    }
  };

  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<VeloUTTwoTrackLine, T>::value>::type> {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {
      bool* decisions = dev_sel_results + dev_sel_results_offsets[I] + dev_mf_sv_offsets[event_number];

      for (uint i = threadIdx.x; i < number_of_mf_vertices_in_event; i += blockDim.x) {
        decisions[i] = T::function(event_mf_vertices[i]);
      }

      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        dev_mf_sv_offsets,
        event_tracks,
        event_vertices,
        event_mf_vertices,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event,
        number_of_mf_vertices_in_event);      
    }
    
  };
  
  template<typename T, typename... OtherLines, unsigned long I, unsigned long... Is>
  struct TraverseImpl<
    std::tuple<T, OtherLines...>,
    std::index_sequence<I, Is...>,
    typename std::enable_if<std::is_base_of<SpecialLine, T>::value>::type> {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {
      // Ignore special lines
      TraverseImpl<std::tuple<OtherLines...>, std::index_sequence<Is...>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        dev_mf_sv_offsets,
        event_tracks,
        event_vertices,
        event_mf_vertices,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event,
        number_of_mf_vertices_in_event);
    }
  };

  template<typename T>
  struct Traverse {
    constexpr static __device__ void traverse(
      bool* dev_sel_results,
      const uint* dev_sel_results_offsets,
      const uint* dev_offsets_forward_tracks,
      const uint* dev_sv_offsets,
      const uint* dev_mf_sv_offsets,
      const ParKalmanFilter::FittedTrack* event_tracks,
      const VertexFit::TrackMVAVertex* event_vertices,
      const VertexFit::TrackMVAVertex* event_mf_vertices,
      const uint event_number,
      const uint number_of_tracks_in_event,
      const uint number_of_vertices_in_event,
      const uint number_of_mf_vertices_in_event)
    {
      TraverseImpl<T, std::make_index_sequence<std::tuple_size<T>::value>>::traverse(
        dev_sel_results,
        dev_sel_results_offsets,
        dev_offsets_forward_tracks,
        dev_sv_offsets,
        dev_mf_sv_offsets,
        event_tracks,
        event_vertices,
        event_mf_vertices,
        event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event,
        number_of_mf_vertices_in_event);
    }
  };
} // namespace Hlt1
