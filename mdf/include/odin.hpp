
#ifndef ODIN_H
#define ODIN_H 1

namespace LHCb {
  struct ODIN final {
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

    enum EventTypeBitsEnum { EventTypeBits = 0, CalibrationStepBits = 16 };

    enum EventTypeMasks { EventTypeMask = 0x0000FFFF, CalibrationStepMask = 0xFFFF0000, FlaggingModeMask = 0x00008000 };

    enum EventTypes {
      VeloOpen = 0x0001, Physics = 0x0002, NoBias = 0x0004, Lumi = 0x0008,
      Beam1Gas = 0x0010, Beam2Gas = 0x0020, et_bit_06 = 0x0040, et_bit_07 = 0x0080,
      et_bit_08 = 0x0100, et_bit_09 = 0x0200, TriggerMaskPhysics = 0x0400, TriggerMaskNoBias = 0x0800,
      TriggerMaskBeam1Gas = 0x1000, TriggerMaskBeam2Gas = 0x2000, SequencerTrigger = 0x4000, HltFlaggingMode = 0x8000,
    };

    enum Word8Bits {
      BunchIDBits = 0, TAEWindowBits = 12, TriggerTypeBits = 16, CalibrationTypeBits = 19,
      ForceBits = 21, BXTypeBits = 22, BunchCurrentBits = 24
    };
     
    enum Word8Masks {
      BunchIDMask = 0x00000FFF, TAEWindowMask = 0x00007000, TriggerTypeMask = 0x00070000, CalibrationTypeMask = 0x00180000,
      ForceMask = 0x00200000, BXTypeMask = 0x00C00000, BunchCurrentMask = 0xFF000000
    };

    enum BXTypes { NoBeam = 0, Beam1 = 1, Beam2 = 2, BeamCrossing = 3 };

    static unsigned int decodeEventType(unsigned int word2) { return (word2 & EventTypeMask) >> EventTypeBits; }
    static unsigned int decodeBXType(unsigned int word8) { return (word8 & BXTypeMask) >> BXTypeBits; }
    static unsigned int decodeBunchCurrent(unsigned int word8) { return (word8 & BunchCurrentMask) >> BunchCurrentBits; }

    unsigned int run_number;
    unsigned int event_type;
    unsigned int orbit_number;
    unsigned long long event_number;
    unsigned long long gps_time;
    unsigned int version;
    unsigned int calibration_step;
    unsigned int tck;
  };
} // namespace LHCb

#endif
