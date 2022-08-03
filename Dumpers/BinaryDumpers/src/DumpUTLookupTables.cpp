/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include <DetDesc/GenericConditionAccessorHolder.h>
#include <PrKernel/IPrUTMagnetTool.h>
#include <Magnet/DeMagnet.h>
#include <Dumpers/Utils.h>
#include <DD4hep/GrammarUnparsed.h>

#include "Dumper.h"

namespace {
  struct LookupTables {

    LookupTables() = default;

    LookupTables(std::vector<char>& data, const IPrUTMagnetTool::Cache& cache)
    {
      DumpUtils::Writer output {};

      std::tuple tables {*cache.lutDxLay, *cache.lutBdl};
      for_each(tables, [&output](auto const& t) {
        auto const& table = t.table();
        output.write(t.nVar);
        for (int i = 0; i < t.nVar; ++i)
          output.write(t.nBins(i));
        output.write(table.size(), table);
      });

      data = output.buffer();
    }
  };
} // namespace

class DumpUTLookupTables final
  : public Allen::Dumpers::
      Dumper<void(LookupTables const&, DeMagnet const&), LHCb::DetDesc::usesConditions<LookupTables, DeMagnet>> {
public:
  DumpUTLookupTables(const std::string& name, ISvcLocator* svcLoc);

  void operator()(LookupTables const& tables, DeMagnet const& magnet) const override;

  StatusCode initialize() override;

private:
  ToolHandle<IPrUTMagnetTool> m_magnetTool {this, "PrUTMagnetTool", "PrUTMagnetTool"};

  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpUTLookupTables)

DumpUTLookupTables::DumpUTLookupTables(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(
    name,
    svcLoc,
    {KeyValue {"LookupTableLocation", location(name, "tables")},
     KeyValue {"Magnet", LHCb::Det::Magnet::det_path}})
{}

StatusCode DumpUTLookupTables::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::UTLookupTables::id, "ut_tables", m_data);
    addConditionDerivation(
      {m_magnetTool->cacheLocation()}, inputLocation<LookupTables>(), [&](IPrUTMagnetTool::Cache const& cache) {
        LookupTables tables {m_data, cache};
        dump();
        return tables;
      });
  });
}

void DumpUTLookupTables::operator()(const LookupTables&, DeMagnet const&) const {}
