/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <array>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>

#include <range/v3/algorithm/any_of.hpp>
#include <range/v3/algorithm/fill.hpp>
#include <range/v3/core.hpp>
#include <range/v3/numeric/accumulate.hpp>
#include <range/v3/view/cartesian_product.hpp>
#include <range/v3/view/concat.hpp>
#include <range/v3/view/iota.hpp>
#include <range/v3/view/take.hpp>

#if RANGE_V3_VERSION < 900
namespace ranges::views {
  using namespace ranges::view;
}
#endif

#include <boost/format.hpp>
#include <boost/numeric/conversion/cast.hpp>

#include <Detector/Muon/Layout.h>
#include <MuonDet/DeMuonDetector.h>
#include <MuonDet/MuonNamespace.h>
#include "Dumper.h"
#include <Dumpers/Utils.h>
#include "MuonDefinitions.cuh"

#include <DD4hep/GrammarUnparsed.h>

namespace {
  using boost::numeric_cast;
  using std::array;
  using std::ios;
  using std::ofstream;
  using std::string;
  using std::tuple;
  using std::vector;
  using namespace ranges;

  inline const std::string MuonTableCond = DeMuonLocation::Default;
  
  constexpr array<int, 16> padGridX {48, 48, 48, 48, 48, 48, 48, 48, 12, 12, 12, 12, 12, 12, 12, 12};
  constexpr array<int, 16> stripXGridX {48, 48, 48, 48, 48, 48, 48, 48, 12, 12, 12, 12, 12, 12, 12, 12};

