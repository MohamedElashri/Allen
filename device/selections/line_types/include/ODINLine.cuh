#pragma once

#include "EventLine.cuh"
#include "ParKalmanFilter.cuh"

/**
 * @brief An ODIN line.
 *
 * It assumes an inheriting class will have the following inputs:
 *
 * It also assumes the ODINLine will be defined as:
 */
template<typename Derived, typename Parameters>
struct ODINLine : public EventLine<Derived, Parameters> {
  __device__ std::tuple<const char*> get_input(const Parameters& parameters, const unsigned event_number) const
  {
    const char* event_odin_data = parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number];
    return std::forward_as_tuple(event_odin_data);
  }
};
