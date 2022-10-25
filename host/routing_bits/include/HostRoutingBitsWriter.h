/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "GenericContainerContracts.h"
#include "RoutingBitsDefinition.h"
#include "boost/dynamic_bitset/dynamic_bitset.hpp"

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
      std::map<std::string, uint32_t>)
    routingbit_map;
    PROPERTY(name_to_id_map_t, "name_to_id_map", "mapping of line names to decIDs", std::map<std::string, uint32_t>)
    name_to_id_map;
  };

  /**
   * @brief Implementation of routing bits writer on the host.
   */

  void host_routingbits_impl(
    unsigned host_number_of_events,
    unsigned number_of_active_lines,
    unsigned* host_dec_reports,
    unsigned* host_routing_bits,
    const std::unordered_map<uint32_t, boost::dynamic_bitset<>>& rb_ids);

  struct host_routingbits_writer_t : public HostAlgorithm, Parameters {
    void init();

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    std::unordered_map<uint32_t, boost::dynamic_bitset<>> m_rb_ids;
    Property<routingbit_map_t> m_routingbit_map {this, {}};
    Property<name_to_id_map_t> m_name_to_id_map {this, {}};
  };
} // namespace host_routingbits_writer
