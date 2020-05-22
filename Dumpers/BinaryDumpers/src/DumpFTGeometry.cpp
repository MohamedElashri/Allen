/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include "DumpFTGeometry.h"

namespace {
  using std::ios;
  using std::ofstream;
  using std::string;
  using std::tuple;
  using std::vector;
} // namespace

DECLARE_COMPONENT(DumpFTGeometry)

DumpUtils::Dumps DumpFTGeometry::dumpGeometry() const
{
  // Detector and mat geometry
  const auto& det = detector();
  const auto& stations = det.stations();
  const auto& layersFirstStation = stations[0]->layers();
  const auto& quartersFirstLayer = layersFirstStation[0]->quarters();
  uint32_t number_of_stations = stations.size();
  uint32_t number_of_layers_per_station = layersFirstStation.size();
  uint32_t number_of_layers = number_of_stations * number_of_layers_per_station;
  uint32_t number_of_quarters_per_layer = quartersFirstLayer.size();
  uint32_t number_of_quarters = number_of_quarters_per_layer * number_of_layers;
  vector<uint32_t> number_of_modules(det.nQuarters);
  uint32_t number_of_mats = 0;
  uint32_t number_of_mats_per_module;

  vector<float> mirrorPointX;
  vector<float> mirrorPointY;
  vector<float> mirrorPointZ;
  vector<float> ddxX;
  vector<float> ddxY;
  vector<float> ddxZ;
  vector<float> uBegin;
  vector<float> halfChannelPitch;
  vector<float> dieGap;
  vector<float> sipmPitch;
  vector<float> dxdy;
  vector<float> dzdy;
  vector<float> globaldy;

  // First uniqueMat is 512, save space by subtracting
  const uint32_t uniqueMatOffset = 512;
  // PrStoreFTHit.h uses hardcoded 2<<11, which is too much.
  uint32_t max_uniqueMat = (2 << 10) - uniqueMatOffset;
  mirrorPointX.resize(max_uniqueMat);
  mirrorPointY.resize(max_uniqueMat);
  mirrorPointZ.resize(max_uniqueMat);
  ddxX.resize(max_uniqueMat);
  ddxY.resize(max_uniqueMat);
  ddxZ.resize(max_uniqueMat);
  uBegin.resize(max_uniqueMat);
  halfChannelPitch.resize(max_uniqueMat);
  dieGap.resize(max_uniqueMat);
  sipmPitch.resize(max_uniqueMat);
  dxdy.resize(max_uniqueMat);
  dzdy.resize(max_uniqueMat);
  globaldy.resize(max_uniqueMat);

  for (unsigned quarter = 0; quarter < det.nQuarters; quarter++) {
    const auto& modules = det.quarter(quarter)->modules();
    number_of_modules[quarter] = modules.size();

    for (const auto& module : modules) {
      const auto& mats = module->mats();
      number_of_mats += mats.size();
      number_of_mats_per_module = mats.size();
      for (const auto& mat : mats) {
        auto index = mat->elementID().uniqueMat() - uniqueMatOffset;
        const auto& mirrorPoint = mat->mirrorPoint();
        const auto& ddx = mat->ddx();
        mirrorPointX[index] = mirrorPoint.x();
        mirrorPointY[index] = mirrorPoint.y();
        mirrorPointZ[index] = mirrorPoint.z();
        ddxX[index] = ddx.x();
        ddxY[index] = ddx.y();
        ddxZ[index] = ddx.z();
        uBegin[index] = mat->uBegin();
        halfChannelPitch[index] = mat->halfChannelPitch();
        dieGap[index] = mat->dieGap();
        sipmPitch[index] = mat->sipmPitch();
        dxdy[index] = mat->dxdy();
        dzdy[index] = mat->dzdy();
        globaldy[index] = mat->globaldy();
      }
    }
  }

  // Raw bank layout (from FTReadoutTool)
  vector<uint32_t> bank_first_channel;
  string conditionLocation = "/dd/Conditions/ReadoutConf/FT/ReadoutMap";
  Condition* rInfo = getDet<Condition>(conditionLocation);

  std::vector<int> stations_ = rInfo->param<std::vector<int>>("FTBankStation");
  std::vector<int> layers = rInfo->param<std::vector<int>>("FTBankLayer");
  std::vector<int> quarters = rInfo->param<std::vector<int>>("FTBankQuarter");
  std::vector<int> firstModules = rInfo->param<std::vector<int>>("FTBankFirstModule");
  std::vector<int> firstMats = rInfo->param<std::vector<int>>("FTBankFirstMat");

  // Construct the first channel attribute
  uint32_t number_of_tell40s = stations_.size();
  bank_first_channel.reserve(number_of_tell40s);
  for (unsigned int i = 0; i < number_of_tell40s; i++) {
    bank_first_channel.push_back(static_cast<uint32_t>(
      LHCb::FTChannelID(stations_[i], layers[i], quarters[i], firstModules[i], firstMats[i], 0u, 0u)));
  }

  DumpUtils::Writer output {};
  output.write(
    number_of_stations,
    number_of_layers_per_station,
    number_of_layers,
    number_of_quarters_per_layer,
    number_of_quarters,
    number_of_modules,
    number_of_mats_per_module,
    number_of_mats,
    number_of_tell40s,
    bank_first_channel,
    max_uniqueMat,
    mirrorPointX,
    mirrorPointY,
    mirrorPointZ,
    ddxX,
    ddxY,
    ddxZ,
    uBegin,
    halfChannelPitch,
    dieGap,
    sipmPitch,
    dxdy,
    dzdy,
    globaldy);

  return {{tuple {output.buffer(), "ft_geometry", Allen::NonEventData::SciFiGeometry::id}}};
}
