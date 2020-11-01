/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "SelectionAlgorithm.cuh"
#include "ODINLine.cuh"

namespace beam_crossing_line {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string),
     pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string),
     post_scaler_hash_string),
    (PROPERTY(beam_crossing_type_t, "beam_crossing_type", "ODIN beam crossing type [0-3]", unsigned),
     beam_crossing_type))

  struct beam_crossing_line_t : public SelectionAlgorithm, Parameters, ODINLine<beam_crossing_line_t, Parameters> {
    __device__ bool select(const Parameters& parameters, std::tuple<const unsigned*> input) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1e-3f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<beam_crossing_type_t> m_beam_crossing_type {this, 0};
  };
} // namespace beam_crossing_line
