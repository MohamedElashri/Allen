/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Include files
#include "Event/RawBank.h"

namespace LHCb {

  /** @class ODIN ODIN.h
   *
   * Class for the decoding of the ODIN RawBank.
   *
   * @author Marco Clemencic
   *
   */
  class ODIN final {
  public:
    /// Fields in the ODIN bank
    enum Data {
      RunNumber = 0,
      EventType,
      OrbitNumber,
      L0EventIDHi,
      L0EventIDLo,
      GPSTimeHi,
      GPSTimeLo,
      Word7,
      Word8,
      TriggerConfigurationKey
    };
    ///
    enum EventTypeBitsEnum { EventTypeBits = 0, CalibrationStepBits = 16 };
    ///
    enum EventTypeMasks { EventTypeMask = 0x0000FFFF, CalibrationStepMask = 0xFFFF0000, FlaggingModeMask = 0x00008000 };
    /// Meaning of the EventType bits
    enum EventTypes {
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
    ///
    enum Word7Bits { DetectorStatusBits = 0, ErrorBits = 24 };
    ///
    enum ErrorCodeMasks { SynchError = 0x1, SynchErrorForced = 0x2 };
    ///
    enum Word7Masks { DetectorStatusMask = 0x00FFFFFF, ErrorMask = 0xFF000000 };
    ///
    enum Word8Bits {
      BunchIDBits = 0,
      TAEWindowBits = 12,
      TriggerTypeBits = 16,
      CalibrationTypeBits = 19,
      ForceBits = 21,
      BXTypeBits = 22,
      BunchCurrentBits = 24
    };
    ///
    enum Word8Masks {
      BunchIDMask = 0x00000FFF,
      TAEWindowMask = 0x00007000,
      TriggerTypeMask = 0x00070000,
      CalibrationTypeMask = 0x00180000,
      ForceMask = 0x00200000,
      BXTypeMask = 0x00C00000,
      BunchCurrentMask = 0xFF000000
    };
    /// Provided for backward compatibility
    enum Word8Bits_v4 { ReadoutTypeBits = 19 };
    /// Provided for backward compatibility
    enum Word8Masks_v4 { ReadoutTypeMask = 0x00180000 };
    ///
    enum ReadoutTypes { ZeroSuppressed = 0, NonZeroSuppressed = 1 };
    ///
    enum CalibrationTypes { A = 0, B = 1, C = 2, D = 3 };
    ///
    enum BXTypes { NoBeam = 0, Beam1 = 1, Beam2 = 2, BeamCrossing = 3 };
    /// Type of trigger broadcasted by ODIN
    enum TriggerType {
      PhysicsTrigger,
      BeamGasTrigger,
      LumiTrigger,
      TechnicalTrigger,
      AuxiliaryTrigger,
      NonZSupTrigger,
      TimingTrigger,
      CalibrationTrigger
    };

    /// Default Constructor
    ODIN() :
      m_runNumber(0), m_eventType(0), m_orbitNumber(0), m_eventNumber(0), m_gpsTime(0), m_detectorStatus(0),
      m_errorBits(0), m_bunchId(0), m_triggerType(TriggerType::PhysicsTrigger),
      m_readoutType(ReadoutTypes::ZeroSuppressed), m_forceBit(false), m_bunchCrossingType(BXTypes::NoBeam),
      m_bunchCurrent(0), m_version(0), m_calibrationStep(0), m_triggerConfigurationKey(0),
      m_timeAlignmentEventWindow(0), m_calibrationType(CalibrationTypes::A)
    {}

    ///
    bool isFlagging() const;

    /// Retrieve const  Run number
    unsigned int runNumber() const;

    /// Update  Run number
    void setRunNumber(unsigned int value);

    /// Retrieve const  Event type
    unsigned int eventType() const;

    /// Update  Event type
    void setEventType(unsigned int value);

    /// Retrieve const  Orbit ID
    unsigned int orbitNumber() const;

    /// Update  Orbit ID
    void setOrbitNumber(unsigned int value);

    /// Retrieve const  L0 Event ID
    unsigned long long eventNumber() const;

    /// Update  L0 Event ID
    void setEventNumber(unsigned long long value);

    /// Retrieve const  GPS Time (microseconds)
    unsigned long long gpsTime() const;

    /// Update  GPS Time (microseconds)
    void setGpsTime(unsigned long long value);