  struct MuonTable_t {
    MuonTable_t() = default;
    MuonTable_t(std::vector<char>& data, const DeMuonDetector& det)
    {

      unsigned int version;
      DumpUtils::Writer output {};
      const int nStations = det.stations();
      assert(nStations == 4);
      const int nRegions = det.regions() / nStations;
      assert(nRegions == 4);
      
      // Detector and mat geometry
      vector<float> padSizeX {}, stripXSizeX {}, stripYSizeX {}, padSizeY {}, stripXSizeY {}, stripYSizeY {};
      array<unsigned int, 16> padOffset {}, stripXOffset {}, stripYOffset {}, padSizeOffset {}, stripXSizeOffset {}, stripYSizeOffset {};
      array<vector<array<float, 3>>, 4> padTable {}, stripXTable {}, stripYTable {};

      auto nChannels = [](size_t s, const auto& gridX, const auto& gridY) {
	return [s, &gridX, &gridY](auto tot, const auto r) { return tot + gridX[4 * s + r] * gridY[4 * s + r]; };
      };
	
      //versioning?????
      if (true) { //discriminating between Run2 and Upgrade encoding	
	std::cout << "MuonTables: Thanks for your work trying to provide me a decoding, It's sad not to be understood :(" << std::endl;

	version = 3;
	output.write(version);

	constexpr array<int, 16> padGridY {8, 16, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
	constexpr array<int, 16> stripXGridY{1, 2, 8, 8, 1, 2, 2, 2, 8, 2, 2, 2, 8, 2, 2, 8};
	constexpr array<int, 16> stripYGridX{8, 4, 48, 48, 8, 4, 2, 2, 12, 4, 2, 2, 12, 4, 2, 12};
	constexpr array<int, 16> stripYGridY{8, 16, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};

	for (int s = 0; s < nStations; ++s) {
	  padTable[s].resize   (12 * accumulate(views::ints(0, 4), 0, nChannels(s, padGridX, padGridY)));
	  stripXTable[s].resize(12 * accumulate(views::ints(0, 4), 0, nChannels(s, stripXGridX, stripXGridY)));
	  stripYTable[s].resize(12 * accumulate(views::ints(0, 4), 0, nChannels(s, stripYGridX, stripYGridY)));
	}

	 for (auto& [sizeX, sizeY, offset, gridY] : 
	   {make_tuple(std::ref(padSizeX), std::ref(padSizeY), std::ref(padSizeOffset), std::ref(padGridY)),
	       make_tuple(std::ref(stripXSizeX), std::ref(stripXSizeY), std::ref(stripXSizeOffset), std::ref(stripXGridY)),
	       make_tuple(std::ref(stripYSizeX), std::ref(stripYSizeY), std::ref(stripYSizeOffset), std::ref(stripYGridY))}) {
	   sizeX.resize(24 * accumulate(gridY, 0));
	   sizeY.resize(24 * accumulate(gridY, 0));
	   for (size_t i = 0; i < gridY.size() - 1; ++i) {
	     offset[i + 1] = offset[i] + 24 * gridY[i];
	   }
	 }

	string padType {"pad"}, stripXType {"stripX"}, stripYType {"stripY"};
	// Pads
	auto pad = std::tie(padType, padGridX, padGridY, padSizeX, padSizeY, padOffset, padSizeOffset, padTable);
	// X strips
	auto stripX = std::tie(stripXType, stripXGridX, stripXGridY, stripXSizeX, stripXSizeY, stripXOffset, stripXSizeOffset, stripXTable);
	// Y strips
	auto stripY = std::tie(stripYType, stripYGridX, stripYGridY, stripYSizeX, stripYSizeY, stripYOffset, stripYSizeOffset, stripYTable);

	for (auto& [t, gridX, gridY, sizeX, sizeY, offset, sizeOffset, table] : {pad, stripX, stripY}) {
	  for (auto station : views::ints(0, nStations)) {
	    size_t index = 0;
	    for (auto region : views::ints(0, nRegions)) {
	      size_t gidx = station * 4 + region;
	      offset[gidx] = index;
	      
	      auto yxRange = views::concat(views::cartesian_product(views::ints(0, gridY[gidx]), views::ints(gridX[gidx], 2 * gridX[gidx])),
					   views::cartesian_product(views::ints(gridY[gidx], 2 * gridY[gidx]), views::ints(0, 2 * gridX[gidx])));
	      // loop over quarters
	      for (auto [quarter, yx] : views::cartesian_product(views::ints(0, 4), yxRange)) {
		auto [y, x] = yx;
		LHCb::Detector::Muon::TileID tile {station,
		    LHCb::Detector::Muon::Layout {static_cast<unsigned int>(gridX[gidx]),
		      static_cast<unsigned int>(gridY[gidx])},
		    region,
		      quarter,
		      x,
		      y};
		auto pos = det.position(tile);
		if (!pos) {
		  std::stringstream e;
		  e << t << " " << station << " " << region << " " << quarter << " " << gridX[gidx] << " " << gridY[gidx]
		    << " " << x << " " << y << "\n";
		  throw GaudiException {e.str(), __FILE__, StatusCode::FAILURE};
		} else {
		  auto sizeIdx = MuonUtils::size_index(sizeOffset, gridX, gridY, tile); //why this?
		  
		  // positions are always indexed by station
		  table[station][index++] = {
		    numeric_cast<float>(pos->x()), numeric_cast<float>(pos->y()), numeric_cast<float>(pos->z())};
		  
		  // sizes are specially indexed
		  if (pos->dX() > sizeX[sizeIdx]) sizeX[sizeIdx] = pos->dX();
		  if (pos->dY() > sizeY[sizeIdx]) sizeY[sizeIdx] = pos->dY();
		}
	      }
	    }
	  }

	  output.write(gridX.size(), gridX,
		       gridY.size(), gridY,
		       sizeX.size(), sizeX,
		       sizeY.size(), sizeY,
		       offset.size(), offset, table.size());
	  for (const auto& station : table) {
	    output.write(station.size());
	    for (const auto& point : station) {
	      output.write(point);
	    }
	  }
	}

      } else { 

	version = 2;
	output.write(version);

	constexpr array<int, 16> padGridY {8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
	constexpr array<int, 16> stripXGridY {1, 2, 2, 2, 1, 2, 2, 2, 8, 2, 2, 2, 8, 2, 2, 2};
	constexpr array<int, 16> stripYGridX {8, 4, 2, 2, 8, 4, 2, 2, 12, 4, 2, 2, 12, 4, 2, 2};
	constexpr array<int, 16> stripYGridY {8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
      
	for (int s = 0; s < nStations; ++s) {
	  padTable[s].resize(Muon::Constants::ODEFrameSize * (padGridX[s] * padGridY[s]));
	  stripXTable[s].resize(12 * accumulate(views::ints(0, 4), 0, nChannels(s, stripXGridX, stripXGridY)));
	  stripYTable[s].resize(12 * accumulate(views::ints(0, 4), 0, nChannels(s, stripYGridX, stripYGridY)));
	}
	
	for (auto& [sizeX, sizeY, offset, gridY] : 
	  {make_tuple(std::ref(padSizeX), std::ref(padSizeY), std::ref(padSizeOffset), std::ref(padGridY)),
	      make_tuple(std::ref(stripXSizeX), std::ref(stripXSizeY), std::ref(stripXSizeOffset), std::ref(stripXGridY)),
	      make_tuple(std::ref(stripYSizeX), std::ref(stripYSizeY), std::ref(stripYSizeOffset), std::ref(stripYGridY))}) {
	  sizeX.resize(24 * accumulate(gridY, 0));
	  sizeY.resize(24 * accumulate(gridY, 0));
	  for (size_t i = 0; i < gridY.size() - 1; ++i) {
	    offset[i + 1] = offset[i] + 24 * gridY[i];
	  }
	}

	string padType {"pad"}, stripXType {"stripX"}, stripYType {"stripY"};
	// Pads
	auto pad = std::tie(padType, padGridX, padGridY, padSizeX, padSizeY, padOffset, padSizeOffset, padTable);
	// X strips
	auto stripX = std::tie(
			       stripXType, stripXGridX, stripXGridY, stripXSizeX, stripXSizeY, stripXOffset, stripXSizeOffset, stripXTable);
	// Y strips
	auto stripY = std::tie(
			       stripYType, stripYGridX, stripYGridY, stripYSizeX, stripYSizeY, stripYOffset, stripYSizeOffset, stripYTable);
		
	for (auto& [t, gridX, gridY, sizeX, sizeY, offset, sizeOffset, table] : {pad, stripX, stripY}) {
	  for (auto station : views::ints(0, nStations)) {
	    size_t index = 0;
	    for (auto region : views::ints(0, nRegions)) {
	      size_t gidx = station * 4 + region;
	      offset[gidx] = index;
	      
	      auto yxRange = views::concat(views::cartesian_product(views::ints(0, gridY[gidx]), views::ints(gridX[gidx], 2 * gridX[gidx])),
					   views::cartesian_product(views::ints(gridY[gidx], 2 * gridY[gidx]), views::ints(0, 2 * gridX[gidx])));
	      // loop over quarters
	      for (auto [quarter, yx] : views::cartesian_product(views::ints(0, 4), yxRange)) {
		auto [y, x] = yx;
		LHCb::Detector::Muon::TileID tile {station,
		    LHCb::Detector::Muon::Layout {static_cast<unsigned int>(gridX[gidx]),
		      static_cast<unsigned int>(gridY[gidx])},
		    region,
		      quarter,
		      x,
		      y};
		auto pos = det.position(tile);
		if (!pos) {
		  std::stringstream e;
		  e << t << " " << station << " " << region << " " << quarter << " " << gridX[gidx] << " " << gridY[gidx]
		    << " " << x << " " << y << "\n";
		  throw GaudiException {e.str(), __FILE__, StatusCode::FAILURE};
		}
		else {
		  auto sizeIdx = MuonUtils::size_index(sizeOffset, gridX, gridY, tile);
		  
		  // positions are always indexed by station
		  table[station][index++] = {
		    numeric_cast<float>(pos->x()), numeric_cast<float>(pos->y()), numeric_cast<float>(pos->z())};
		  
		  // sizes are specially indexed
		  if (pos->dX() > sizeX[sizeIdx]) sizeX[sizeIdx] = pos->dX(); 
		  if (pos->dY() > sizeY[sizeIdx]) sizeY[sizeIdx] = pos->dY();
		}
	      }
	    }
	  }
	  output.write(gridX.size(), gridX,
		       gridY.size(), gridY,
		       sizeX.size(), sizeX,
		       sizeY.size(), sizeY,
		       offset.size(), offset, table.size());
	  for (const auto& station : table) {
	    output.write(station.size());
	    for (const auto& point : station) {
	      output.write(point);
	    }
	  }
	}
      } //Run2 enconding
      data = output.buffer();
    }
  };
} // namespace


/** @class DumpMuonTable
 *  Dump tables for the muon detector
 *
 *  @author Saverio Mariani
 *  @date   2022-06-03
 */
class DumpMuonTable final
  : public Allen::Dumpers::Dumper<void(MuonTable_t const&), LHCb::DetDesc::usesConditions<MuonTable_t>> {
public:
  DumpMuonTable(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const MuonTable_t& MuonTable) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpMuonTable)

DumpMuonTable::DumpMuonTable(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"MuonTableLocation", "AlgorithmSpecific-" + name + "-table"}})
{}

StatusCode DumpMuonTable::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::MuonLookupTables::id, "muon_tables", m_data);
    addConditionDerivation({MuonTableCond}, inputLocation<MuonTable_t>(), [&](DeMuonDetector const& det) {
	auto MuonTable = MuonTable_t {m_data, det};
      dump();
      return MuonTable;
    });
  });
}

void DumpMuonTable::operator()(const MuonTable_t&) const {}
