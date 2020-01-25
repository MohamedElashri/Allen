#pragma once

#include "TrackMVALines.cuh"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LineInfo.cuh"

namespace run_hlt1 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_OUTPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_OUTPUT(dev_sel_results_atomics_t, uint) dev_sel_results_atomics;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void run_hlt1(Parameters);

  template<typename T, char... S>
  struct run_hlt1_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(run_hlt1)) function {run_hlt1};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_sel_results_t>(
        arguments, 1000 * value<host_number_of_selected_events_t>(arguments) * Hlt1::Hlt1Lines::End);
      set_size<dev_sel_results_atomics_t>(arguments, 2 * Hlt1::Hlt1Lines::End + 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // TODO: Move this to its own visitor and add a GPU option.
      for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = 0;
      }
      for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      }
      for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = value<host_number_of_svs_t>(arguments);
      }
      for (uint i_line = 1; i_line <= Hlt1::Hlt1Lines::End; i_line++) {
        host_buffers.host_sel_results_atomics[Hlt1::Hlt1Lines::End + i_line] =
          host_buffers.host_sel_results_atomics[Hlt1::Hlt1Lines::End + i_line - 1] +
          host_buffers.host_sel_results_atomics[i_line - 1];
      }

      cudaCheck(cudaMemcpyAsync(
        begin<dev_sel_results_atomics_t>(arguments),
        host_buffers.host_sel_results_atomics,
        size<dev_sel_results_atomics_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      cudaCheck(cudaMemsetAsync(begin<dev_sel_results_t>(arguments), 0, size<dev_sel_results_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_atomics_t>(arguments)});

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
