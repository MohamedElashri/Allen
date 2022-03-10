/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "GenericContainerContracts.h"
#include "RoutingBitsDefinition.h"
#include "boost/regex.hpp"

namespace host_routingbits_writer {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_INPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    HOST_INPUT(host_dec_reports_t, unsigned) host_dec_reports;
    HOST_OUTPUT(host_routingbits_t, unsigned) host_routingbits;
    PROPERTY(
      routingbit_map_t,
      "routingbit_map",
      "mapping of expressions to routing bits",
      std::map<uint32_t, std::string>)
    routingbit_map;
  };

  /**
   * @brief Implementation of routing bits writer on the host.
   */
  std::map<uint32_t, boost::regex> m_regex_map;

  void host_routingbits_conf_impl(
    unsigned host_number_of_events,
    unsigned number_of_active_lines,
    char* names_of_active_lines,
    unsigned* host_dec_reports,
    unsigned* host_routing_bits,
    const std::map<uint32_t, boost::regex>& routingbit_map);

  struct host_routingbits_writer_t : public HostAlgorithm, Parameters {
    void init() const;

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

  private:
    Property<routingbit_map_t> m_routingbit_map {this, RoutingBitsDefinition::default_routingbit_map};
  };
} // namespace host_routingbits_writer
