/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <gsl/span>

#include <Common.h>
#include <AlgorithmTypes.cuh>
#include <ODINBank.cuh>
#include <TAE.h>

namespace host_tae_filter {
  struct Parameters {
    HOST_INPUT(host_event_list_t, unsigned) host_event_list;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_odin_data_t, ODINData) host_odin_data;
    HOST_OUTPUT(host_number_of_tae_events_t, unsigned) host_number_of_tae_events;
    HOST_OUTPUT(host_tae_events_t, TAE::TAEEvent) host_tae_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    HOST_OUTPUT(host_output_event_list_t, unsigned) host_output_event_list;
    HOST_OUTPUT(host_mask_event_list_t, unsigned) host_mask_event_list;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_output_list_t) dev_event_output_list;
  };

  // Algorithm
  struct host_tae_filter_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<bool> m_accept_sub_events {this,
                                               "accept_sub_events",
                                               true,
                                               "Accept all sub events of a TAE batch as separate events"};
  };
} // namespace host_tae_filter
