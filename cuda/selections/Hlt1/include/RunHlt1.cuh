#pragma once

#include "DeviceAlgorithm.cuh"
#include "DeviceLineTraverser.cuh"
#include "HostPrefixSum.h"

namespace run_hlt1 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, uint) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_velo_offsets;
    DEVICE_OUTPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_OUTPUT(dev_sel_results_offsets_t, uint) dev_sel_results_offsets;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  template<typename T>
  __global__ void run_hlt1(Parameters parameters, const uint selected_number_of_events, const uint event_start)
  {
    const uint total_number_of_events = gridDim.x;

    // Run all events through the Special line traverser with the last block
    if (blockIdx.x == gridDim.x - 1) {
      Hlt1::SpecialLineTraverse<T>::traverse(
        parameters.dev_sel_results,
        parameters.dev_sel_results_offsets,
        parameters.dev_odin_raw_input_offsets,
        parameters.dev_odin_raw_input,
        total_number_of_events);
    }

    if (blockIdx.x < selected_number_of_events) {
      // Run all events that passed the filter (GEC) through the other line traversers
      const uint selected_event_number = blockIdx.x;
      // TODO: Revisit when making composable lists
      const uint event_number = parameters.dev_event_list[blockIdx.x] - event_start;

      // Fetch tracks
      const ParKalmanFilter::FittedTrack* event_tracks =
        parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[selected_event_number];
      const auto number_of_tracks_in_event = parameters.dev_offsets_forward_tracks[selected_event_number + 1] -
                                             parameters.dev_offsets_forward_tracks[selected_event_number];

      // Fetch vertices
      const VertexFit::TrackMVAVertex* event_vertices =
        parameters.dev_consolidated_svs + parameters.dev_sv_offsets[selected_event_number];
      const auto number_of_vertices_in_event =
        parameters.dev_sv_offsets[selected_event_number + 1] - parameters.dev_sv_offsets[selected_event_number];

      // Fetch ODIN info.
      const char* event_odin_data = parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number];

      // Fetch number of velo tracks.
      const uint n_velo_tracks =
        parameters.dev_velo_offsets[selected_event_number + 1] - parameters.dev_velo_offsets[selected_event_number];

      // Process all lines
      Hlt1::Traverse<T>::traverse(
        parameters.dev_sel_results,
        parameters.dev_sel_results_offsets,
        parameters.dev_offsets_forward_tracks,
        parameters.dev_sv_offsets,
        event_tracks,
        event_vertices,
        event_odin_data,
        n_velo_tracks,
        selected_event_number,
        number_of_tracks_in_event,
        number_of_vertices_in_event);
    }
  }

  template<typename T, typename U, char... S>
  struct run_hlt1_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(run_hlt1<U>)) function {run_hlt1<U>};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      const auto total_number_of_events =
        std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

      set_size<dev_sel_results_t>(arguments, 1000 * total_number_of_events * std::tuple_size<U>::value);
      set_size<dev_sel_results_offsets_t>(arguments, std::tuple_size<U>::value + 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto total_number_of_events =
        std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

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

      const auto lambda_special_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = total_number_of_events;
      };
      Hlt1::TraverseLines<U, Hlt1::SpecialLine, decltype(lambda_special_fn)>::traverse(lambda_special_fn);

      const auto lambda_velo_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_selected_events_t>(arguments);
      };
      Hlt1::TraverseLines<U, Hlt1::VeloLine, decltype(lambda_velo_fn)>::traverse(lambda_velo_fn);
      
      // Prefix sum
      host_prefix_sum::host_prefix_sum_impl(host_buffers.host_sel_results_atomics, std::tuple_size<U>::value);

      cudaCheck(cudaMemcpyAsync(
        begin<dev_sel_results_offsets_t>(arguments),
        host_buffers.host_sel_results_atomics,
        size<dev_sel_results_offsets_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      initialize<dev_sel_results_t>(arguments, 0, cuda_stream);

      function(dim3(total_number_of_events), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_event_list_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_odin_raw_input_t>(arguments),
                    begin<dev_odin_raw_input_offsets_t>(arguments),
                    begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_offsets_t>(arguments)},
        value<host_number_of_selected_events_t>(arguments),
        event_start);

      if (runtime_options.do_check) {
        safe_assign_to_host_buffer<dev_sel_results_t>(
          host_buffers.host_sel_results, host_buffers.host_sel_results_size, arguments, cuda_stream);
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace run_hlt1
