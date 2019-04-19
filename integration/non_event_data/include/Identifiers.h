#pragma once

#include <string>

namespace Allen {
namespace NonEventData {
  struct Identifier{};

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

}
}
