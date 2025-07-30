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

#include <string>
#include <ostream>
#include "BackendCommon.h"

namespace Allen {
  class RichSmartID {
    uint64_t m_key;

  public:
    RichSmartID() = default;

    __host__ __device__ RichSmartID(uint64_t key) : m_key(key) {}

    // Number of bits for each data field in the word
    static constexpr const unsigned BitsPixelCol = 3;   ///< Number of bits for MaPMT pixel column
    static constexpr const unsigned BitsPixelRow = 3;   ///< Number of bits for MaPMT pixel row
    static constexpr const unsigned BitsPDNumInMod = 4; ///< Number of bits for MaPMT 'number in module'
    static constexpr const unsigned BitsPDMod = 9;      ///< Number of bits for MaPMT module
    static constexpr const unsigned BitsPanel = 1;      ///< Number of bits for MaPMT panel
    static constexpr const unsigned BitsRich = 1;       ///< Number of bits for RICH detector
    static constexpr const unsigned BitsPixelSubRowIsSet = 1;
    static constexpr const unsigned BitsPixelColIsSet = 1;
    static constexpr const unsigned BitsPixelRowIsSet = 1;
    static constexpr const unsigned BitsPDIsSet = 1;
    static constexpr const unsigned BitsPanelIsSet = 1;
    static constexpr const unsigned BitsRichIsSet = 1;
    static constexpr const unsigned BitsLargePixel = 1;

    // The shifts
    static constexpr const unsigned ShiftPixelCol = 0;
    static constexpr const unsigned ShiftPixelRow = ShiftPixelCol + BitsPixelCol;
    static constexpr const unsigned ShiftPDNumInMod = ShiftPixelRow + BitsPixelRow;
    static constexpr const unsigned ShiftPDMod = ShiftPDNumInMod + BitsPDNumInMod;
    static constexpr const unsigned ShiftPanel = ShiftPDMod + BitsPDMod;
    static constexpr const unsigned ShiftRich = ShiftPanel + BitsPanel;
    static constexpr const unsigned ShiftPixelSubRowIsSet = ShiftRich + BitsRich;
    static constexpr const unsigned ShiftPixelColIsSet = ShiftPixelSubRowIsSet + BitsPixelSubRowIsSet;
    static constexpr const unsigned ShiftPixelRowIsSet = ShiftPixelColIsSet + BitsPixelColIsSet;
    static constexpr const unsigned ShiftPDIsSet = ShiftPixelRowIsSet + BitsPixelRowIsSet;
    static constexpr const unsigned ShiftPanelIsSet = ShiftPDIsSet + BitsPDIsSet;
    static constexpr const unsigned ShiftRichIsSet = ShiftPanelIsSet + BitsPanelIsSet;
    static constexpr const unsigned ShiftLargePixel = ShiftRichIsSet + BitsRichIsSet;

    // The masks
    static constexpr const unsigned MaskPixelCol = (unsigned) ((1 << BitsPixelCol) - 1) << ShiftPixelCol;
    static constexpr const unsigned MaskPixelRow = (unsigned) ((1 << BitsPixelRow) - 1) << ShiftPixelRow;
    static constexpr const unsigned MaskPDNumInMod = (unsigned) ((1 << BitsPDNumInMod) - 1) << ShiftPDNumInMod;
    static constexpr const unsigned MaskPDMod = (unsigned) ((1 << BitsPDMod) - 1) << ShiftPDMod;
    static constexpr const unsigned MaskPanel = (unsigned) ((1 << BitsPanel) - 1) << ShiftPanel;
    static constexpr const unsigned MaskRich = (unsigned) ((1 << BitsRich) - 1) << ShiftRich;
    static constexpr const unsigned MaskPixelSubRowIsSet = (unsigned) ((1 << BitsPixelSubRowIsSet) - 1)
                                                           << ShiftPixelSubRowIsSet;
    static constexpr const unsigned MaskPixelColIsSet = (unsigned) ((1 << BitsPixelColIsSet) - 1) << ShiftPixelColIsSet;
    static constexpr const unsigned MaskPixelRowIsSet = (unsigned) ((1 << BitsPixelRowIsSet) - 1) << ShiftPixelRowIsSet;
    static constexpr const unsigned MaskPDIsSet = (unsigned) ((1 << BitsPDIsSet) - 1) << ShiftPDIsSet;
    static constexpr const unsigned MaskPanelIsSet = (unsigned) ((1 << BitsPanelIsSet) - 1) << ShiftPanelIsSet;
    static constexpr const unsigned MaskRichIsSet = (unsigned) ((1 << BitsRichIsSet) - 1) << ShiftRichIsSet;
    static constexpr const unsigned MaskLargePixel = (unsigned) ((1 << BitsLargePixel) - 1) << ShiftLargePixel;

