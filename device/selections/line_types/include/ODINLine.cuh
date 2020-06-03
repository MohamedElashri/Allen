#pragma once

#include "Line.cuh"
#include "ParKalmanFilter.cuh"

/**
 * @brief An ODIN line.
 *
 * It assumes an inheriting class will have the following inputs:
 *
 * It also assumes the ODINLine will be defined as:
 */
template<typename Derived, typename Parameters>
struct ODINLine : public Line<Derived, Parameters> {
  using iteration_t = LineIteration::event_iteration_tag;

  unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { return 512; }

  /**
   * @brief Decision size is the number of events.
   */
  unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const
  {
    return first<typename Parameters::host_number_of_events_t>(arguments);
  }

  __device__ std::tuple<const char*>
  get_input(const Parameters& parameters, const unsigned event_number) const
  {
    const char* event_odin_data = parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number];
    return std::forward_as_tuple(event_odin_data);
  }
};
