/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "HostAlgorithm.cuh"
#include "GenericContainerContracts.h"
#include "RoutingBitsConfiguration.cuh"

namespace host_routingbits_configuration {
  struct Parameters {
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_INPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    HOST_OUTPUT(host_routingbits_associatedlines_t, RoutingBitsConfiguration::AssociatedLines) host_routingbits_associatedlines;
    DEVICE_OUTPUT(dev_routingbits_associatedlines_t, RoutingBitsConfiguration::AssociatedLines) dev_routingbits_associatedlines;
  };

  /**
   * @brief Implementation of routing bits configuration on the host.
   */
  void host_routingbits_conf_impl(
    unsigned number_of_active_lines,
    char* names_of_active_lines,
    RoutingBitsConfiguration::AssociatedLines* routingbits_associatedlines,
    const RoutingBitsConfiguration::RoutingBits* dev_routingbits_conf);

  struct host_routingbits_configuration_t : public HostAlgorithm, Parameters {

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context&) const;
  };
} // namespace host_routingbits_configuration
