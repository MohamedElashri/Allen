#pragma once

#include "DeviceAlgorithm.cuh"
#include "ODINLine.cuh"

namespace beam_crossing_line {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, uint), dev_odin_raw_input_offsets),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (PROPERTY(beam_crossing_type_t, "beam_crossing_type", "ODIN beam crossing type [0-3]", unsigned), beam_crossing_type))

  struct beam_crossing_line_t : public SelectionAlgorithm, Parameters, ODINLine<beam_crossing_line_t, Parameters> {
    __device__ bool select(const Parameters& parameters, std::tuple<const char*> input) const;

  private:
    Property<beam_crossing_type_t> m_beam_crossing_type {this, 0};
  };
} // namespace beam_crossing_line