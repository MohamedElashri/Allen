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
  __device__ static std::tuple<const ODINData&>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned)
  {
    return std::forward_as_tuple(parameters.dev_odin_data[event_number]);
  }
};
