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
    DEVICE_INPUT(dev_selections_t, uint32_t) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;

    HOST_OUTPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_OUTPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    HOST_OUTPUT(host_lumi_summaries_count_t, unsigned) host_lumi_summaries_count;
    DEVICE_OUTPUT(dev_lumi_event_indices_t, unsigned) dev_lumi_event_indices;
  };

  __global__ void calc_lumi_sum_size(
    Parameters,
    const unsigned number_of_events,
    const unsigned line_index,
    const unsigned line_index_full,
    const unsigned lumi_sum_length_full,
    const unsigned lumi_sum_length);

  struct calc_lumi_sum_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_line_index {this, "line_index", 0, "index of lumi line"};
    Allen::Property<unsigned> m_line_index_full {this, "line_index_full", 0, "index of 1kHz lumi line"};
    Allen::Property<unsigned> m_lumi_sum_length {this, "lumi_sum_length", 0u, "LumiSummary length"};
    Allen::Property<unsigned> m_lumi_sum_length_full {this,
                                                      "lumi_sum_length_full",
                                                      0u,
                                                      "LumiSummary length for the 1kHz line"};
  };
} // namespace calc_lumi_sum_size
