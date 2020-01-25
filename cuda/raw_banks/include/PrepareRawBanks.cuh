#pragma once

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LineInfo.cuh"

namespace prepare_raw_banks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_INPUT(dev_sel_results_atomics_t, uint) dev_sel_results_atomics;
    DEVICE_OUTPUT(dev_dec_reports_t, uint) dev_dec_reports;
    DEVICE_OUTPUT(dev_number_of_passing_events_t, uint) dev_number_of_passing_events;
    DEVICE_OUTPUT(dev_passing_event_list_t, uint) dev_passing_event_list;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void prepare_raw_banks(Parameters);

  template<typename T, char... S>
  struct prepare_raw_banks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(prepare_raw_banks)) function {prepare_raw_banks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto n_hlt1_lines = Hlt1::Hlt1Lines::End;
      set_size<dev_dec_reports_t>(arguments, (2 + n_hlt1_lines) * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_number_of_passing_events_t>(arguments, 1);
      set_size<dev_passing_event_list_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      // Initialize number of events passing Hlt1.
      cudaCheck(cudaMemsetAsync(begin<dev_number_of_passing_events_t>(arguments), 0, sizeof(uint), cuda_stream));

      cudaCheck(
        cudaMemsetAsync(begin<dev_dec_reports_t>(arguments), 0, size<dev_dec_reports_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_event_list_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_atomics_t>(arguments),
                    begin<dev_dec_reports_t>(arguments),
                    begin<dev_number_of_passing_events_t>(arguments),
                    begin<dev_passing_event_list_t>(arguments)});

      // Copy raw bank data.
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_dec_reports,
        begin<dev_dec_reports_t>(arguments),
        size<dev_dec_reports_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      // Copy list of passing events.
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_number_of_passing_events,
        begin<dev_number_of_passing_events_t>(arguments),
        size<dev_number_of_passing_events_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_passing_event_list,
        begin<dev_passing_event_list_t>(arguments),
        size<dev_passing_event_list_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace prepare_raw_banks
