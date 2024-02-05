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

namespace host_prefix_sum {
  struct Parameters {
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
    DEVICE_INPUT(dev_input_buffer_t, unsigned) dev_input_buffer;
    HOST_OUTPUT(host_output_buffer_t, unsigned) host_output_buffer;
    DEVICE_OUTPUT(dev_output_buffer_t, unsigned) dev_output_buffer;
  };

  /**
   * @brief Implementation of prefix sum on the host.
   */
  void host_prefix_sum_impl(
    unsigned* host_prefix_sum_buffer,
    const size_t input_number_of_elements,
    unsigned* host_total_sum_holder = nullptr);

  struct host_prefix_sum_t : public HostAlgorithm, Parameters {
    using contracts = std::tuple<
      Allen::contract::is_monotonically_increasing<host_output_buffer_t, Parameters, Allen::contract::Postcondition>,
      Allen::contract::
        are_equal<host_output_buffer_t, dev_output_buffer_t, Parameters, Allen::contract::Postcondition>>;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };
} // namespace host_prefix_sum
