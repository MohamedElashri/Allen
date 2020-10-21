/*****************************************************************************\
* (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <string>

namespace Allen {
  namespace NonEventData {
    struct Identifier {
    };

    /** @class VeloGeometry
     *  Identifier for the Velo Geometry non-event data for Allen
     */
    struct VeloGeometry : Identifier {
      inline static std::string const id = "VeloGeometry";
    };

    /** @class UTGeometry
     *  Identifier for the UT Geometry non-event data for Allen
     */
    struct UTGeometry : Identifier {
      inline static std::string const id = "UTGeometry";
    };

    /** @class UTBoards
     *  Identifier for the UT readout boards non-event data for Allen
     */
    struct UTBoards : Identifier {
      inline static std::string const id = "UTBoards";
    };

    /** @class SciFiGeometry
     *  Identifier for the SciFi Geometry non-event data for Allen
     */
    struct SciFiGeometry : Identifier {
      inline static std::string const id = "SciFiGeometry";
    };

    /** @class UTLookupTables
     *  Identifier for the UT lookup tables for Allen
     */
    struct UTLookupTables : Identifier {
      inline static std::string const id = "UTLookupTables";
    };

    /** @class UTLookupTables
     *  Identifier for the beamline position for Allen
     */
    struct Beamline : Identifier {
      inline static std::string const id = "Beamline";
    };

    /** @class UTLookupTables
     *  Identifier for the magnetic field non-event data for Allen
     */
    struct MagneticField : Identifier {
      inline static std::string const id = "MagneticField";
    };

    /** @class MuonGeometry
     *  Identifier for the Muon geometry non-event data for Allen
     */
    struct MuonGeometry : Identifier {
      inline static std::string const id = "MuonGeometry";
    };

    /** @class MuonLookupTables
     *  Identifier for the Muon lookup tables for Allen
     */
    struct MuonLookupTables : Identifier {
      inline static std::string const id = "MuonLookupTables";
    };

  } // namespace NonEventData
} // namespace Allen
