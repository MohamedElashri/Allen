/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <gsl/gsl>

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include <ODINBank.cuh>

namespace odin_provider {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_mep_layout_t, unsigned) host_mep_layout;
    DEVICE_OUTPUT(dev_odin_data_t, ODINData) dev_odin_data;
    HOST_OUTPUT(host_odin_data_t, ODINData) host_odin_data;
    HOST_OUTPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    DEVICE_OUTPUT(dev_event_mask_t, unsigned) dev_event_mask;
  };

  struct odin_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;
  };
} // namespace odin_provider
