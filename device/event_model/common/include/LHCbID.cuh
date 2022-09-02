/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file LHCbID.cuh
 *
 * @brief encapsulate an LHCbID
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 */
#pragma once
#include "BackendCommon.h"

using LHCbID = unsigned;

namespace lhcb_id {
  /// Offsets of bitfield lhcbID
  static constexpr auto detectorTypeBits = 28;
  enum lhcbIDMasks { IDMask = 0xfffffffL, detectorTypeMask = 0xf0000000L };

  enum class LHCbIDType {
    Plume,
    VELO = 0x8,
    UT = 0xb,
    reserved_magnet_sidestations,
    FT = 0xa,
    reserved_mighty_tracker,
    reserved_torch,
    Rich,
    Calo,
    Muon
  };
  __host__ __device__ inline unsigned detector_type_lhcbid(const unsigned id)
  {
    return (unsigned) ((id & lhcbIDMasks::detectorTypeMask) >> detectorTypeBits);
  }
  __host__ __device__ inline unsigned set_detector_type_id(LHCbIDType t, const unsigned id)
  {
    return ((static_cast<unsigned int>(t) << detectorTypeBits) & detectorTypeMask) | (id & IDMask);
  }

  __host__ __device__ inline bool is_velo(const unsigned id)
  {
    return detector_type_lhcbid(id) == (unsigned) LHCbIDType::VELO;
  }

  __host__ __device__ inline bool is_ut(const unsigned id)
  {
    return detector_type_lhcbid(id) == (unsigned) LHCbIDType::UT;
  }

  __host__ __device__ inline bool is_scifi(const unsigned id)
  {
    return detector_type_lhcbid(id) == (unsigned) LHCbIDType::FT;
  }
} // namespace lhcb_id
