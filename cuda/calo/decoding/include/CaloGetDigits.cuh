#pragma once

#include "CaloRawEvent.cuh"
#include "CaloRawBanks.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

#define ECAL_BANKS 28
#define HCAL_BANKS 8
#define CARD_CHANNELS 32
#define MAX_CELLID 0b100000000000000


namespace calo_get_digits {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_OUTPUT(dev_ecal_raw_input_t, char) dev_ecal_raw_input;
    DEVICE_OUTPUT(dev_ecal_raw_input_offsets_t, uint) dev_ecal_raw_input_offsets;
    DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_OUTPUT(dev_hcal_raw_input_t, char) dev_hcal_raw_input;
    DEVICE_OUTPUT(dev_hcal_raw_input_offsets_t, uint) dev_hcal_raw_input_offsets;
    DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit) dev_hcal_digits;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimension X", 32);
  };

  // Global function
  __global__ void calo_get_digits(Parameters parameters, const uint number_of_events,
                                  const char* dev_ecal_geometry, const char* dev_hcal_geometry);
  __global__ void calo_get_digits_mep(Parameters parameters, const uint number_of_events,
                                      const char* dev_ecal_geometry, const char* dev_hcal_geometry);

  // Algorithm
  template<typename T, char... S>
  struct calo_get_digits_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(calo_get_digits)) function {calo_get_digits};
    decltype(global_function(calo_get_digits_mep)) function_mep {
      calo_get_digits_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ecal_raw_input_t>(arguments, std::get<1>(runtime_options.host_ecal_events));
      set_size<dev_ecal_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_ecal_events).size_bytes() / sizeof(uint));
      set_size<dev_hcal_raw_input_t>(arguments, std::get<1>(runtime_options.host_hcal_events));
      set_size<dev_hcal_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_hcal_events).size_bytes() / sizeof(uint));

      set_size<dev_ecal_digits_t>(arguments, MAX_CELLID * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_hcal_digits_t>(arguments, MAX_CELLID * value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
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
                                  begin<dev_ecal_digits_t>(arguments),
                                  begin<dev_hcal_raw_input_t>(arguments),
                                  begin<dev_hcal_raw_input_offsets_t>(arguments),
                                  begin<dev_hcal_digits_t>(arguments)};
      if (runtime_options.mep_layout) {
        function_mep(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
          parameters, value<host_number_of_selected_events_t>(arguments),
          constants.dev_ecal_geometry, constants.dev_hcal_geometry);
      }
      else {
        function(grid_size, dim3(property<block_dim_x_t>().get()), cuda_stream)(
          parameters, value<host_number_of_selected_events_t>(arguments),
          constants.dev_ecal_geometry, constants.dev_hcal_geometry);
      }
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace calo_get_digits
