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

#include <RichDefinitions.cuh>
#include <RichTel40CableMapping.cuh>

// STL
#include <array>
#include <cassert>
#include <cstdint>
#include <ostream>
#include <set>
#include <string>

namespace Rich::Future::DAQ::Allen {

  /// Helper class for RICH PDMDB readout mapping
  class PDMDBDecodeMapping final {
  public:
    // data types

    /// The data for each anode
    class BitData final {
    public:
      /// The EC number (0-3)
      int8_t ec;
      /// The PMT number in EC
      int8_t pmtInEC;
      /// The Anode index (0-63)
      int8_t anode;

    public:
      /// Default constructor
      BitData() = default;
      /// Constructor from values
      __host__ __device__ BitData(
        const int8_t _ec,  //
        const int8_t _pmt, //
        const int8_t _anode) :
        ec(_ec),
        pmtInEC(_pmt), anode(_anode)
      {}
    };

  private:
    // defines

    /// Max Number of frames per PDMDB
    static constexpr const unsigned FramesPerPDMDB = 6;

    /// Number of PDMDBs per module
    static constexpr const unsigned PDMDBPerModule = 2;

    ///  Max Number of frames per PDM
    static constexpr const unsigned FramesPerPDM = PDMDBPerModule * FramesPerPDMDB;

    /// Number of bits per data frame
    static constexpr const unsigned BitsPerFrame = 86;

    /// Array of Bit Data structs per frame
    using FrameData = std::array<BitData, BitsPerFrame>;

    /// Data for each PDMDB
    using PDMDBData = std::array<FrameData, FramesPerPDMDB>;

    /// Data for each PDM
    using PDMData = std::array<PDMDBData, PDMDBPerModule>;

    ///  R-Type Module data for each RICH
    using RTypeRichData = std::array<PDMData, 2>;

  private:
    // methods

    /// Get the PDMDB data for given RICH, PDMDB and frame
    __host__ __device__ inline const auto& getFrameData(
      const int8_t rich,  //
      const int8_t pdmdb, //
      const int8_t link,  //
      const bool isHType) const
    {
      // Note as this is called many times from the decoding, avoid runtime range checking
      // in optimised builds, as once OK it should never be invalidated.
      // This is though tested in the debug builds via the asserts.
      if (!isHType) {
        // R type PMT
        return m_pdmDataR[rich][pdmdb][link];
      }
      else {
        return m_pdmDataH[pdmdb][link];
      }
    }

  public:
    /// mapping version
    __host__ __device__ inline auto version() const { return m_mappingVer; }

    /// Access the initialisation state
    __host__ __device__ inline auto isInitialised() const { return m_isInitialised; }

    /// Get PDMDB data for given Tel40 data
    __host__ __device__ inline const auto& getFrameData(const Tel40CableMapping::Tel40LinkData& cData) const
    {
      const auto rich = cData.smartID.getData(::Allen::RichSmartID::ShiftRich, ::Allen::RichSmartID::MaskRich);
      return getFrameData(rich, cData.pdmdbNum, cData.linkNum, cData.isHType);
    }

  private:
    // data

    /// R type data
    RTypeRichData m_pdmDataR; // std::array<PDMData, 2>

    /// H type data
    PDMData m_pdmDataH; // std::array<PDMDBData, 2>

    /// Flag to indicate initialisation status
    bool m_isInitialised {false};

    /// Mapping version
    int m_mappingVer {-1};
  };

} // namespace Rich::Future::DAQ::Allen
