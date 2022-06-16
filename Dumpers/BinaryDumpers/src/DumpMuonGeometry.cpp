/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <array>
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include <DetDesc/GenericConditionAccessorHolder.h>
#include <MuonDet/MuonNamespace.h>
#include <MuonDet/MuonDAQHelper.h>
#include <MuonDet/DeMuonDetector.h>

#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include <DD4hep/GrammarUnparsed.h>

#include "Dumper.h"

namespace {
  inline const std::string MuonGeoCond = DeMuonLocation::Default;

  struct MuonGeometry_t {

    MuonGeometry_t() {};
    MuonGeometry_t(std::vector<char>& data, const DeMuonDetector& det)
    {
      DumpUtils::Writer output {};

      const int nStations = det.stations();
      assert(nStations == 4);

      auto* daqHelper = const_cast<MuonDAQHelper*>(det.getDAQInfo());
      std::array<float, 4> innerX {}, innerY {}, outerX {}, outerY {}, stationZ {};

      for (int s = 0; s != nStations; ++s) {
        innerX[s] = det.getInnerX(s);
        innerY[s] = det.getInnerY(s);
        outerX[s] = det.getOuterX(s);
        outerY[s] = det.getOuterY(s);
        stationZ[s] = det.getStationZ(s);
      }

      output.write(
        innerX.size(),
        innerX,
        innerY.size(),
        innerY,
        outerX.size(),
        outerX,
        outerY.size(),
        outerY,
        stationZ.size(),
        stationZ);

      std::vector<unsigned int> nTiles(daqHelper->TotTellNumber(), 0);
      for (auto tell1 = 0u; tell1 < daqHelper->TotTellNumber(); ++tell1) {
        nTiles[tell1] = daqHelper->getADDInTell1(tell1).size();
      }

      output.write(nTiles.size());
      for (auto tell1 = 0u; tell1 < daqHelper->TotTellNumber(); ++tell1) {
        auto const& tiles = daqHelper->getADDInTell1(tell1);
        output.write(tiles.size());
        for (auto const& tile : tiles) {
          output.write(static_cast<unsigned int>(tile));
        }
      }
      data = output.buffer();
    }
  };
} // namespace

/** @class DumpMuonGeometry
 *  Dump geometry for the muon detector
 *
 *  @author Saverio Mariani
 *  @date   2022-06-03
 */
class DumpMuonGeometry final
  : public Allen::Dumpers::Dumper<void(MuonGeometry_t const&), LHCb::DetDesc::usesConditions<MuonGeometry_t>> {
public:
  DumpMuonGeometry(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const MuonGeometry_t& MuonGeo) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpMuonGeometry)

DumpMuonGeometry::DumpMuonGeometry(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"MuonGeometryLocation", "AlgorithmSpecific-" + name + "-geometry"}})
{}

StatusCode DumpMuonGeometry::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::MuonGeometry::id, "muon_geometry", m_data);
    addConditionDerivation({MuonGeoCond}, inputLocation<MuonGeometry_t>(), [&](DeMuonDetector const& det) {
      auto MuonGeo = MuonGeometry_t {m_data, det};
      dump();
      return MuonGeo;
    });
  });
}

void DumpMuonGeometry::operator()(const MuonGeometry_t&) const {}
