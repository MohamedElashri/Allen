/** @file LHCbID.h
 *
 * @brief encapsulate an LHCbID
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 */

#pragma once

#include <vector>

using LHCbID = uint;
using LHCbIDs = std::vector<LHCbID>;

namespace lhcb_id {
  inline uint detector_type_lhcbid(const uint id) {
    return (uint) ((id & 0xF0000000L) >> 28);
  }

  inline bool is_velo(const uint id) {
    return detector_type_lhcbid(id) == 0x8;
  }

  inline bool is_ut(const uint id) {
    return detector_type_lhcbid(id) == 0xa;
  }

  inline bool is_scifi(const uint id) {
    return detector_type_lhcbid(id) == 0xb;
  }
}
