#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace layout_provider {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_OUTPUT(host_mep_layout_t, unsigned), host_mep_layout),
    (DEVICE_OUTPUT(dev_mep_layout_t, unsigned), dev_mep_layout))

  struct layout_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentRefManager<ParameterTuple<Parameters>::t> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentRefManager<ParameterTuple<Parameters>::t>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t&,
      cudaEvent_t&) const;
  };
} // namespace layout_provider
