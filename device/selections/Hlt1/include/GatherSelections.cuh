#pragma once

#include "HostAlgorithm.cuh"
#include "ConfiguredLines.h"

namespace gather_selections {
  DEFINE_PARAMETERS(
    Parameters,
    (DEVICE_OUTPUT(dev_selections_t, bool), dev_selections),
    (DEVICE_OUTPUT(dev_selections_offsets_t, unsigned), dev_selections_offsets))

  struct gather_selections_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_gather_selection_size(arguments);
    }

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const
    {
      gather_selection_operator(arguments, stream);
    }
  };
} // namespace gather_selections