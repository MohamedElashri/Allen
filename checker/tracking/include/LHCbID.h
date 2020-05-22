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

using LHCbID = unsigned;
using LHCbIDs = std::vector<LHCbID>;

namespace lhcb_id {
  enum class LHCbIDType { VELO = 0x8, UT = 0xb, FT = 0xa };

  inline unsigned detector_type_lhcbid(const unsigned id) { return (unsigned)((id & 0xF0000000L) >> 28); }

  inline bool is_velo(const unsigned id) { return detector_type_lhcbid(id) == (unsigned) LHCbIDType::VELO; }

  inline bool is_ut(const unsigned id) { return detector_type_lhcbid(id) == (unsigned) LHCbIDType::UT; }

  inline bool is_scifi(const unsigned id) { return detector_type_lhcbid(id) == (unsigned) LHCbIDType::FT; }
} // namespace lhcb_id
