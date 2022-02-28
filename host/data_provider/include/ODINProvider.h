/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include <gsl/gsl>
#include <Event/ODIN.h>

namespace odin_provider {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_mep_layout_t, unsigned) host_mep_layout;
    DEVICE_OUTPUT(dev_odin_t, LHCb::ODIN) dev_odin;
    HOST_OUTPUT(host_odin_t, LHCb::ODIN) host_odin;
    HOST_OUTPUT(host_raw_bank_version_t, int) host_raw_bank_version;
  };

  struct odin_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;
  };
} // namespace odin_provider