    /// Retrieve const  Detector Status
    unsigned long long detectorStatus() const;

    /// Update  Detector Status
    void setDetectorStatus(unsigned long long value);

    /// Retrieve const  Error Bits
    unsigned int errorBits() const;

    /// Update  Error Bits
    void setErrorBits(unsigned int value);

    /// Retrieve const  Bunch ID
    unsigned int bunchId() const;

    /// Update  Bunch ID
    void setBunchId(unsigned int value);

    /// Retrieve const  Trigger Type @see enum LHCb::ODIN::TriggerType
    const TriggerType& triggerType() const;

    /// Update  Trigger Type @see enum LHCb::ODIN::TriggerType
    void setTriggerType(const TriggerType& value);

    /// Retrieve const  Readout Type (@see enum LHCb::ODIN::ReadoutTypes). Meaningful only if bank version < 5.
    const ReadoutTypes& readoutType() const;

    /// Update  Readout Type (@see enum LHCb::ODIN::ReadoutTypes). Meaningful only if bank version < 5.
    void setReadoutType(const ReadoutTypes& value);

    /// Retrieve const  Force Bit
    bool forceBit() const;

    /// Update  Force Bit
    void setForceBit(bool value);

    /// Retrieve const  Bunch Crossing Type (BXType, @see enum LHCb::ODIN::BXTypes)
    const BXTypes& bunchCrossingType() const;

    /// Update  Bunch Crossing Type (BXType, @see enum LHCb::ODIN::BXTypes)
    void setBunchCrossingType(const BXTypes& value);

    /// Retrieve const  Bunch Current
    unsigned int bunchCurrent() const;

    /// Update  Bunch Current
    void setBunchCurrent(unsigned int value);

    /// Retrieve const  Version of the ODIN bank
    unsigned int version() const;

    /// Update  Version of the ODIN bank
    void setVersion(unsigned int value);

    /// Retrieve const  Calibration Step Number
    unsigned int calibrationStep() const;

    /// Update  Calibration Step Number
    void setCalibrationStep(unsigned int value);

    /// Retrieve const  Requested Trigger Configuration Key. The key actually used is in
    /// LHCb::HltDecReports::configuredTCK
    unsigned int triggerConfigurationKey() const;

    /// Update  Requested Trigger Configuration Key. The key actually used is in LHCb::HltDecReports::configuredTCK
    void setTriggerConfigurationKey(unsigned int value);

    /// Retrieve const  TAE (Time Alignment Event) window size
    unsigned int timeAlignmentEventWindow() const;

    /// Update  TAE (Time Alignment Event) window size
    void setTimeAlignmentEventWindow(unsigned int value);

    /// Retrieve const  Calibration Type (@see enum LHCb::ODIN::CalibrationTypes). Meaningful only if bank version >= 5.
    const CalibrationTypes& calibrationType() const;

    /// Update  Calibration Type (@see enum LHCb::ODIN::CalibrationTypes). Meaningful only if bank version >= 5.
    void setCalibrationType(const CalibrationTypes& value);

