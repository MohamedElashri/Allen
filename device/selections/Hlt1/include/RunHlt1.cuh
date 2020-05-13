#pragma once

#include "DeviceAlgorithm.cuh"
#include "DeviceLineTraverser.cuh"
#include "HostPrefixSum.h"
#include "ConfiguredLines.h"

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
    PROPERTY(factor_one_track_t, float, "factor_one_track", "postscale for one-track line") factor_one_track;
    PROPERTY(factor_single_muon_t, float, "factor_single_muon", "postscale for single-muon line")
    factor_single_muon;
    PROPERTY(factor_two_tracks_t, float, "factor_two_tracks", "postscale for two-track line") factor_two_tracks;
    PROPERTY(factor_disp_dimuon_t, float, "factor_disp_dimuon", "postscale for displaced-dimuon line")
    factor_disp_dimuon;
    PROPERTY(factor_high_mass_dimuon_t, float, "factor_high_mass_dimuon", "postscale for high-mass-dimuon line")
    factor_high_mass_dimuon;
    PROPERTY(factor_dimuon_soft_t, float, "factor_dimuon_soft", "postscale for soft-dimuon line")
    factor_dimuon_soft;

    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void run_hlt1(Parameters parameters, const uint selected_number_of_events, const uint event_start);

  __global__ void run_postscale(Parameters, const uint selected_number_of_events, const uint event_start);

  template<typename T>
  struct run_hlt1_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(run_hlt1)) hlt1_function {run_hlt1};
    decltype(global_function(run_postscale)) postscale_function {run_postscale};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      const auto total_number_of_events =
        std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

      set_size<dev_sel_results_t>(
        arguments, 1000 * total_number_of_events * std::tuple_size<configured_lines_t>::value);
      set_size<dev_sel_results_offsets_t>(arguments, std::tuple_size<configured_lines_t>::value + 1);
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
      for (uint i_line = 0; i_line < std::tuple_size<configured_lines_t>::value; i_line++) {
        host_buffers.host_sel_results_atomics[i_line] = 0;
      }

      const auto lambda_one_track_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      };
      Hlt1::TraverseLines<configured_lines_t, Hlt1::OneTrackLine, decltype(lambda_one_track_fn)>::traverse(
        lambda_one_track_fn);

      const auto lambda_two_track_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_svs_t>(arguments);
      };
      Hlt1::TraverseLines<configured_lines_t, Hlt1::TwoTrackLine, decltype(lambda_two_track_fn)>::traverse(
        lambda_two_track_fn);

      const auto lambda_special_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = total_number_of_events;
      };
      Hlt1::TraverseLines<configured_lines_t, Hlt1::SpecialLine, decltype(lambda_special_fn)>::traverse(
        lambda_special_fn);

      const auto lambda_velo_fn = [&](const unsigned long i_line) {
        host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_selected_events_t>(arguments);
      };
      Hlt1::TraverseLines<configured_lines_t, Hlt1::VeloLine, decltype(lambda_velo_fn)>::traverse(lambda_velo_fn);

      // Prefix sum
      host_prefix_sum::host_prefix_sum_impl(
        host_buffers.host_sel_results_atomics, std::tuple_size<configured_lines_t>::value);

      cudaCheck(cudaMemcpyAsync(
        data<dev_sel_results_offsets_t>(arguments),
        host_buffers.host_sel_results_atomics,
        size<dev_sel_results_offsets_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      initialize<dev_sel_results_t>(arguments, 0, cuda_stream);

      hlt1_function(dim3(total_number_of_events), property<block_dim_t>(), cuda_stream)(
        Parameters {
          data<dev_event_list_t>(arguments),
          data<dev_kf_tracks_t>(arguments),
          data<dev_consolidated_svs_t>(arguments),
          data<dev_offsets_forward_tracks_t>(arguments),
          data<dev_sv_offsets_t>(arguments),
          data<dev_odin_raw_input_t>(arguments),
          data<dev_odin_raw_input_offsets_t>(arguments),
          data<dev_offsets_all_velo_tracks_t>(arguments),
          data<dev_sel_results_t>(arguments),
          data<dev_sel_results_offsets_t>(arguments),
          property<factor_one_track_t>(),
          property<factor_single_muon_t>(),
          property<factor_two_tracks_t>(),
          property<factor_disp_dimuon_t>(),
          property<factor_high_mass_dimuon_t>(),
          property<factor_dimuon_soft_t>()},
        first<host_number_of_selected_events_t>(arguments),
        event_start);

      // Run the postscaler.
      postscale_function(dim3(total_number_of_events), property<block_dim_t>(), cuda_stream)(
        Parameters {
          data<dev_event_list_t>(arguments),
          data<dev_kf_tracks_t>(arguments),
          data<dev_consolidated_svs_t>(arguments),
          data<dev_offsets_forward_tracks_t>(arguments),
          data<dev_sv_offsets_t>(arguments),
          data<dev_odin_raw_input_t>(arguments),
          data<dev_odin_raw_input_offsets_t>(arguments),
          data<dev_offsets_all_velo_tracks_t>(arguments),
          data<dev_sel_results_t>(arguments),
          data<dev_sel_results_offsets_t>(arguments),
          property<factor_one_track_t>(),
          property<factor_single_muon_t>(),
          property<factor_two_tracks_t>(),
          property<factor_disp_dimuon_t>(),
          property<factor_high_mass_dimuon_t>(),
          property<factor_dimuon_soft_t>()},
        first<host_number_of_selected_events_t>(arguments),
        event_start);

      if (runtime_options.do_check) {
        safe_assign_to_host_buffer<dev_sel_results_t>(
          host_buffers.host_sel_results, host_buffers.host_sel_results_size, arguments, cuda_stream);
      }
    }

  private:
    Property<factor_one_track_t> m_factor_one_track {this, 1.f};
    Property<factor_single_muon_t> m_factor_single_muon {this, 1.f};
    Property<factor_two_tracks_t> m_factor_two_tracks {this, 1.f};
    Property<factor_disp_dimuon_t> m_factor_disp_dimuon {this, 1.f};
    Property<factor_high_mass_dimuon_t> m_factor_high_mass_dimuon {this, 1.f};
    Property<factor_dimuon_soft_t> m_factor_dimuon_soft {this, 1.f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace run_hlt1