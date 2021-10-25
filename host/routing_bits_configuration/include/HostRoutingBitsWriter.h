/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "HostAlgorithm.cuh"
#include "GenericContainerContracts.h"

namespace host_routingbits_writer {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_INPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    HOST_INPUT(host_dec_reports_t, unsigned) host_dec_reports;
    HOST_OUTPUT(host_routingbits_t, unsigned) host_routingbits;
  };

  /**
   * @brief Implementation of routing bits writer on the host.
   */
  void host_routingbits_conf_impl(
    unsigned host_number_of_events,
    unsigned number_of_active_lines,
    char* names_of_active_lines,
    unsigned* host_dec_reports,
    unsigned* host_routing_bits);

  struct host_routingbits_writer_t : public HostAlgorithm, Parameters {

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
} // namespace host_routingbits_writer
