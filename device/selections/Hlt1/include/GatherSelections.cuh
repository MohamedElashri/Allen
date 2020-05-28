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
    (DEVICE_INPUT_AGGREGATE(dev_input_selections_t, gather_selections::dev_input_selections_t::tuple_t),
     dev_input_selections),
    (HOST_OUTPUT(host_selections_offsets_t, unsigned), host_selections_offsets),
    (DEVICE_OUTPUT(dev_selections_t, bool), dev_selections),
    (DEVICE_OUTPUT(dev_selections_offsets_t, unsigned), dev_selections_offsets))

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
  };
} // namespace gather_selections