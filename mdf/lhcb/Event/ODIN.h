/*****************************************************************************\
* (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <gsl/span>
namespace LHCb {
  using gsl::span;
}
#include <array>
#include <cassert>
#include <cstdint>
#include <cstring>

namespace LHCb {

  namespace ODINImplementation::details {
    /// Helper to extract COUNT bits starting from OFFSET in a buffer.
    template<unsigned int COUNT, unsigned int OFFSET>
    auto get_bits(LHCb::span<const std::uint32_t> data)
    {
      static_assert(COUNT != 0 && COUNT <= 64, "invalid COUNT parameter");
      if constexpr (COUNT == 1) {
        return (data[OFFSET / 32] & (1 << OFFSET % 32)) ? true : false;
        // } else if constexpr ( COUNT <= 8 ) { // this version returns strings in Python
        //   static_assert( ( OFFSET % 32 + COUNT ) <= 32 );
        //   const auto mask = static_cast<std::uint32_t>( -1 ) >> ( 32 - COUNT );
        //   return static_cast<std::uint8_t>( ( data[OFFSET / 32] >> OFFSET % 32 ) & mask );
      }
      else if constexpr (COUNT <= 16) {
        static_assert((OFFSET % 32 + COUNT) <= 32, "invalid COUNT or OFFSET parameter");
        const auto mask = static_cast<std::uint32_t>(-1) >> (32 - COUNT);
        return static_cast<std::uint16_t>((data[OFFSET / 32] >> OFFSET % 32) & mask);
      }
      else if constexpr (COUNT < 32) {
        static_assert((OFFSET % 32 + COUNT) <= 32, "invalid COUNT or OFFSET parameter");
        const auto mask = static_cast<std::uint32_t>(-1) >> (32 - COUNT);
        return static_cast<std::uint32_t>((data[OFFSET / 32] >> OFFSET % 32) & mask);
      }
      else if constexpr (COUNT == 32) {
        static_assert(OFFSET % 32 == 0, "invalid COUNT or OFFSET parameter");
        return data[OFFSET / 32];
      }
      else if constexpr (COUNT == 64) {
        static_assert(OFFSET % 32 == 0, "invalid COUNT or OFFSET parameter");
        return static_cast<std::uint64_t>(data[OFFSET / 32]) |
               (static_cast<std::uint64_t>(data[OFFSET / 32 + 1]) << 32);
      }
    }
    /// Helper to set COUNT bits starting from OFFSET in a buffer using the passed value.
    template<unsigned int COUNT, unsigned int OFFSET, typename VALUE>
    void set_bits(LHCb::span<std::uint32_t> data, VALUE value)
    {
      static_assert(COUNT != 0 && COUNT <= 64, "invalid COUNT parameter");
      if constexpr (COUNT == 1) {
        if (value) {
          data[OFFSET / 32] |= (1 << OFFSET % 32);
        }
        else {
          data[OFFSET / 32] &= ~(1 << OFFSET % 32);
        }
      }
      else if constexpr (COUNT < 32) {
        static_assert((OFFSET % 32 + COUNT) <= 32, "invalid COUNT or OFFSET parameter");
        const auto mask = static_cast<std::uint32_t>(-1) >> (32 - COUNT);
        data[OFFSET / 32] = (data[OFFSET / 32] & ~(mask << OFFSET % 32)) | ((value & mask) << OFFSET % 32);
      }
      else if constexpr (COUNT == 32) {
        static_assert(OFFSET % 32 == 0, "invalid COUNT or OFFSET parameter");
        data[OFFSET / 32] = value;
      }
      else if constexpr (COUNT == 64) {
        static_assert(OFFSET % 32 == 0, "invalid COUNT or OFFSET parameter");
        data[OFFSET / 32] = static_cast<std::uint32_t>(value & 0xFFFFFFFF);
        data[OFFSET / 32 + 1] = static_cast<std::uint32_t>((value >> 32) & 0xFFFFFFFF);
      }
    }
  } // namespace ODINImplementation::details

  namespace ODINImplementation::v7 {

    struct ODIN final {

      /// Meaning of the EventType bits
      enum class EventTypes : std::uint16_t {
        VeloOpen = 0x0001,
        Physics = 0x0002,
        NoBias = 0x0004,
        Lumi = 0x0008,
        Beam1Gas = 0x0010,
        Beam2Gas = 0x0020,
        et_bit_06 = 0x0040,
        et_bit_07 = 0x0080,
        et_bit_08 = 0x0100,
        et_bit_09 = 0x0200,
        TriggerMaskPhysics = 0x0400,
        TriggerMaskNoBias = 0x0800,
        TriggerMaskBeam1Gas = 0x1000,
        TriggerMaskBeam2Gas = 0x2000,
        SequencerTrigger = 0x4000,
        HltFlaggingMode = 0x8000
      };

      /// Calibration types
      enum class CalibrationTypes : std::uint8_t { //
        A = 0,
        B = 1,
        C = 2,
        D = 3
      };

      /// BX Types
      enum class BXTypes : std::uint8_t { //
        NoBeam = 0,
        Beam1 = 1,
        Beam2 = 2,
        BeamCrossing = 3
      };

      /// Types of trigger broadcasted by ODIN
      enum class TriggerTypes : std::uint8_t { //
        PhysicsTrigger = 0,
        BeamGasTrigger = 1,
        LumiTrigger = 2,
        TechnicalTrigger = 3,
        AuxiliaryTrigger = 4,
        NonZSupTrigger = 5,
        TimingTrigger = 6,
        CalibrationTrigger = 7
      };

      static constexpr int BANK_VERSION = 7;
      static constexpr int BANK_SIZE = 40;

      std::array<std::uint32_t, BANK_SIZE / sizeof(std::uint32_t)> data {0};

      ODIN() = default;
      ODIN(LHCb::span<const std::uint32_t> buffer)
      {
        assert(buffer.size() == data.size());
        std::memcpy(data.data(), buffer.data(), sizeof(data));
      }

      enum Fields {
        RunNumberSize = 32,
        RunNumberOffset = 0,
        EventTypeSize = 16,
        EventTypeOffset = 1 * 32 + 0,
        CalibrationStepSize = 16,
        CalibrationStepOffset = 1 * 32 + 16,
        GpsTimeSize = 64,
        GpsTimeOffset = 2 * 32,
        TriggerConfigurationKeySize = 32,
        TriggerConfigurationKeyOffset = 4 * 32,
        PartitionIDSize = 32,
        PartitionIDOffset = 5 * 32,
        BunchIdSize = 12,
        BunchIdOffset = 6 * 32 + 0,
        BunchCrossingTypeSize = 2,
        BunchCrossingTypeOffset = 6 * 32 + 12,
        NonZeroSuppressionModeSize = 1,
        NonZeroSuppressionModeOffset = 6 * 32 + 14,
        TimeAlignmentEventCentralSize = 1,
        TimeAlignmentEventCentralOffset = 6 * 32 + 15,
        TimeAlignmentEventWindowSize = 6,
        TimeAlignmentEventWindowOffset = 6 * 32 + 16,
        StepRunEnableSize = 1,
        StepRunEnableOffset = 6 * 32 + 22,
        TriggerTypeSize = 4,
        TriggerTypeOffset = 6 * 32 + 23,
        TimeAlignmentEventFirstSize = 1,
        TimeAlignmentEventFirstOffset = 6 * 32 + 27,
        CalibrationTypeSize = 4,
        CalibrationTypeOffset = 6 * 32 + 28,
        OrbitNumberSize = 32,
        OrbitNumberOffset = 7 * 32,
        EventNumberSize = 64,
        EventNumberOffset = 8 * 32
      };

      auto runNumber() const { return details::get_bits<RunNumberSize, RunNumberOffset>(data); }
      void setRunNumber(std::uint32_t value) { details::set_bits<RunNumberSize, RunNumberOffset>(data, value); }

      auto eventType() const { return details::get_bits<EventTypeSize, EventTypeOffset>(data); }
      void setEventType(std::uint16_t value) { details::set_bits<EventTypeSize, EventTypeOffset>(data, value); }
      void setEventType(EventTypes value) { setEventType(static_cast<std::uint16_t>(value)); }

      auto calibrationStep() const { return details::get_bits<CalibrationStepSize, CalibrationStepOffset>(data); }
      void setCalibrationStep(std::uint16_t value)
      {
        details::set_bits<CalibrationStepSize, CalibrationStepOffset>(data, value);
      }

      auto gpsTime() const { return details::get_bits<GpsTimeSize, GpsTimeOffset>(data); }
      void setGpsTime(std::uint64_t value) { details::set_bits<GpsTimeSize, GpsTimeOffset>(data, value); }

      auto triggerConfigurationKey() const
      {
        return details::get_bits<TriggerConfigurationKeySize, TriggerConfigurationKeyOffset>(data);
      }
      void setTriggerConfigurationKey(std::uint32_t value)
      {
        details::set_bits<TriggerConfigurationKeySize, TriggerConfigurationKeyOffset>(data, value);
      }

      auto partitionID() const { return details::get_bits<PartitionIDSize, PartitionIDOffset>(data); }
      void setPartitionID(std::uint32_t value) { details::set_bits<PartitionIDSize, PartitionIDOffset>(data, value); }

      auto bunchId() const { return details::get_bits<BunchIdSize, BunchIdOffset>(data); }
      void setBunchId(std::uint16_t value) { details::set_bits<BunchIdSize, BunchIdOffset>(data, value); }
      BXTypes bunchCrossingType() const
      {
        return static_cast<BXTypes>(details::get_bits<BunchCrossingTypeSize, BunchCrossingTypeOffset>(data));
      }
      void setBunchCrossingType(BXTypes value)
      {
        details::set_bits<BunchCrossingTypeSize, BunchCrossingTypeOffset>(data, static_cast<std::uint8_t>(value));
      }
      auto nonZeroSuppressionMode() const
      {
        return details::get_bits<NonZeroSuppressionModeSize, NonZeroSuppressionModeOffset>(data);
      }
      void setNonZeroSuppressionMode(bool value)
      {
        details::set_bits<NonZeroSuppressionModeSize, NonZeroSuppressionModeOffset>(data, value);
      }
      auto timeAlignmentEventCentral() const
      {
        return details::get_bits<TimeAlignmentEventCentralSize, TimeAlignmentEventCentralOffset>(data);
      }
      void setTimeAlignmentEventCentral(bool value)
      {
        details::set_bits<TimeAlignmentEventCentralSize, TimeAlignmentEventCentralOffset>(data, value);
      }
      auto timeAlignmentEventWindow() const
      {
        return details::get_bits<TimeAlignmentEventWindowSize, TimeAlignmentEventWindowOffset>(data);
      }
      void setTimeAlignmentEventWindow(std::uint8_t value)
      {
        details::set_bits<TimeAlignmentEventWindowSize, TimeAlignmentEventWindowOffset>(data, value);
      }
      auto stepRunEnable() const { return details::get_bits<StepRunEnableSize, StepRunEnableOffset>(data); }
      void setStepRunEnable(bool value) { details::set_bits<StepRunEnableSize, StepRunEnableOffset>(data, value); }
      auto triggerType() const { return details::get_bits<TriggerTypeSize, TriggerTypeOffset>(data); }
      void setTriggerType(std::uint8_t value) { details::set_bits<TriggerTypeSize, TriggerTypeOffset>(data, value); }
      void setTriggerType(TriggerTypes value) { setTriggerType(static_cast<std::uint8_t>(value)); }
      auto timeAlignmentEventFirst() const
      {
        return details::get_bits<TimeAlignmentEventFirstSize, TimeAlignmentEventFirstOffset>(data);
      }
      void setTimeAlignmentEventFirst(bool value)
      {
        details::set_bits<TimeAlignmentEventFirstSize, TimeAlignmentEventFirstOffset>(data, value);
      }
      auto calibrationType() const { return details::get_bits<CalibrationTypeSize, CalibrationTypeOffset>(data); }
      void setCalibrationType(std::uint8_t value)
      {
        details::set_bits<CalibrationTypeSize, CalibrationTypeOffset>(data, value);
      }
      void setCalibrationType(CalibrationTypes value) { setCalibrationType(static_cast<std::uint8_t>(value)); }

      auto orbitNumber() const { return details::get_bits<OrbitNumberSize, OrbitNumberOffset>(data); }
      void setOrbitNumber(std::uint32_t value) { details::set_bits<OrbitNumberSize, OrbitNumberOffset>(data, value); }

      auto eventNumber() const { return details::get_bits<EventNumberSize, EventNumberOffset>(data); }
      void setEventNumber(std::uint64_t value) { details::set_bits<EventNumberSize, EventNumberOffset>(data, value); }

      // Helpers
      bool isFlagging() const { return eventType() & static_cast<std::uint16_t>(EventTypes::HltFlaggingMode); }
    };

  } // namespace ODINImplementation::v7

  using ODIN = ODINImplementation::v7::ODIN;

} // namespace LHCb
