#pragma once

#include "DeviceAlgorithm.cuh"

namespace copy_odin_to_device {
  struct Parameters {
    DEVICE_OUTPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_OUTPUT(dev_odin_raw_input_offsets_t, uint) dev_odin_raw_input_offsets;
  };

  template<typename T>
  __global__ void copy_odin_to_device(Parameters);

  template<typename T, typename U, char... S>
  struct copy_odin_to_device_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_odin_raw_input_t>(arguments, std::get<1>(runtime_options.host_odin_events));
      set_size<dev_odin_raw_input_offsets_t>(
        arguments, std::get<2>(runtime_options.host_odin_events).size_bytes() / sizeof(uint));
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
    }

  private:
  };
} // namespace copy_odin_to_device

// Implementation of copy_odin_to_device
