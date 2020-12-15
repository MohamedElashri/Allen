/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include "DumpUTLookupTables.h"
#include "Utils.h"

DECLARE_COMPONENT(DumpUTLookupTables)

DumpUtils::Dumps DumpUTLookupTables::dumpGeometry() const
{

  auto& tool = detector();

  DumpUtils::Writer output {};

  std::tuple tables {std::tuple {"deflection", tool.DxLayTable()}, std::tuple {"Bdl", tool.BdlTable()}};
  for_each(tables, [&output](auto const& entry) {
    auto const& [name, t] = entry;
    auto const& table = t.table();
    output.write(t.nVar);
    for (int i = 0; i < t.nVar; ++i)
      output.write(t.nBins(i));
    output.write(table.size(), table);
  });

  return {{std::tuple {output.buffer(), "ut_tables", Allen::NonEventData::UTLookupTables::id}}};
}
