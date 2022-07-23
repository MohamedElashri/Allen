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

#ifndef DUMPFTGEOMETRY_H
#define DUMPFTGEOMETRY_H 1

#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

// LHCb
#include <Detector/FT/FTChannelID.h>
#include <Detector/FT/FTConstants.h>
#include <FTDet/DeFTDetector.h>
#include <FTDAQ/FTReadoutMap.h>
#include <LHCbAlgs/Transformer.h>
#include <DetDesc/GenericConditionAccessorHolder.h>

// Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>

namespace {
  using std::vector;
  using FTChannelID = LHCb::Detector::FTChannelID;
  namespace FT = LHCb::Detector::FT;
} // namespace

/** @class DumpFTGeometry
 *  Convert SciFi geometry for use on an accelerator
 *
 *  @author Nabil Garroum
 *  @date   2022-04-23
 *  This Class dumps geometry for SciFi using DD4HEP and Gaudi Algorithm
 *  This Class uses a condition derivation and a detector description
 *  This Class is basically an instation of a Gaudi algorithm with specific inputs and outputs:
 *  The role of this class is to get data from TES to Allen for the SciFi
 */
class DumpFTGeometry final
  : public LHCb::Algorithm::MultiTransformer<
      std::tuple<std::vector<char>, std::string>(const DeFT&, const FTReadoutMap<DumpFTGeometry>&),
      LHCb::DetDesc::usesBaseAndConditions<GaudiAlgorithm, FTReadoutMap<DumpFTGeometry>, DeFT>> {
public:
  DumpFTGeometry(const std::string& name, ISvcLocator* pSvcLocator);

  std::tuple<std::vector<char>, std::string> operator()(
    const DeFT& DeFT,
    const FTReadoutMap<DumpFTGeometry>& readoutMap) const override;

  StatusCode initialize() override;

  Gaudi::Property<std::string> m_id {this, "ID", Allen::NonEventData::SciFiGeometry::id};

private:
  Gaudi::Property<std::string> m_mapLocation {this, "ReadoutMapLocation", "/dd/Conditions/ReadoutConf/FT/ReadoutMap"};
};

DECLARE_COMPONENT(DumpFTGeometry)

