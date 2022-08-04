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

    unsigned int stationsTell40[Muon::Constants::maxTell40Number];
    unsigned int activeLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber];
    unsigned int regionOfLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                             [Muon::Constants::maxNumberLinks];
    unsigned int quarterOfLink[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                              [Muon::Constants::maxNumberLinks];
    unsigned int tileinTell40[Muon::Constants::maxTell40Number][Muon::Constants::maxTell40PCINumber]
                             [Muon::Constants::maxNumberLinks * Muon::Constants::ODEFrameSize];

    for (size_t itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      unsigned int station;
      std::copy_n((unsigned int*) raw_input, 1, &station);
      raw_input += sizeof(unsigned int);
      stationsTell40[itell] = station;
    }

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        unsigned int activelink;
        std::copy_n((unsigned int*) raw_input, 1, &activelink);
        raw_input += sizeof(unsigned int);
        activeLink[itell][ipci] = activelink;
      }
    }

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          unsigned int linkregion;
          std::copy_n((unsigned int*) raw_input, 1, &linkregion);
          raw_input += sizeof(unsigned int);
          regionOfLink[itell][ipci][ilink] = linkregion;
        }
      }
    }

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          unsigned int linkquarter;
          std::copy_n((unsigned int*) raw_input, 1, &linkquarter);
          raw_input += sizeof(unsigned int);
          quarterOfLink[itell][ipci][ilink] = linkquarter;
        }
      }
    }

    for (unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++) {
      for (unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++) {
        for (unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++) {
          for (unsigned int ich = 0; ich < Muon::Constants::ODEFrameSize; ich++) {
            unsigned int tileID;
            std::copy_n((unsigned int*) raw_input, 1, &tileID);
            raw_input += sizeof(unsigned int);
            tileinTell40[itell][ipci][ilink * Muon::Constants::ODEFrameSize + ich] = tileID;
          }
        }
      }
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

    Muon::MuonGeometry host_muon_geometry {stationsTell40, activeLink, regionOfLink, quarterOfLink, tileinTell40};
    host_muon_geometry.setVersion(3);
    Allen::memcpy(m_muon_geometry.get(), &host_muon_geometry, sizeof(Muon::MuonGeometry), Allen::memcpyHostToDevice);
  }
  else {
    error_cout << "unrecognized muon geometry version" << std::endl;
  }
}
