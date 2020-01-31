#pragma once

#include "DeviceAlgorithm.cuh"
#include "DeviceLineTraverser.cuh"
#include "HostPrefixSum.h"

namespace run_hlt1 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    HOST_INPUT(host_number_of_mf_svs_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_mf_svs_t, VertexFit::TrackMVAVertex) dev_mf_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_mf_sv_offsets_t, uint) dev_mf_sv_offsets;
    DEVICE_OUTPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_OUTPUT(dev_sel_results_offsets_t, uint) dev_sel_results_offsets;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  template<typename T>
  __global__ void run_hlt1(Parameters parameters)
  {
    const uint event_number = blockIdx.x;

    // Fetch tracks
    const ParKalmanFilter::FittedTrack* event_tracks =
      parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[event_number];
    const auto number_of_tracks_in_event =
      parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];

    // Fetch vertices
    const VertexFit::TrackMVAVertex* event_vertices =
      parameters.dev_consolidated_svs + parameters.dev_sv_offsets[event_number];
    const auto number_of_vertices_in_event =
      parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];

    // Fetch MF vertices
    const VertexFit::TrackMVAVertex* event_mf_vertices =
      parameters.dev_mf_svs + parameters.dev_mf_sv_offsets[event_number];
    const auto number_of_mf_vertices_in_event =
      parameters.dev_mf_sv_offsets[event_number + 1] - parameters.dev_mf_sv_offsets[event_number];

    // Process all lines
    Hlt1::Traverse<T>::traverse(
      parameters.dev_sel_results,
      parameters.dev_sel_results_offsets,
      parameters.dev_offsets_forward_tracks,
      parameters.dev_sv_offsets,
      parameters.dev_mf_sv_offsets,
      event_tracks,
      event_vertices,
      event_mf_vertices,
      event_number,
      number_of_tracks_in_event,
      number_of_vertices_in_event,
      number_of_mf_vertices_in_event);
  }

  template<typename T, typename U, char... S>
  struct run_hlt1_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(run_hlt1<U>)) function {run_hlt1<U>};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_sel_results_t>(
        arguments, 1000 * value<host_number_of_selected_events_t>(arguments) * std::tuple_size<U>::value);
      set_size<dev_sel_results_offsets_t>(arguments, std::tuple_size<U>::value + 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // TODO: Do this on the GPU, or rather remove completely
      // Prepare prefix sum of sizes of number of tracks and number of secondary vertices
      for (uint i_line = 0; i_line < std::tuple_size<U>::value; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = 0;
      }

      const auto lambda_one_track_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      };
      Hlt1::TraverseLines<U, Hlt1::OneTrackLine, decltype(lambda_one_track_fn)>::traverse(lambda_one_track_fn);

      const auto lambda_two_track_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_svs_t>(arguments);
      };
      Hlt1::TraverseLines<U, Hlt1::TwoTrackLine, decltype(lambda_two_track_fn)>::traverse(lambda_two_track_fn);

      const auto lambda_velo_ut_two_track_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_mf_svs_t>(arguments);
      };
      Hlt1::TraverseLines<U, Hlt1::VeloUTTwoTrackLine, decltype(lambda_velo_ut_two_track_fn)>::traverse(
        lambda_velo_ut_two_track_fn);

      // Prefix sum
      host_prefix_sum::host_prefix_sum_impl(host_buffers.host_sel_results_atomics, std::tuple_size<U>::value);

      cudaCheck(cudaMemcpyAsync(
        begin<dev_sel_results_offsets_t>(arguments),
        host_buffers.host_sel_results_atomics,
        size<dev_sel_results_offsets_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      initialize<dev_sel_results_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_mf_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_mf_sv_offsets_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_offsets_t>(arguments)});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_sel_results,
          begin<dev_sel_results_t>(arguments),
          size<dev_sel_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace run_hlt1