  protected:
  private:
    unsigned int m_runNumber;            ///< Run number
    unsigned int m_eventType;            ///< Event type
    unsigned int m_orbitNumber;          ///< Orbit ID
    unsigned long long m_eventNumber;    ///< L0 Event ID
    unsigned long long m_gpsTime;        ///< GPS Time (microseconds)
    unsigned long long m_detectorStatus; ///< Detector Status
    unsigned int m_errorBits;            ///< Error Bits
    unsigned int m_bunchId;              ///< Bunch ID
    TriggerType m_triggerType;           ///< Trigger Type @see enum LHCb::ODIN::TriggerType
    ReadoutTypes m_readoutType;  ///< Readout Type (@see enum LHCb::ODIN::ReadoutTypes). Meaningful only if bank version
                                 ///< < 5.
    bool m_forceBit;             ///< Force Bit
    BXTypes m_bunchCrossingType; ///< Bunch Crossing Type (BXType, @see enum LHCb::ODIN::BXTypes)
    unsigned int m_bunchCurrent; ///< Bunch Current
    unsigned int m_version;      ///< Version of the ODIN bank
    unsigned int m_calibrationStep;          ///< Calibration Step Number
    unsigned int m_triggerConfigurationKey;  ///< Requested Trigger Configuration Key. The key actually used is in
                                             ///< LHCb::HltDecReports::configuredTCK
    unsigned int m_timeAlignmentEventWindow; ///< TAE (Time Alignment Event) window size
    CalibrationTypes m_calibrationType; ///< Calibration Type (@see enum LHCb::ODIN::CalibrationTypes). Meaningful only
                                        ///< if bank version >= 5.

  }; // class ODIN

} // namespace LHCb

// -----------------------------------------------------------------------------
// end of class
// -----------------------------------------------------------------------------

inline unsigned int LHCb::ODIN::runNumber() const { return m_runNumber; }

inline void LHCb::ODIN::setRunNumber(unsigned int value) { m_runNumber = value; }

inline unsigned int LHCb::ODIN::eventType() const { return m_eventType; }

inline void LHCb::ODIN::setEventType(unsigned int value) { m_eventType = value; }

inline unsigned int LHCb::ODIN::orbitNumber() const { return m_orbitNumber; }

inline void LHCb::ODIN::setOrbitNumber(unsigned int value) { m_orbitNumber = value; }

inline unsigned long long LHCb::ODIN::eventNumber() const { return m_eventNumber; }

inline void LHCb::ODIN::setEventNumber(unsigned long long value) { m_eventNumber = value; }

inline unsigned long long LHCb::ODIN::gpsTime() const { return m_gpsTime; }

inline void LHCb::ODIN::setGpsTime(unsigned long long value) { m_gpsTime = value; }

inline unsigned long long LHCb::ODIN::detectorStatus() const { return m_detectorStatus; }

inline void LHCb::ODIN::setDetectorStatus(unsigned long long value) { m_detectorStatus = value; }

inline unsigned int LHCb::ODIN::errorBits() const { return m_errorBits; }

inline void LHCb::ODIN::setErrorBits(unsigned int value) { m_errorBits = value; }

inline unsigned int LHCb::ODIN::bunchId() const { return m_bunchId; }

inline void LHCb::ODIN::setBunchId(unsigned int value) { m_bunchId = value; }

inline const LHCb::ODIN::TriggerType& LHCb::ODIN::triggerType() const { return m_triggerType; }

inline void LHCb::ODIN::setTriggerType(const TriggerType& value) { m_triggerType = value; }

inline const LHCb::ODIN::ReadoutTypes& LHCb::ODIN::readoutType() const { return m_readoutType; }

inline void LHCb::ODIN::setReadoutType(const ReadoutTypes& value) { m_readoutType = value; }

inline bool LHCb::ODIN::forceBit() const { return m_forceBit; }

inline void LHCb::ODIN::setForceBit(bool value) { m_forceBit = value; }

inline const LHCb::ODIN::BXTypes& LHCb::ODIN::bunchCrossingType() const { return m_bunchCrossingType; }

inline void LHCb::ODIN::setBunchCrossingType(const BXTypes& value) { m_bunchCrossingType = value; }

inline unsigned int LHCb::ODIN::bunchCurrent() const { return m_bunchCurrent; }

inline void LHCb::ODIN::setBunchCurrent(unsigned int value) { m_bunchCurrent = value; }

inline unsigned int LHCb::ODIN::version() const { return m_version; }

inline void LHCb::ODIN::setVersion(unsigned int value) { m_version = value; }

inline unsigned int LHCb::ODIN::calibrationStep() const { return m_calibrationStep; }

inline void LHCb::ODIN::setCalibrationStep(unsigned int value) { m_calibrationStep = value; }

inline unsigned int LHCb::ODIN::triggerConfigurationKey() const { return m_triggerConfigurationKey; }

inline void LHCb::ODIN::setTriggerConfigurationKey(unsigned int value) { m_triggerConfigurationKey = value; }

inline unsigned int LHCb::ODIN::timeAlignmentEventWindow() const { return m_timeAlignmentEventWindow; }

inline void LHCb::ODIN::setTimeAlignmentEventWindow(unsigned int value) { m_timeAlignmentEventWindow = value; }

inline const LHCb::ODIN::CalibrationTypes& LHCb::ODIN::calibrationType() const { return m_calibrationType; }

inline void LHCb::ODIN::setCalibrationType(const CalibrationTypes& value) { m_calibrationType = value; }

inline bool LHCb::ODIN::isFlagging() const { return eventType() & EventTypeMasks::FlaggingModeMask; }
