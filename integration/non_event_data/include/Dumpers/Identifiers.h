/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>

namespace Allen {
  namespace NonEventData {
    struct Identifier {
    };

    struct VeloGeometry : Identifier {
      inline static std::string const id = "VeloGeometry";
    };

    struct UTGeometry : Identifier {
      inline static std::string const id = "UTGeometry";
    };

    struct UTBoards : Identifier {
      inline static std::string const id = "UTBoards";
    };

    struct SciFiGeometry : Identifier {
      inline static std::string const id = "SciFiGeometry";
    };

    struct UTLookupTables : Identifier {
      inline static std::string const id = "UTLookupTables";
    };

    struct Beamline : Identifier {
      inline static std::string const id = "Beamline";
    };

    struct MagneticField : Identifier {
      inline static std::string const id = "MagneticField";
    };

    struct MuonGeometry : Identifier {
      inline static std::string const id = "MuonGeometry";
    };

    struct MuonLookupTables : Identifier {
      inline static std::string const id = "MuonLookupTables";
    };

    /** @class HCalGeometry
     *  Identifier for the HCal geometry in Allen
     */
    struct HCalGeometry : Identifier {
      inline static std::string const id = "HcalGeometry";
    };

    /** @class ECalGeometry
     *  Identifier for the ECal geometry in Allen
     */
    struct ECalGeometry : Identifier {
      inline static std::string const id = "EcalGeometry";
    };
  } // namespace NonEventData
} // namespace Allen
