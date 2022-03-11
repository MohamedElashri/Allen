/*g***************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsDefinition {
  const std::map<uint32_t, std::string> default_routingbit_map;

  static constexpr int bits_size = 32; // 32 routing bits for HLT1
  static constexpr int n_words = 4;    // 4 words  (ODIN, HLT1, HLT2, Markus)
} // namespace RoutingBitsDefinition
