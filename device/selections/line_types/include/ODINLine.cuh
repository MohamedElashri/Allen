/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
  __device__ static std::tuple<const ODINData>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned)
  {
    return {parameters.dev_odin_data[event_number]};
  }
};
