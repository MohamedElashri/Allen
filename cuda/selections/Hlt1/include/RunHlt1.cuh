#pragma once

#include "TrackMVALines.cuh"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace run_hlt1 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_OUTPUT(dev_one_track_results_t, bool) dev_one_track_results;
    DEVICE_OUTPUT(dev_two_track_results_t, bool) dev_two_track_results;
    DEVICE_OUTPUT(dev_single_muon_results_t, bool) dev_single_muon_results;
    DEVICE_OUTPUT(dev_disp_dimuon_results_t, bool) dev_disp_dimuon_results;
    DEVICE_OUTPUT(dev_high_mass_dimuon_results_t, bool) dev_high_mass_dimuon_results;
    DEVICE_OUTPUT(dev_dimuon_soft_results_t, bool) dev_dimuon_soft_results;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
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
      set_size<dev_one_track_results_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_two_track_results_t>(arguments, value<host_number_of_svs_t>(arguments));
      set_size<dev_single_muon_results_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_disp_dimuon_results_t>(arguments, value<host_number_of_svs_t>(arguments));
      set_size<dev_high_mass_dimuon_results_t>(arguments, value<host_number_of_svs_t>(arguments));
      set_size<dev_dimuon_soft_results_t>(arguments, value<host_number_of_svs_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_one_track_results_t>(arguments),
                    begin<dev_two_track_results_t>(arguments),
                    begin<dev_single_muon_results_t>(arguments),
                    begin<dev_disp_dimuon_results_t>(arguments),
                    begin<dev_high_mass_dimuon_results_t>(arguments),
                    begin<dev_dimuon_soft_results_t>(arguments)});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_one_track_decisions,
          begin<dev_one_track_results_t>(arguments),
          size<dev_one_track_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_two_track_decisions,
          begin<dev_two_track_results_t>(arguments),
          size<dev_two_track_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_single_muon_decisions,
          begin<dev_single_muon_results_t>(arguments),
          size<dev_single_muon_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_disp_dimuon_decisions,
          begin<dev_disp_dimuon_results_t>(arguments),
          size<dev_disp_dimuon_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_high_mass_dimuon_decisions,
          begin<dev_high_mass_dimuon_results_t>(arguments),
          size<dev_high_mass_dimuon_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_dimuon_soft_decisions,
          begin<dev_dimuon_soft_results_t>(arguments),
          size<dev_dimuon_soft_results_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace run_hlt1