DumpFTGeometry::DumpFTGeometry(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformer {
    name,
    pSvcLocator,
    {KeyValue {"FTLocation", DeFTDetectorLocation::Default},
     KeyValue {"ReadoutMapStorage", "AlgorithmSpecific-" + name + "-ReadoutMap"}},
    {KeyValue {"Converted", "Allen/NonEventData/DeFT"}, KeyValue {"OutputID", "Allen/NonEventData/DeFTID"}}}
{}

// MultiTrasnformer algorithm with 2 inputs and 2 outputs , cf Gaudi algorithmas taxonomy as reference.

StatusCode DumpFTGeometry::initialize()
{
  return MultiTransformer::initialize().andThen(
    [&] { FTReadoutMap<DumpFTGeometry>::addConditionDerivation(this, inputLocation<FTReadoutMap<DumpFTGeometry>>()); });
}

// operator() call

std::tuple<std::vector<char>, std::string> DumpFTGeometry::operator()(
  const DeFT& det,
  const FTReadoutMap<DumpFTGeometry>& readoutMap) const
{

  // Detector and mat geometry
  uint32_t const number_of_stations = FT::nStations;
  uint32_t const number_of_layers_per_station = FT::nLayers;
  uint32_t const number_of_layers = number_of_stations * number_of_layers_per_station;
  uint32_t const number_of_quarters_per_layer = FT::nQuarters;
  uint32_t const number_of_quarters = number_of_quarters_per_layer * number_of_layers;
  vector<uint32_t> number_of_modules(number_of_quarters);
  uint32_t number_of_mats = 0;

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
  const uint32_t uniqueMatOffset = 512; // FIXME -- hardcoded
  // PrStoreFTHit.h uses hardcoded 2<<11, which is too much.
  uint32_t max_uniqueMat = (1 << 11) - uniqueMatOffset; // FIXME -- hardcoded
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

  // FIXME: Stations starting at 0 is not to be done.
#ifdef USE_DD4HEP
  // FIXME
  std::array<unsigned, number_of_stations> stations = {0, 1, 2};
#else
  std::array<unsigned, number_of_stations> stations = {1, 2, 3};
#endif

  for (auto i_station : stations) {
    FTChannelID::StationID station_id {i_station};
    for (unsigned i_layer = 0; i_layer < number_of_layers_per_station; ++i_layer) {
      FTChannelID::LayerID layer_id {i_layer};
      auto const& layer = det.findLayer(FTChannelID {station_id,
                                                     layer_id,
                                                     FTChannelID::QuarterID {0u},
                                                     FTChannelID::ModuleID {0u},
                                                     FTChannelID::MatID {0u},
                                                     0u,
                                                     0u});
      for (unsigned i_quarter = 0; i_quarter < number_of_quarters_per_layer; ++i_quarter) {
        FTChannelID::QuarterID quarter_id {i_quarter};
        FTChannelID quarterChanID(
          station_id, layer_id, quarter_id, FTChannelID::ModuleID {0u}, FTChannelID::MatID {0u}, 0, 0);
        auto const& quarter = layer->findQuarter(quarterChanID);
        auto const n_modules = quarter->modules().size();
        number_of_modules[quarterChanID.globalQuarterIdx()] = n_modules;
        for (unsigned i_module = 0; i_module < n_modules; ++i_module) {
          FTChannelID::ModuleID module_id {i_module};
          auto const& mod = quarter->findModule(
            FTChannelID {station_id, layer_id, quarter_id, module_id, FTChannelID::MatID {0u}, 0u, 0u});
          number_of_mats += FT::nMats;
          for (unsigned i_mat = 0; i_mat < FT::nMats; ++i_mat) {
            FTChannelID::MatID mat_id {i_mat};
            const auto& mat = mod->findMat(FTChannelID {station_id, layer_id, quarter_id, module_id, mat_id, 0, 0});
            auto index = mat->elementID().globalMatID_shift();
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
    }
  }

  DumpUtils::Writer output {};

  // Data from Condition
  auto comp = readoutMap.compatibleVersions();
  auto number_of_banks = readoutMap.nBanks();
  if (comp.count(4)) {
    // Decoding v6
    vector<uint32_t> bank_first_channel;
    bank_first_channel.reserve(number_of_banks);
    for (unsigned int i = 0; i < number_of_banks; i++) {
      bank_first_channel.push_back(readoutMap.channelIDShift(i));
    }
    output.write(
      number_of_stations,
      number_of_layers_per_station,
      number_of_layers,
      number_of_quarters_per_layer,
      number_of_quarters,
      number_of_modules,
      FT::nMats,
      number_of_mats,
      number_of_banks,
      0,
      bank_first_channel,
      FT::nMatsMax,
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
    /*
    printf("FT geometry\n");
    printf("Number of stations: %u\n",number_of_stations);
    printf("Number of layers per station: %u\n",number_of_layers_per_station);
    printf("Number of layers: %u\n",number_of_layers);
    printf("Number of quarters per layer: %u\n",number_of_quarters_per_layer);
    printf("Number of quarters: %u\n",number_of_quarters);
    printf("Number of modules:\n");
    for (unsigned int i = 0 ; i < number_of_quarters ; i++)
      printf("%u ",number_of_modules[i]);
    printf("\n");
    printf("Number of mats per module: %u\n",FT::nMats);
    printf("Number of mats: %u\n",number_of_mats);
    printf("Number of banks: %u\n",number_of_tell40s);
    printf("Number of mats (max): %u\n",FT::nMatsMax);
    printf("Bank first channel:\n");
    for (unsigned int i = 0 ; i < number_of_tell40s ; i++){
      if(i%10 == 0 && i != 0)
  printf("\n");
      printf("%i ",bank_first_channel[i]);
    }
    printf("\n");
    */
  }
  else if (comp.count(7)) {
    constexpr uint32_t nLinksPerBank = 24; // FIXME: change to centralised number
    std::vector<uint32_t> source_ids;
    source_ids.reserve(number_of_banks);
    for (unsigned int i = 0; i < number_of_banks; i++)
      source_ids.push_back(readoutMap.sourceID(i).sourceID());
    std::vector<uint32_t> linkMap;
    linkMap.reserve(number_of_banks * nLinksPerBank);
    for (unsigned int i = 0; i < number_of_banks; i++)
      for (unsigned int j = 0; j < nLinksPerBank; j++)
        linkMap.push_back(readoutMap.getGlobalSiPMIDFromIndex(i, j));
    output.write(
      number_of_stations,
      number_of_layers_per_station,
      number_of_layers,
      number_of_quarters_per_layer,
      number_of_quarters,
      number_of_modules,
      FT::nMats,
      number_of_mats,
      number_of_banks,
      1,
      source_ids,
      linkMap,
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
  }
  else {
    std::stringstream s;
    Gaudi::Utils::toStream(comp, s);
    throw GaudiException {"Unsupported conditions compatible with " + s.str(), __FILE__, StatusCode::FAILURE};
  }
  // Final data output
  return std::tuple {output.buffer(), m_id};
}

#endif
