/*g***************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsDefinition {
  const std::map<std::string, uint32_t> default_routingbit_map;

  static constexpr int bits_size = 32; // 32 routing bits for HLT1
  static constexpr int n_words = 4;    // 4 words  (HLT1, future use, HLT2, output streams)
} // namespace RoutingBitsDefinition
