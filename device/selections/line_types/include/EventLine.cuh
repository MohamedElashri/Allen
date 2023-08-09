/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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
