/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "UTRaw.cuh"
#include <MEPTools.h>
#include "UTDecoder.cuh"

namespace ut_decoding_get_bank_offsets {
  struct Parameters {
    // Basics
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Rawbank
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    DEVICE_INPUT(dev_ut_raw_input_t, char) dev_ut_raw_input;
    DEVICE_INPUT(dev_ut_raw_input_offsets_t, unsigned) dev_ut_raw_input_offsets;
    DEVICE_INPUT(dev_ut_raw_input_sizes_t, unsigned) dev_ut_raw_input_sizes;
    DEVICE_INPUT(dev_ut_raw_input_types_t, unsigned) dev_ut_raw_input_types;
    // Outputs
    HOST_OUTPUT(host_total_number_of_ut_banks_t, unsigned) host_total_number_of_ut_banks;
    DEVICE_OUTPUT(dev_ut_banks_offsets_t, unsigned) dev_ut_banks_offsets;
  };

  struct ut_decoding_get_bank_offsets_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants& constants)
      const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };

  template<bool mep>
  __global__ void
  ut_decoding_get_number_of_banks(Parameters parameters, unsigned event_start, unsigned event_list_size);

} // namespace ut_decoding_get_bank_offsets
