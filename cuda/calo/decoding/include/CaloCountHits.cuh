#pragma once

#include "CaloRawEvent.cuh"
#include "CaloRawBanks.cuh"
#include "DeviceAlgorithm.cuh"

#define ECAL_BANKS 28
#define HCAL_BANKS 8
#define CARD_CHANNELS 32


namespace calo_count_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_ecal_raw_input_t, char) dev_ecal_raw_input;
    DEVICE_OUTPUT(dev_ecal_raw_input_offsets_t, uint) dev_ecal_raw_input_offsets;
    DEVICE_OUTPUT(dev_ecal_number_of_hits_t, uint) dev_ecal_number_of_hits;
    DEVICE_OUTPUT(dev_hcal_raw_input_t, char) dev_hcal_raw_input;
    DEVICE_OUTPUT(dev_hcal_raw_input_offsets_t, uint) dev_hcal_raw_input_offsets;
    DEVICE_OUTPUT(dev_hcal_number_of_hits_t, uint) dev_hcal_number_of_hits;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimension X", 32);
  };

  // Global function
  __global__ void calo_count_hits(Parameters parameters, const uint number_of_events);
  __global__ void calo_count_hits_mep(Parameters parameters, const uint number_of_events);

  // Algorithm
  template<typename T, char... S>
  struct calo_count_hits_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(calo_count_hits)) function {calo_count_hits};
    decltype(global_function(calo_count_hits_mep)) function_mep {
      calo_count_hits_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ecal_raw_input_t>(arguments, std::get<1>(runtime_options.host_ecal_events));
      set_size<dev_ecal_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_ecal_events).size_bytes() / sizeof(uint));
      set_size<dev_ecal_number_of_hits_t>(
        arguments, ECAL_BANKS * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_hcal_raw_input_t>(arguments, std::get<1>(runtime_options.host_hcal_events));
      set_size<dev_hcal_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_hcal_events).size_bytes() / sizeof(uint));
      set_size<dev_hcal_number_of_hits_t>(
        arguments, HCAL_BANKS * value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      data_to_device<dev_ecal_raw_input_t, dev_ecal_raw_input_offsets_t>(
        arguments, runtime_options.host_ecal_events, cuda_stream);

      data_to_device<dev_hcal_raw_input_t, dev_hcal_raw_input_offsets_t>(
        arguments, runtime_options.host_hcal_events, cuda_stream);

      // Enough blocks to cover all events
      const auto grid_size = dim3(
        (value<host_number_of_selected_events_t>(arguments) + property<block_dim_x_t>() - 1) / property<block_dim_x_t>());

      // Invoke kernel
      const Parameters parameters{begin<dev_event_list_t>(arguments),
                                  begin<dev_ecal_raw_input_t>(arguments),
                                  begin<dev_ecal_raw_input_offsets_t>(arguments),
                                  begin<dev_ecal_number_of_hits_t>(arguments),
                                  begin<dev_hcal_raw_input_t>(arguments),
                                  begin<dev_hcal_raw_input_offsets_t>(arguments),
                                  begin<dev_hcal_number_of_hits_t>(arguments)};

      if (runtime_options.mep_layout) {
        function_mep(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
          parameters, value<host_number_of_selected_events_t>(arguments));
      }
      else {
        function(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
          parameters, value<host_number_of_selected_events_t>(arguments));
      }
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace calo_count_hits
