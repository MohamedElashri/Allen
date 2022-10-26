/*g***************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsDefinition {
  static constexpr int bits_size = 32; // 32 routing bits for HLT1
  static constexpr int n_words = 3;    // 3 words  (HLT1, future use, HLT2)
} // namespace RoutingBitsDefinition
