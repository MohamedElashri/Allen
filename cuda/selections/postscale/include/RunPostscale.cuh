#pragma once

#include "DeviceAlgorithm.cuh"

namespace run_postscale {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_OUTPUT(dev_odin_raw_input_offsets_t, uint) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_OUTPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_OUTPUT(dev_sel_results_offsets_t, uint) dev_sel_results_offsets;
    PROPERTY(factor_one_track_t, float, "factor_one_track", "postscale for one-track line", 1.f) factor_one_track;
    PROPERTY(factor_single_muon_t, float, "factor_single_muon", "postscale for single-muon line", 1.f)
    factor_single_muon;
    PROPERTY(factor_two_tracks_t, float, "factor_two_tracks", "postscale for two-track line", 1.f) factor_two_tracks;
    PROPERTY(factor_disp_dimuon_t, float, "factor_disp_dimuon", "postscale for displaced-dimuon line", 1.f)
    factor_disp_dimuon;
    PROPERTY(factor_high_mass_dimuon_t, float, "factor_high_mass_dimuon", "postscale for high-mass-dimuon line", 1.f)
    factor_high_mass_dimuon;
    PROPERTY(factor_dimuon_soft_t, float, "factor_dimuon_soft", "postscale for soft-dimuon line", 1.f)
    factor_dimuon_soft;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  template<typename T>
  __global__ void run_postscale(Parameters);

  template<typename T, typename U, char... S>
  struct run_postscale_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(run_postscale<U>)) function {run_postscale<U>};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_odin_raw_input_t>(arguments, std::get<1>(runtime_options.host_odin_events));
      set_size<dev_odin_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_odin_events).size_bytes() / sizeof(uint));
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
      data_to_device<dev_odin_raw_input_t, dev_odin_raw_input_offsets_t>(
        arguments, runtime_options.host_odin_events, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_odin_raw_input_t>(arguments),
                    begin<dev_odin_raw_input_offsets_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_offsets_t>(arguments),
                    property<factor_one_track_t>(),
                    property<factor_single_muon_t>(),
                    property<factor_two_tracks_t>(),
                    property<factor_disp_dimuon_t>(),
                    property<factor_high_mass_dimuon_t>(),
                    property<factor_dimuon_soft_t>()});

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
    Property<factor_one_track_t> m_factor_one_track {this};
    Property<factor_single_muon_t> m_factor_single_muon {this};
    Property<factor_two_tracks_t> m_factor_two_tracks {this};
    Property<factor_disp_dimuon_t> m_factor_disp_dimuon {this};
    Property<factor_high_mass_dimuon_t> m_factor_high_mass_dimuon {this};
    Property<factor_dimuon_soft_t> m_factor_dimuon_soft {this};
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace run_postscale

// Implementation of run_postscale
#include "RunPostscale.icc"