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
  /**
   * @brief Set the tag to event_iteration_tag, to mark how to iterate events.
   */
  using iteration_t = LineIteration::event_iteration_tag;

  /**
   * @brief Execute with a block dimension of 512.
   */
  static unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) { return 512; }

  /**
   * @brief Decision size is the number of events.
   */
  static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
  {
    return first<typename Parameters::host_number_of_events_t>(arguments);
  }
};
