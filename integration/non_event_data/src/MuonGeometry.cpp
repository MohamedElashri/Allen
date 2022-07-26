/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "MuonDefinitions.cuh"
#include "MuonGeometry.cuh"
#include "MuonTables.cuh"

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MuonGeometry::MuonGeometry(
  std::vector<char>& host_geometry_raw,
  char*& dev_geometry_raw,
  Muon::MuonGeometry*& dev_muon_geometry) :
  m_host_geometry_raw {host_geometry_raw},
  m_dev_geometry_raw {dev_geometry_raw}, m_muon_geometry {dev_muon_geometry}
{}

void Consumers::MuonGeometry::consume(std::vector<char> const& data)
{
  const char* raw_input = data.data();
  int version;
  std::copy_n((uint*) raw_input, 1, &version);
  raw_input += sizeof(uint);

  // std::cout << "VERSION IS NOW: " << version << std::endl;
  if (version == 2) {

    size_t nTilesSize;
    std::copy_n((size_t*) raw_input, 1, &nTilesSize);
    assert(nTilesSize == Muon::MuonGeometry::m_tiles_size);
    size_t sizes[Muon::MuonGeometry::m_tiles_size];
    unsigned int* tiles[Muon::MuonGeometry::m_tiles_size];
    size_t tilesOffset[Muon::MuonGeometry::m_tiles_size];
    raw_input += sizeof(size_t);
    for (size_t i = 0; i < nTilesSize; i++) {
      size_t tilesSize;
      std::copy_n((size_t*) raw_input, 1, &tilesSize);
      sizes[i] = tilesSize;

      raw_input += sizeof(size_t);
      tilesOffset[i] = ((unsigned*) raw_input) - ((unsigned*) data.data());
      raw_input += sizeof(unsigned) * tilesSize;
    }

    auto& dev_geometry_raw = m_dev_geometry_raw.get();
    auto& host_geometry_raw = m_host_geometry_raw.get();
    if (!m_muon_geometry) {
      Allen::malloc((void**) &dev_geometry_raw, data.size());
      Allen::malloc((void**) &m_muon_geometry.get(), sizeof(Muon::MuonGeometry));
      m_size = sizeof(Muon::MuonGeometry);
    }
    else if (host_geometry_raw.size() != data.size()) {
      throw StrException {string {"sizes don't match: "} + to_string(host_geometry_raw.size()) + " " +
                          to_string(data.size())};
    }
    host_geometry_raw = data;
    Allen::memcpy(dev_geometry_raw, host_geometry_raw.data(), host_geometry_raw.size(), Allen::memcpyHostToDevice);

    for (size_t i = 0; i < nTilesSize; i++) {
      tiles[i] = ((unsigned*) dev_geometry_raw) + tilesOffset[i];
    }

    Muon::MuonGeometry host_muon_geometry {sizes, tiles};
    host_muon_geometry.setVersion(2);

    Allen::memcpy(m_muon_geometry.get(), &host_muon_geometry, sizeof(Muon::MuonGeometry), Allen::memcpyHostToDevice);
  }
  else if (version == 3) {
    // std::cout << "That's the new consumer for the dumped muon geometry" << std::endl;
    // std::cout << "Geometry version set to 3" << std::endl;

    unsigned int stationsTell40[Muon::Constants::maxTell40Number];
    unsigned int activeLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber];
    unsigned int regionOfLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                             [Muon::Constants::maxNumberLinks];
    unsigned int quarterOfLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                              [Muon::Constants::maxNumberLinks];
    unsigned int tileinTell40[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                             [Muon::Constants::maxNumberLinks * Muon::Constants::ODEFrameSize];

    ///////////terrible, but let's see if it's working
    for (size_t itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      unsigned int station;
      std::copy_n((unsigned int*) raw_input, 1, &station);
      raw_input += sizeof(unsigned int);
      stationsTell40[itell] = station;
      // std::cout << "Adding to stationTell40 " <<station << std::endl;
    }

    //    std::cout << "stationsTell40 vector filled" << std::endl;

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        unsigned int activelink;
        std::copy_n((unsigned int*) raw_input, 1, &activelink);
        raw_input += sizeof(unsigned int);
        // std::cout << "Adding to activeLink " << activelink << std::endl;
        activeLink[itell][ipci] = activelink;
      }
    }

    // std::cout << "activeLink vector filled" << std::endl;

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          unsigned int linkregion;
          std::copy_n((unsigned int*) raw_input, 1, &linkregion);
          raw_input += sizeof(unsigned int);
          // std::cout << "Adding to LinkRegion " << linkregion << std::endl;
          regionOfLink[itell][ipci][ilink] = linkregion;
        }
      }
    }

    // std::cout << "regionOfLink vector filled" << std::endl;

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          unsigned int linkquarter;
          std::copy_n((unsigned int*) raw_input, 1, &linkquarter);
          raw_input += sizeof(unsigned int);
          // std::cout << "Adding to LinkQuarter " << linkquarter << std::endl;
          quarterOfLink[itell][ipci][ilink] = linkquarter;
        }
      }
    }

    // std::cout << "quarterOfLink vector filled" << std::endl;

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          for (unsigned int ich = 0; ich < Muon::Constants::ODEFrameSize; ich++) {
            unsigned int tileID;
            std::copy_n((unsigned int*) raw_input, 1, &tileID);
            raw_input += sizeof(unsigned int);
            // std::cout << "Adding to tileID map " << tileID << std::endl;
            tileinTell40[itell][ipci][ilink * Muon::Constants::ODEFrameSize + ich] = tileID;
          }
        }
      }
    }

    // std::cout << "tileinTell40 vector filled" << std::endl;

    // std::cout << "DUMPING NOW THE MAPS FROM THE CONSUMER" << std::endl;
    // for (auto i = 0; i < 2; i++){
    // 	std::cout << "Tell40 number " << i << std::endl;
    // 	std::cout << "    which_station_is_tell_40 " << stationsTell40[i] << std::endl;
    // 	for (auto j = 0; j < Muon::Constants::maxTell40PCINumber; j++){
    // 	  std::cout << "        pci number " << j << std::endl;
    // 	  std::cout << "        numberOfActiveLink " << activeLink[i][j] << std::endl;
    // 	  for (auto k = 0; k < Muon::Constants::maxNumberLinks; k++){
    // 	    std::cout <<  "            link number " << k << std::endl;
    // 	    std::cout  << "            QuarterOfLink " << quarterOfLink[i][j][k] << ", RegionOfLink " <<
    // regionOfLink[i][j][k] << std::endl; 	    for (auto l = 0; l < Muon::Constants::ODEFrameSize; l++){
    // std::cout << " ODE number " << l << std::endl; 	      std::cout << "              TileInTell40 map " <<
    // tileinTell40[i][j][k * Muon::Constants::ODEFrameSize + l] << std::endl;
    // 	    }
    // 	  }
    // 	}
    // }

    // throw StrException {string {"bpnfpw: "}};

    // for (auto i = 0; i < Muon::Constants::maxTell40Number; i++){
    // 	std::cout << "Tell40 number " << i << std::endl;
    // 	std::cout << "    which_station_is_tell_40 " << stationsTell40[i] << std::endl;
    // 	for (auto j = 0; j <Muon::Constants::maxTell40PCINumber; j++){
    // 	  std::cout << "        pci number " << j << std::endl;
    // 	  std::cout << "        numberOfActiveLink " << activeLink[i][j] << std::endl;
    // 	  for (auto k = 0; k < Muon::Constants::maxNumberLinks; k++){
    // 	    std::cout <<  "            link number " << k << std::endl;
    // 	    std::cout  << "            QuarterOfLink " << quarterOfLink[i][j][k] << std::endl;
    // 	    std::cout  << "            RegionOfLink " << regionOfLink[i][j][k] << std::endl;
    // 	    for (auto l = 0; l < Muon::Constants::ODEFrameSize; l++){
    // 	      std::cout << "              ODE number " << l << std::endl;
    // 	      std::cout << "              TileInTell40 map " << tileinTell40[i][j][k * Muon::Constants::ODEFrameSize +
    // l] << std::endl;
    // 	    }
    // 	  }
    // 	}
    // }

    auto& dev_geometry_raw = m_dev_geometry_raw.get();
    auto& host_geometry_raw = m_host_geometry_raw.get();
    if (!m_muon_geometry) {
      Allen::malloc((void**) &dev_geometry_raw, data.size());
      Allen::malloc((void**) &m_muon_geometry.get(), sizeof(Muon::MuonGeometry));
      m_size = sizeof(Muon::MuonGeometry);
    }
    else if (host_geometry_raw.size() != data.size()) {
      throw StrException {string {"sizes don't match: "} + to_string(host_geometry_raw.size()) + " " +
                          to_string(data.size())};
    }
    host_geometry_raw = data;
    Allen::memcpy(dev_geometry_raw, host_geometry_raw.data(), host_geometry_raw.size(), Allen::memcpyHostToDevice);

    Muon::MuonGeometry host_muon_geometry {stationsTell40, activeLink, regionOfLink, quarterOfLink, tileinTell40};
    host_muon_geometry.setVersion(3);

    // std::cout << "Before the copy" << std::endl;
    // std::cout << "m_muon_geometry size is "<< sizeof(m_muon_geometry.get()) << ", host is "<<
    // sizeof(host_muon_geometry) << std::endl;
    Allen::memcpy(m_muon_geometry.get(), &host_muon_geometry, sizeof(Muon::MuonGeometry), Allen::memcpyHostToDevice);
    // std::cout << "After the copy" << std::endl;
  }
  else {
    error_cout << "unrecognized muon geometry version" << std::endl;
  }
}
