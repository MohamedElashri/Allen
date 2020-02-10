#pragma once

#include "HltSelReport.cuh"
#include "ParKalmanDefinitions.cuh"
#include "RawBanksDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace package_sel_reports {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_sel_rep_words_t, uint);
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_OUTPUT(dev_sel_rb_hits_t, uint) dev_sel_rb_hits;
    DEVICE_OUTPUT(dev_sel_rb_stdinfo_t, uint) dev_sel_rb_stdinfo;
    DEVICE_OUTPUT(dev_sel_rb_objtyp_t, uint) dev_sel_rb_objtyp;
    DEVICE_OUTPUT(dev_sel_rb_substr_t, uint) dev_sel_rb_substr;
    DEVICE_OUTPUT(dev_sel_rep_raw_banks_t, uint) dev_sel_rep_raw_banks;
    DEVICE_OUTPUT(dev_sel_rep_offsets_t, uint) dev_sel_rep_offsets;
    DEVICE_OUTPUT(dev_passing_event_list_t, uint) dev_passing_event_list;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimension X", 256);
  };

  __global__ void package_sel_reports(Parameters, const uint number_of_events);

  template<typename T, char... S>
  struct package_sel_reports_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(package_sel_reports)) function {package_sel_reports};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_sel_rep_raw_banks_t>(arguments, value<host_number_of_sel_rep_words_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_sel_rep_raw_banks_t>(arguments, 0, cuda_stream);

      const auto grid_size = dim3(
        (value<host_number_of_selected_events_t>(arguments) + property<block_dim_x_t>() - 1) /
        property<block_dim_x_t>());

      function(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
        Parameters {begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sel_rb_hits_t>(arguments),
                    begin<dev_sel_rb_stdinfo_t>(arguments),
                    begin<dev_sel_rb_objtyp_t>(arguments),
                    begin<dev_sel_rb_substr_t>(arguments),
                    begin<dev_sel_rep_raw_banks_t>(arguments),
                    begin<dev_sel_rep_offsets_t>(arguments),
                    begin<dev_passing_event_list_t>(arguments)},
        host_buffers.host_number_of_passing_events[0]);

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_sel_rep_offsets,
        begin<dev_sel_rep_offsets_t>(arguments),
        size<dev_sel_rep_offsets_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
      
      safe_assign_to_host_buffer<dev_sel_rep_raw_banks_t>(
        host_buffers.host_sel_rep_raw_banks, host_buffers.host_sel_rep_raw_banks_size, arguments, cuda_stream);
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace package_sel_reports