#pragma once

#include "DeviceAlgorithm.cuh"

namespace populate_odin_banks {
  struct Parameters {
    DEVICE_OUTPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_OUTPUT(dev_odin_raw_input_offsets_t, uint) dev_odin_raw_input_offsets;
  };

  template<typename T>
  __global__ void populate_odin_banks(Parameters);

  template<typename T, typename U, char... S>
  struct populate_odin_banks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_odin_raw_input_t>(arguments, std::get<1>(runtime_options.host_odin_events));
      set_size<dev_odin_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_odin_events).size_bytes() / sizeof(uint));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      data_to_device<dev_odin_raw_input_t, dev_odin_raw_input_offsets_t>(
        arguments, runtime_options.host_odin_events, cuda_stream);
    }

  private:
  };
} // namespace populate_odin_banks

// Implementation of populate_odin_banks
