/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <array>
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

// LHCb
#include <MuonDet/DeMuonDetector.h>
#include <MuonDet/MuonNamespace.h>
#include <MuonDet/MuonStationCabling.h>
#include <MuonDet/MuonTell40Board.h>
#include <MuonDet/MuonNODEBoard.h>
#include <MuonDet/MuonTell40PCI.h>
#include <LHCbAlgs/Transformer.h>

#include <DD4hep/GrammarUnparsed.h>

// Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include "Dumper.h"
#include "MuonDefinitions.cuh"

#include "Detector/Muon/TileID.h"

namespace {
  inline const std::string MuonGeoCond = DeMuonLocation::Default;
  using std::array;
  using std::vector;
  using namespace Muon::Constants;

  struct MuonGeometry_t {
    MuonGeometry_t() = default;
    MuonGeometry_t(vector<char>& data, const DeMuonDetector& det)
    {
      DumpUtils::Writer output {};
      const int nStations = det.stations();
      assert(nStations == 4);
      unsigned int geom_version = det.upgradeReadout() ? 3 : 2;
      output.write(geom_version);

      if (geom_version == 3) {
        auto daqHelper = det.getUpgradeDAQInfo();

        // containers initialization
        array<unsigned int, maxTell40Number> whichStationIsTell40;
        array<array<unsigned int, maxTell40PCINumber>, maxTell40Number> tell40PCINumberOfActiveLink;
        array<array<array<unsigned int, maxNumberLinks>, maxTell40PCINumber>, maxTell40Number> mapRegionOfLink;
        array<array<array<unsigned int, maxNumberLinks>, maxTell40PCINumber>, maxTell40Number> mapQuarterOfLink;
        array<array<array<unsigned int, maxNumberLinks * ODEFrameSize>, maxTell40PCINumber>, maxTell40Number>
          mapTileInTell40;

        for (int station = 0; station < nStations; station++) {
          for (unsigned int iTell = 0; iTell < daqHelper->getNumberOfTell40Boards(station); iTell++) {
            whichStationIsTell40[iTell] = daqHelper->whichstationTell40(iTell);
          }
        }

        for (unsigned int itell = 0; itell < maxTell40Number; itell++) {
          for (unsigned int ipci = 0; ipci < maxTell40PCINumber; ipci++) {
            unsigned int active_link_per_PCI = 0;
            for (unsigned int ilink = 0; ilink < maxNumberLinks; ilink++) {
              unsigned int node = daqHelper->getODENumberNoHole(itell, ipci, ilink);
              unsigned int frame = daqHelper->getODEFrameNumberNoHole(itell, ipci, ilink);
              if (node > 0) {
                active_link_per_PCI++;
                tell40PCINumberOfActiveLink[itell][ipci] = active_link_per_PCI;

                for (unsigned int ich = 0; ich < ODEFrameSize; ich++) {
                  auto tileID = daqHelper->getTileIDInNODE(node - 1, frame * ODEFrameSize + ich);
                  if (tileID.isValid()) {
                    mapRegionOfLink[itell][ipci][ilink] = tileID.region();
                    mapQuarterOfLink[itell][ipci][ilink] = tileID.quarter();
                  } // valid tileID
                  mapTileInTell40[itell][ipci][(ilink) *ODEFrameSize + ich] = int(tileID);
                } // loop on channels
              }   // valid node
            }     // loop on links
          }       // loop on pci boards
        }         // loop on tell40s

        output.write(
          whichStationIsTell40, tell40PCINumberOfActiveLink, mapRegionOfLink, mapQuarterOfLink, mapTileInTell40);
      }
      else {

        auto daqHelper = det.getDAQInfo();

        vector<unsigned int> nTiles(daqHelper->TotTellNumber(), 0);
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
      } // Run2 cabling
      data = output.buffer();
    }
  };
} // namespace

/** @class DumpMuonGeometry
 *  Convert Muon geometry for use on an accelerator
 *
 *  @author Saverio Mariani
 *  @date   2022-06-10
 */

class DumpMuonGeometry final
  : public Allen::Dumpers::Dumper<void(MuonGeometry_t const&), LHCb::DetDesc::usesConditions<MuonGeometry_t>> {
public:
  DumpMuonGeometry(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const MuonGeometry_t& MuonGeo) const override;

  StatusCode initialize() override;

private:
  vector<char> m_data;
};

DECLARE_COMPONENT(DumpMuonGeometry)

DumpMuonGeometry::DumpMuonGeometry(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"MuonGeometryLocation", location(name, "geometry")}})
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
