/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <vector>

#include <boost/filesystem.hpp>

#include "Event/RawEvent.h"
#include "Event/VPLightCluster.h"

#include "DumpFTHits.h"
#include "Utils.h"

namespace fs = boost::filesystem;

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(DumpFTHits)

DumpFTHits::DumpFTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default}, KeyValue {"FTHitsLocation", PrFTInfo::FTHitsLocation}})
{}

StatusCode DumpFTHits::initialize()
{
  if (!DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }
  return StatusCode::SUCCESS;
}

void DumpFTHits::operator()(const LHCb::ODIN& odin, const PrFTHitHandler<PrHit>& hitHandler) const
{

  /*Write SciFi variables for GPU to binary file */
  DumpUtils::FileWriter outfile {m_outputDirectory.value() + "/" + std::to_string(odin.runNumber()) + "_" +
                                 std::to_string(odin.eventNumber()) + ".bin"};

  // SciFi
  constexpr int n_layers_scifi = 24;
  auto scifi_x = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_z = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_w = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_dxdy = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_dzdy = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_YMin = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_YMax = std::array<std::vector<float>, n_layers_scifi> {};
  auto scifi_LHCbID = std::array<std::vector<unsigned int>, n_layers_scifi> {};
  auto scifi_hitPlaneCode = std::array<std::vector<int>, n_layers_scifi> {};
  auto scifi_hitZone = std::array<std::vector<int>, n_layers_scifi> {};

  for (unsigned int zone = 0; PrFTInfo::nbZones() > zone; ++zone) {
    for (const auto& hit : hitHandler.hits(zone)) {
      // get the LHCbID from the PrHit
      LHCb::LHCbID lhcbid = hit.id();

      // Fill the info for the eventual binary
      int code = 2 * hit.planeCode() + hit.zone();
      scifi_x[code].push_back(hit.x());
      scifi_z[code].push_back(hit.z());
      scifi_w[code].push_back(hit.w());
      scifi_dxdy[code].push_back(hit.dxDy());
      scifi_dzdy[code].push_back(hit.dzDy());
      scifi_YMin[code].push_back(hit.yMin());
      scifi_YMax[code].push_back(hit.yMax());
      scifi_LHCbID[code].push_back(lhcbid.lhcbID());
      scifi_hitPlaneCode[code].push_back(hit.planeCode());
      scifi_hitZone[code].push_back(hit.zone());
    }
  }

  // first the number of hits per layer in each half as header
  for (int index = 0; index < n_layers_scifi; ++index) {
    uint32_t n_hits = (int) (scifi_x[index].size());
    outfile.write(n_hits);
  }

  // then the vectors containing the variables
  for (int index = 0; index < n_layers_scifi; ++index) {
    outfile.write(
      scifi_x[index],
      scifi_z[index],
      scifi_w[index],
      scifi_dxdy[index],
      scifi_dzdy[index],
      scifi_YMin[index],
      scifi_YMax[index],
      scifi_LHCbID[index],
      scifi_hitPlaneCode[index],
      scifi_hitZone[index]);
  }
}
