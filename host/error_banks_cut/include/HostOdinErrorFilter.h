/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include <gsl/span>
#include "InputProvider.h"

namespace host_odin_error_filter {
  struct Parameters {
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list;
    HOST_OUTPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    DEVICE_OUTPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list;
  };

  // Algorithm
  struct host_odin_error_filter_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;
  };
} // namespace host_odin_error_filter
