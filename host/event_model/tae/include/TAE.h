/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

namespace TAE {
  inline unsigned max_tae_events(unsigned const n_events)
  {
    // For TAE events the minimum window size is 1, so 3 events for
    // frame. The maximum number of central TAE events is therefore at
    // most 1/3 of the number of events. For each central event we also
    // store the window size.
    return n_events / 3;
  }

  struct TAEEvent {
    unsigned central = 0;
    unsigned half_window = 0;
  };
} // namespace TAE
