
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

    enum Word8Bits {
      BunchIDBits = 0, TAEWindowBits = 12, TriggerTypeBits = 16, CalibrationTypeBits = 19,
      ForceBits = 21, BXTypeBits = 22, BunchCurrentBits = 24
    };
     
    enum Word8Masks {
      BunchIDMask = 0x00000FFF, TAEWindowMask = 0x00007000, TriggerTypeMask = 0x00070000, CalibrationTypeMask = 0x00180000,
      ForceMask = 0x00200000, BXTypeMask = 0x00C00000, BunchCurrentMask = 0xFF000000
    };

    enum BXTypes { NoBeam = 0, Beam1 = 1, Beam2 = 2, BeamCrossing = 3 };

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
