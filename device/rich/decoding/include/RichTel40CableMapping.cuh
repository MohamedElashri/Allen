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

#include <array>
#include <RichDefinitions.cuh>

namespace Rich::Future::DAQ::Allen {
  /// Helper class for RICH PMT data format encoding
  class Tel40CableMapping final {

  public:
    /// Struct for storing data for each Tel40 Link
    class Tel40LinkData final {
    public:
      /// RICH SmartID
      ::Allen::RichSmartID smartID;
      /// Module Number
      int32_t moduleNum;
      /// Source ID
      int16_t sourceID;
      /// Tel40 connector
      int8_t connector;
      /// PDMDB number (0,1)
      int8_t pdmdbNum;
      /// Link number
      int8_t linkNum;
      /// PMT type
      bool isHType {false};
      /// Is Link Active
      bool isActive {false};

    public:
      /// Default constructor
      Tel40LinkData() = default;
    };

    class Tel40MetaData final {
    public:
      uint32_t nActiveLinks;
      bool hasInactiveLinks;
    };

    /// Max number of links(frames) per PDMDB
    static constexpr const uint64_t MaxLinksPerPDMDB = 6;

    /// Number of PDMDBs per module
    static constexpr const uint64_t PDMDBPerModule = 2;

    /// Number of Tel40 connections per MPO
    static constexpr const uint64_t ConnectionsPerTel40MPO = 12;

    /// Maximum number of active Tel40 MPOs per Source ID
    static constexpr const uint64_t MaxNumberMPOsPerSourceID = 2;

    /// Maximum Number of connections per Tel40
    static constexpr const uint64_t MaxConnectionsPerTel40 = MaxNumberMPOsPerSourceID * ConnectionsPerTel40MPO;

    /// Array of Tel40 for each link in a PDMDB
    using PDMDBLinkData = std::array<Tel40LinkData, MaxLinksPerPDMDB>;

    /// Array of LinkData for each PDMDB in a module
    using PDMDBData = std::array<PDMDBLinkData, PDMDBPerModule>;

    /// Tel40 data for each Module
    using ModuleTel40Data = std::array<PDMDBData, 300>; // 300 is totalmodules

    using Tel40SourceIDs = std::array<std::array<std::array<std::array<Tel40LinkData, 24>, 164>, 2>, 2>;
    using Tel40SourceMetas = std::array<std::array<std::array<Tel40MetaData, 164>, 2>, 2>;

  public:
    // accessors

    /// Access the initialisation state
    inline bool isInitialised() const { return m_isInitialised; }

    /// Access the Tel40 Link data for given channel ID
    const auto& tel40Data(
      const uint32_t id,  // PD ID
      const int8_t pdmdb, // PDMDB ID
      const int8_t frame  // PDMDB Frame
      ) const
    {
      // module number
      const auto modN = (id >> 6) & 0xF; // TODO: RichSmartID.h:912

      // return tel40 data
      const auto& data = m_tel40ModuleData[modN][pdmdb][frame];
      // finally return
      return data;
    }

    /// Access the Tel40 connection data for a given SourceID
    __device__ const auto& tel40Data(const int16_t sID) const
    {
      const auto payload = sID & 0x3FF;
      const auto side = (sID >> 10) & 0x1;
      const auto rich = (sID >> 11) == 9; // Rich1 is 4, Rich2 is 9. Then, Rich1 is identified with 0, Rich2 is 1.
      return m_tel40ConnData[rich][side][payload];
    }

    // TODO: Use this when the int / boolean info is needed
    __device__ const auto& tel40Meta(const int16_t sID) const
    {
      const auto payload = sID & 0x3FF;
      const auto side = (sID >> 10) & 0x1;
      const auto rich = (sID >> 11) == 9; // Rich1 is 4, Rich2 is 9. Then, Rich1 is identified with 0, Rich2 is 1.
      return m_tel40ConnMeta[rich][side][payload];
    }

    /// mapping version
    inline auto version() const { return m_mappingVer; }

  private:
    // data

    /// Tel40 connection mapping data
    Tel40SourceIDs m_tel40ConnData;
    Tel40SourceMetas m_tel40ConnMeta;

    /// Tel40 Module Mapping data
    ModuleTel40Data m_tel40ModuleData;

    /// Flag to indicate initialisation status
    bool m_isInitialised {false};

    /// Mapping version
    int m_mappingVer {-1};
  };

} // namespace Rich::Future::DAQ::Allen