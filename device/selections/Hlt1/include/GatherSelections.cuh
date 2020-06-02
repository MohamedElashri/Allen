#pragma once

#include "HostAlgorithm.cuh"

// Note: This include is required when aggregates are used in the parameter list
//       (ie. DEVICE_INPUT_AGGREGATE, HOST_INPUT_AGGREGATE).
//       This also requires that the relevant CMakeLists.txt depend on configured_sequence, ie.
//       add_dependencies(Selections configured_sequence)
#include "ConfiguredInputAggregates.h"

namespace gather_selections {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_OUTPUT(host_selections_lines_offsets_t, unsigned), host_selections_lines_offsets),
    (HOST_OUTPUT(host_selections_offsets_t, unsigned), host_selections_offsets),
    (DEVICE_INPUT_AGGREGATE(dev_input_selections_t, gather_selections::dev_input_selections_t::tuple_t),
     dev_input_selections),
    (DEVICE_INPUT_AGGREGATE(dev_input_selections_offsets_t, gather_selections::dev_input_selections_offsets_t::tuple_t),
     dev_input_selections_offsets),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_OUTPUT(dev_selections_t, bool), dev_selections),
    (DEVICE_OUTPUT(dev_selections_offsets_t, unsigned), dev_selections_offsets),
    (PROPERTY(scale_factor_t, "scale_factor", "scale factor of postscaler", float), scale_factor),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned), block_dim_x))

  struct gather_selections_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<scale_factor_t> m_scale_factor {this, 1.0f};
  };

  __global__ void postscaler(
    bool* dev_selections,
    const unsigned* dev_selections_offsets,
    const char* dev_odin_raw_input,
    const unsigned* dev_odin_raw_input_offsets,
    const unsigned number_of_lines,
    const float scale_factor);
} // namespace gather_selections