/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"

namespace calc_lumi_sum_size {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_OUTPUT(dev_lumi_sum_sizes_t, unsigned) dev_lumi_sum_sizes;
    DEVICE_OUTPUT(dev_lumi_sum_present_t, unsigned) dev_lumi_sum_present;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(line_index_t, "line_index", "index of lumi line", unsigned) line_index;
    PROPERTY(line_index_full_t, "line_index_full", "index of 1kHz lumi line", unsigned) line_index_full;
    PROPERTY(lumi_sum_length_t, "lumi_sum_length", "LumiSummary length", unsigned) lumi_sum_length;
    PROPERTY(lumi_sum_length_full_t, "lumi_sum_length_full", "LumiSummary length for the 1kHz line", unsigned)
    lumi_sum_length_full;
  }; // struct Parameters

  __global__ void calc_lumi_sum_size(Parameters, const unsigned number_of_events);

  struct calc_lumi_sum_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<line_index_t> m_line_index {this, 0};
    Property<line_index_full_t> m_line_index_full {this, 0};
    Property<lumi_sum_length_t> m_lumi_sum_length {this, 0u};
    Property<lumi_sum_length_full_t> m_lumi_sum_length_full {this, 0u};
  }; // struct calc_lumi_sum_size_t
} // namespace calc_lumi_sum_size
