/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "EventLine.cuh"
#include "ODINBank.cuh"

/**
 * @brief An ODIN line.
 *
 * It assumes an inheriting class will have the following inputs:
 *
 * It also assumes the ODINLine will be defined as:
 */
template<typename Derived, typename Parameters>
struct ODINLine : public EventLine<Derived, Parameters> {
  __device__ std::tuple<const unsigned*> get_input(const Parameters& parameters, const unsigned event_number) const
  {
    const unsigned* event_odin_data = nullptr;
    if (parameters.dev_mep_layout[0]) {
      event_odin_data = odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
    } else {
      event_odin_data = odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
    }
    return std::forward_as_tuple(event_odin_data);
  }
};
