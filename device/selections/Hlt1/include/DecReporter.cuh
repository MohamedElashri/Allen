/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"

namespace dec_reporter {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_OUTPUT(dev_selected_candidates_counts_t, unsigned) dev_selected_candidates_counts;
    DEVICE_OUTPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    HOST_OUTPUT(host_dec_reports_t, unsigned) host_dec_reports;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(tck_t, "tck", "TCK", unsigned) tck;
    PROPERTY(encoding_key_t, "encoding_key", "encoding key", unsigned) key;
    PROPERTY(task_id_t, "task_is", "Task ID", unsigned) task_id;
  };

  __global__ void dec_reporter(Parameters);

  struct dec_reporter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
    Property<tck_t> m_tck {this, 0};
    Property<encoding_key_t> m_key {this, 0xDEADBEEF}; // FIXME
    Property<task_id_t> m_taskID {this, 1};
  };
} // namespace dec_reporter