    // Max Values
    static constexpr const unsigned MaxPixelCol = (unsigned) (1 << BitsPixelCol) - 1;
    static constexpr const unsigned MaxPixelRow = (unsigned) (1 << BitsPixelRow) - 1;
    static constexpr const unsigned MaxPDNumInMod = (unsigned) (1 << BitsPDNumInMod) - 1;
    static constexpr const unsigned MaxPDMod = (unsigned) (1 << BitsPDMod) - 1;
    static constexpr const unsigned MaxPanel = (unsigned) (1 << BitsPanel) - 1;
    static constexpr const unsigned MaxRich = (unsigned) (1 << BitsRich) - 1;

    __host__ __device__ constexpr inline void
    setData(const unsigned value, const unsigned shift, const unsigned mask) noexcept
    {
      m_key = ((static_cast<uint64_t>(value) << shift) & mask) | (m_key & ~mask);
    }

    __host__ __device__ constexpr inline void setData(
      const unsigned value, //
      const unsigned shift, //
      const unsigned mask,  //
      const unsigned okMask) noexcept
    {
      m_key = ((static_cast<uint64_t>(value) << shift) & mask) | (m_key & ~mask) | okMask;
    }

    __host__ __device__ constexpr inline uint64_t getData(const unsigned shift, const unsigned mask) const noexcept
    {
      return (m_key & mask) >> shift;
    }

    __host__ __device__ constexpr inline auto key() const noexcept { return m_key; }

    __host__ __device__ constexpr inline bool operator==(const RichSmartID& other) const noexcept
    {
      return m_key == other.key();
    }

    /// ostream operator
    __host__ friend std::ostream& operator<<(std::ostream& str, const RichSmartID& id) { return str << id.key(); }
  }; // namespace RichSmartID
} // namespace Allen

namespace Rich::Future::DAQ {
  enum DetectorType : std::int8_t {
    InvalidDetector = -1, ///< Unspecified Detector
    Rich1 = 0,            ///< RICH1 detector
    Rich2 = 1,            ///< RICH2 detector
    Rich = 1              ///< Single RICH detector
  };

  class PackedFrameSizes final {
  public:
    /// Packed type
    using IntType = std::uint8_t;

  private:
    // Bits for each Size
    static const IntType Bits0 = 4;
    static const IntType Bits1 = 4;
    // shifts
    static const IntType Shift0 = 0;
    static const IntType Shift1 = Shift0 + Bits0;
    // masks
    static const IntType Mask0 = (IntType)((1 << Bits0) - 1) << Shift0;
    static const IntType Mask1 = (IntType)((1 << Bits1) - 1) << Shift1;
    // max values
    static const IntType Max0 = (1 << Bits0) - 1;
    static const IntType Max1 = (1 << Bits1) - 1;

  public:
    /// Contructor from a single word
    __host__ __device__ explicit PackedFrameSizes(const IntType d) : m_data(d) {}

    /// Get the overall data
    __host__ __device__ inline IntType data() const noexcept { return m_data; }

    /// Get first size word
    __host__ __device__ inline IntType size0() const noexcept { return ((data() & Mask0) >> Shift0); }

    /// Get second size word
    __host__ __device__ inline IntType size1() const noexcept { return ((data() & Mask1) >> Shift1); }

    /// Get the total size
    __host__ __device__ inline auto totalSize() const noexcept { return size0() + size1(); }

  private:
    /// The data word
    IntType m_data {0};
  };
} // namespace Rich::Future::DAQ
