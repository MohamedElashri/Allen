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

#include "Line.cuh"

/**
 * @brief A line that executes only once per event.
 */
template<typename Derived, typename Parameters>
struct EventLine : public Line<Derived, Parameters> {
  __device__ static unsigned offset(const Parameters&, const unsigned event_number) { return event_number; }

  /**
   * @brief Decision size is the number of events.
   */
  static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
  {
    return arguments.template first<typename Parameters::host_number_of_events_t>();
  }
};
