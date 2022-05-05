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
#include "DumpGeometry.h"
#include <FTDet/DeFTDetector.h>
#include "FTDAQ/FTReadoutMap.h"
#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include "DetDesc/IConditionDerivationMgr.h"
#include <LHCbAlgs/Transformer.h>

// Gaudi
//#include "GaudiAlg/Transformer.h"
// Attention : in this class, we are using Algs from LHCb and not from Gaudi

//Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
//#include "DumpFTGeometry.h" , Old header, delted for this class

namespace {
  using std::ios;
  using std::ofstream;
  using std::string;
  using std::tuple;
  using std::vector;

  inline const std::string FTconditionLocation = "/dd/Conditions/ReadoutConf/FT/ReadoutMap";

} // namespace

/** @class DumpCaloGeometry
 *  Dump Calo Geometry.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-23
 *  This Class dumps geometry for SciFi using DD4HEP and Gaudi Algorithm
 *  This Class uses a condition derivation and a detector description
 *  This Class is basically an instation of a Gaudi algorithm with specific inputs and outputs:
 *  The role of this class is to get data from TES to Allen for the SciFi
 */

class DumpFTGeometry final
  : public LHCb::Algorithm::MultiTransformer<std::tuple<std::vector<char>, std::string>(
                                                const DeFT& , const FTReadoutMap<DumpFTGeometry>&),
                                            LHCb::DetDesc::usesBaseAndConditions<GaudiAlgorithm, FTReadoutMap<DumpFTGeometry>, DeFT>> {
public:

  DumpFTGeometry( const std::string& name, ISvcLocator* pSvcLocator );

  std::tuple<std::vector<char>, std::string> operator()( const DeFT& DeFT , const FTReadoutMap<DumpFTGeometry>& readoutMap) const override;

  StatusCode initialize() override;

  Gaudi::Property<std::string> m_id{this, "ID", Allen::NonEventData::SciFiGeometry::id};


private:

  Gaudi::Property<std::string> m_mapLocation{this, "ReadoutMapLocation", "/dd/Conditions/ReadoutConf/FT/ReadoutMap"};

};



DECLARE_COMPONENT(DumpFTGeometry)


DumpFTGeometry::DumpFTGeometry( const std::string& name, ISvcLocator* pSvcLocator )
    : MultiTransformer{
          name,
          pSvcLocator,
          {KeyValue{"FTLocation", DeFTDetectorLocation::Default},
           KeyValue{"ReadoutMapStorage", "AlgorithmSpecific-" + name + "-ReadoutMap"}},
          {KeyValue{"Converted", "Allen/NonEventData/DeFT"},
           KeyValue{"OutputID", "Allen/NonEventData/DeFTID"}}} {}

// MultiTrasnformer algorithm with 2 inputs and 2 outputs , cf Gaudi algorithmas taxonomy as reference.

StatusCode DumpFTGeometry::initialize()
{
  return MultiTransformer::initialize().andThen(
    [&] { FTReadoutMap<DumpFTGeometry>::addConditionDerivation( this, inputLocation<FTReadoutMap<DumpFTGeometry>>() ); } );
}



// operator() call

std::tuple<std::vector<char>, std::string> DumpFTGeometry::operator()( const DeFT& det , const FTReadoutMap<DumpFTGeometry>& readoutMap ) const 
{

// Detector and mat geometry
#ifdef USE_DD4HEP
  
  uint32_t number_of_stations = LHCb::Detector::FT::nStations;
  uint32_t number_of_layers_per_station = LHCb::Detector::FT::nLayers;
  uint32_t number_of_layers = number_of_stations * number_of_layers_per_station;
  uint32_t number_of_quarters_per_layer = LHCb::Detector::FT::nQuarters;
  uint32_t number_of_quarters = number_of_quarters_per_layer * number_of_layers;
  vector<uint32_t> number_of_modules(number_of_quarters);
#else
  const auto& stations = det.stations();
  const auto& layersFirstStation = stations[0]->layers();
  const auto& quartersFirstLayer = layersFirstStation[0]->quarters();
  uint32_t number_of_stations = stations.size();
  uint32_t number_of_layers_per_station = layersFirstStation.size();
  uint32_t number_of_layers = number_of_stations * number_of_layers_per_station;
  uint32_t number_of_quarters_per_layer = quartersFirstLayer.size();
  uint32_t number_of_quarters = number_of_quarters_per_layer * number_of_layers;
  vector<uint32_t> number_of_modules(det.nQuarters);
#endif
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

#ifndef USE_DD4HEP
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
#endif

  DumpUtils::Writer output {};

// Data from Condition
  auto comp = readoutMap.compatibleVersions();
  if (comp.count(4)) {
    auto number_of_tell40s = readoutMap.nBanks();
    // Decoding v6
    vector<uint32_t> bank_first_channel;
    bank_first_channel.reserve(number_of_tell40s);
    for (unsigned int i = 0; i < number_of_tell40s; i++) {
      bank_first_channel.push_back(readoutMap.channelIDShift(i));
    }
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
