/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <vector>

#include <boost/filesystem.hpp>

#include "DumpUTHits.h"
#include <Dumpers/Utils.h>

namespace fs = boost::filesystem;
#ifdef USE_DD4HEP
namespace {
  constexpr int NBSIDE = 2;
  constexpr int NBHALFLAYER = 4;
  constexpr int NBSTAVE = 9;
  constexpr int NBFACE = 2;
  constexpr int NBMODULE = 8;
  constexpr int NBSUBSECTOR = 2;
} // namespace
#endif

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(DumpUTHits)

DumpUTHits::DumpUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default}, KeyValue {"UTHitsLocation", UTInfo::HitLocation}})
{}

StatusCode DumpUTHits::initialize()
{
  if (!DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }
  return StatusCode::SUCCESS;
}

void DumpUTHits::operator()(const LHCb::ODIN& odin, const UT::HitHandler& hitHandler) const
{

  /*Write UT variables for GPU to binary file */
  DumpUtils::FileWriter outfile {m_outputDirectory.value() + "/" + std::to_string(odin.runNumber()) + "_" +
                                 std::to_string(odin.eventNumber()) + ".bin"};

  // UT
  // Variables written to binary file as GPU input for VeloUT tracking

  constexpr int n_layers_ut = 4;
  auto ut_cos = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_yBegin = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_yEnd = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_dxDy = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_zAtYEq0 = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_xAtYEq0 = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_weight = std::array<std::vector<float>, n_layers_ut> {};
  auto ut_highThreshold = std::array<std::vector<int>, n_layers_ut> {};
  auto ut_LHCbID = std::array<std::vector<unsigned int>, n_layers_ut> {};

  for (int iSide = 0; iSide < NBSIDE; ++iSide) {
    for (int iLayer = 0; iLayer < NBHALFLAYER; ++iLayer) {
      for (int iStave = 0; iStave < NBSTAVE; ++iStave) {
        for (int iFace = 0; iFace < NBFACE; ++iFace) {
          for (int iModule = 0; iModule < NBMODULE; ++iModule) {
            for (int iSector = 0; iSector < NBSUBSECTOR; ++iSector) {
              for (const auto& hit : hitHandler.hits(iSide, iLayer, iStave, iFace, iModule, iSector)) {
                /* For GPU input */
                ut_cos[hit.planeCode()].push_back(hit.cos());
                ut_yBegin[hit.planeCode()].push_back(hit.yBegin());
                ut_yEnd[hit.planeCode()].push_back(hit.yEnd());
                ut_dxDy[hit.planeCode()].push_back(hit.dxDy());
                ut_zAtYEq0[hit.planeCode()].push_back(hit.zAtYEq0());
                ut_xAtYEq0[hit.planeCode()].push_back(hit.xAtYEq0());
                ut_weight[hit.planeCode()].push_back(hit.weight());
                ut_highThreshold[hit.planeCode()].push_back(hit.highThreshold());
                ut_LHCbID[hit.planeCode()].push_back(hit.lhcbID().lhcbID());
              }
            }
          }
        }
      }
    }
  }

  // first the number of hits per layer in each half as header
  for (int iStation = 0; iStation < 2; ++iStation) {
    for (int iLayer = 0; iLayer < 2; ++iLayer) {
      int index = 2 * iStation + iLayer;
      uint32_t n_hits = (int) (ut_cos[index].size());
      outfile.write(n_hits);
    }
  }

  // then the vectors containing the variables
  for (int i_layer = 0; i_layer < n_layers_ut; ++i_layer) {
    outfile.write(
      ut_cos[i_layer],
      ut_yBegin[i_layer],
      ut_yEnd[i_layer],
      ut_dxDy[i_layer],
      ut_zAtYEq0[i_layer],
      ut_xAtYEq0[i_layer],
      ut_weight[i_layer],
      ut_highThreshold[i_layer],
      ut_LHCbID[i_layer]);
  }
}
