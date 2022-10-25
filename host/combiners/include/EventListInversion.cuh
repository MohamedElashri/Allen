/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"

namespace event_list_inversion {
  struct Parameters {
    MASK_INPUT(dev_event_list_input_t) dev_event_list;
    HOST_OUTPUT(host_event_list_t, unsigned) host_event_list;
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list_output;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;
  };

  struct event_list_inversion_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;
  };
} // namespace event_list_inversion
