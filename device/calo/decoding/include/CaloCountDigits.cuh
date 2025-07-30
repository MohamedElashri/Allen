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

#include "CaloGeometry.cuh"
#include "AlgorithmTypes.cuh"

namespace calo_count_digits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_digits_offsets_t, unsigned) dev_digits_offsets;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  __global__ void calo_count_digits(Parameters parameters, unsigned const n_events, char const* dev_ecal_geometry);

  // Algorithm
  struct calo_count_digits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 256, "block dimension X"};
  };
} // namespace calo_count_digits
