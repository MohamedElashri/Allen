#pragma once

#include "DeviceAlgorithm.cuh"
#include "RunHlt1Parameters.cuh"
#include "LineTraverser.cuh"

namespace run_hlt1 {
  template<typename T>
  __global__ void run_hlt1(Parameters parameters) {
      const uint event_number = blockIdx.x;
  
    // Fetch tracks
    const ParKalmanFilter::FittedTrack* event_tracks =
      parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[event_number];
    const auto number_of_tracks_in_event =
      parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];

    // Fetch vertices
    const VertexFit::TrackMVAVertex* event_vertices =
      parameters.dev_consolidated_svs + parameters.dev_sv_offsets[event_number];
    const auto number_of_vertices_in_event = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];

    // Process all lines
    Hlt1::Traverse<T>::traverse(parameters, event_tracks, event_vertices, event_number, number_of_tracks_in_event, number_of_vertices_in_event);
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
        arguments, 1000 * value<host_number_of_selected_events_t>(arguments) * Hlt1::Hlt1Lines::End);
      set_size<dev_sel_results_offsets_t>(arguments, Hlt1::Hlt1Lines::End + 1);
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
      for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = 0;
      }
      for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_reconstructed_scifi_tracks_t>(arguments)
          + host_buffers.host_sel_results_atomics[i_line - 1];
      }
      for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_svs_t>(arguments)
          + host_buffers.host_sel_results_atomics[i_line - 1];
      }

      cudaCheck(cudaMemcpyAsync(
        begin<dev_sel_results_offsets_t>(arguments),
        host_buffers.host_sel_results_atomics,
        size<dev_sel_results_offsets_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(begin<dev_sel_results_t>(arguments), 0, size<dev_sel_results_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
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
