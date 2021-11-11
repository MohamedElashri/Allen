#ifndef __SOURCEID_H
#define __SOURCEID_H

#include <stdint.h>
#include <string.h>

// From https://indico.cern.ch/event/855945/contributions/3602071/attachments/1930420/3197111/191022_LHCbCommissioning.pdf

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  SourceIdSys_ODIN    = 0,
  //1 ?
  SourceIdSys_VELO_A  = 2,
  SourceIdSys_VELO_C  = 3,
  SourceIdSys_RICH_1  = 4,
  SourceIdSys_UT_A    = 5,
  SourceIdSys_UT_C    = 6,
  SourceIdSys_SCIFI_A = 7,
  SourceIdSys_SCIFI_C = 8,
  SourceIdSys_RICH_2  = 9,
  SourceIdSys_PLUME   = 10,
  SourceIdSys_ECAL    = 11,
  SourceIdSys_HCAL    = 12,
  SourceIdSys_MUON_A  = 13,
  SourceIdSys_MUON_C  = 14,
  SourceIdSys_TDET    = 15,
} SourceIdSys;

struct __attribute__((__packed__)) SourceId {
  uint16_t bits;
};

inline int SourceId_sys(uint16_t bits) {
  return bits >> 11;
}

inline const char *SourceId_sysstr(uint16_t bits) {
  switch (SourceId_sys(bits)) {
    case SourceIdSys_ODIN: return "ODIN";
    case SourceIdSys_VELO_A: return "VELO_A";
    case SourceIdSys_VELO_C: return "VELO_C";
    case SourceIdSys_RICH_1: return "RICH_1";
    case SourceIdSys_UT_A: return "UT_A";
    case SourceIdSys_UT_C: return "UT_C";
    case SourceIdSys_SCIFI_A: return "SCIFI_A";
    case SourceIdSys_SCIFI_C: return "SCIFI_C";
    case SourceIdSys_RICH_2: return "RICH_2";
    case SourceIdSys_PLUME: return "PLUME";
    case SourceIdSys_ECAL: return "ECAL";
    case SourceIdSys_HCAL: return "HCAL";
    case SourceIdSys_MUON_A: return "MUON_A";
    case SourceIdSys_MUON_C: return "MUON_C";
    case SourceIdSys_TDET: return "TDET";
    default: return NULL;
  }
}

inline int SourceId_num(uint16_t bits) {
  return bits & 0x7FF;
}

#ifdef __cplusplus
} //extern "C"
#endif

#endif//__SOURCEID_H
