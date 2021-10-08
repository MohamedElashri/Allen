/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"

namespace host_init_event_list {
  struct Parameters {
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list;
  };

  // Algorithm
  struct host_init_event_list_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;
  };
} // namespace host_init_event_list