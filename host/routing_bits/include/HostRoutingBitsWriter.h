/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
    HOST_INPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    HOST_INPUT(host_dec_reports_t, unsigned) host_dec_reports;
    HOST_OUTPUT(host_routingbits_t, unsigned) host_routingbits;
  };

  /**
   * @brief Implementation of routing bits writer on the host.
   */

  void host_routingbits_impl(
    unsigned host_number_of_events,
    gsl::span<const unsigned> host_dec_reports,
    unsigned* host_routing_bits,
    const std::unordered_map<uint32_t, boost::dynamic_bitset<>>& rb_ids);

  struct host_routingbits_writer_t : public HostAlgorithm, Parameters {
    void init();

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    std::unordered_map<uint32_t, boost::dynamic_bitset<>> m_rb_ids;

    Allen::Property<std::map<std::string, uint32_t>> m_routingbit_map {this,
                                                                       "routingbit_map",
                                                                       {},
                                                                       "mapping of expressions to routing bits"};
    Allen::Property<std::map<std::string, uint32_t>> m_name_to_id_map {this,
                                                                       "name_to_id_map",
                                                                       {},
                                                                       "mapping of line names to decIDs"};
  };
} // namespace host_routingbits_writer
