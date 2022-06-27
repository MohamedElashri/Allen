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

#include <DetDesc/GenericConditionAccessorHolder.h>

// Allen
#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include "MuonDefinitions.cuh"

#include "Detector/Muon/TileID.h"

namespace {
  using std::vector;
  inline const std::string CablingCond = "/dd/Conditions/ReadoutConf/Muon/Cabling/M2Upgrade/Cabling";
}


/** @class DumpMuonGeometry
 *  Convert Muon geometry for use on an accelerator
 *
 *  @author Saverio Mariani
 *  @date   2022-06-10
 */
class DumpMuonGeometry final
  : public LHCb::Algorithm::MultiTransformer<
      std::tuple<std::vector<char>, std::string>(const DeMuonDetector&),
      LHCb::DetDesc::usesBaseAndConditions<GaudiAlgorithm, DeMuonDetector>> {
public:
  DumpMuonGeometry(const std::string& name, ISvcLocator* pSvcLocator);

  std::tuple<std::vector<char>, std::string> operator()(
    const DeMuonDetector& DeMuon) const override;

  StatusCode initialize() override;

  Gaudi::Property<std::string> m_id {this, "ID", Allen::NonEventData::MuonGeometry::id};

};

DECLARE_COMPONENT(DumpMuonGeometry)

DumpMuonGeometry::DumpMuonGeometry(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformer {
    name,
    pSvcLocator,
    {KeyValue {"MuonLocation", DeMuonLocation::Default}},
    {KeyValue {"Converted", "Allen/NonEventData/DeMuon"}, KeyValue {"OutputID", "Allen/NonEventData/DeMuonID"}}}
{}

StatusCode DumpMuonGeometry::initialize()
{
  return MultiTransformer::initialize();
}

std::tuple<std::vector<char>, std::string> DumpMuonGeometry::operator()(
									const DeMuonDetector& det
									//how can I enforce versioning?
									// const MuonUpgradeStationCabling& M2Cabling, what happens if it's not here? 
									// const MuonUpgradeStationCabling& M3Cabling,
									// const MuonUpgradeStationCabling& M4Cabling,
									// const MuonUpgradeStationCabling& M5Cabling
									) const
{  
  DumpUtils::Writer output {};
  const int nStations = det.stations();
  assert(nStations == 4);
  unsigned int version;

  auto cabling = getDetIfExists<MuonUpgradeStationCabling>(CablingCond);
  //if (cabling) { //discriminating between Run2 and Upgrade encoding
  if (true) { //discriminating between Run2 and Upgrade encoding
    std::cout << "MuonGeometry: Thanks for your work trying to provide me a decoding :), It's sad not to be understood :(" << std::endl;

    version = 3;
    output.write(version);


    //DAQ Helper
    auto daqHelper = det.getUpgradeDAQInfo();    

    //containers initialization
    std::array<unsigned int, Muon::Constants::maxTell40Number> whichStationIsTell40;
    std::array< std::array<unsigned int, Muon::Constants::maxTell40PCINumber>, Muon::Constants::maxTell40Number> tell40PCINumberOfActiveLink;
    std::array< std::array< std::array<unsigned int, Muon::Constants::maxNumberLinks> , Muon::Constants::maxTell40PCINumber>, Muon::Constants::maxTell40Number> mapRegionOfLink;
    std::array< std::array< std::array<unsigned int, Muon::Constants::maxNumberLinks> , Muon::Constants::maxTell40PCINumber>, Muon::Constants::maxTell40Number> mapQuarterOfLink;
    std::array< std::array< std::array<unsigned int, Muon::Constants::maxNumberLinks * Muon::Constants::ODEFrameSize> , Muon::Constants::maxTell40PCINumber>, Muon::Constants::maxTell40Number> mapTileInTell40;
    
    /////////////starting loop on stations
    for ( int station = 0; station < nStations; station++ ) {
      std::string cablingBasePath = daqHelper->getBasePath( daqHelper->getStationName( station ));
      auto cabling = getDet<MuonUpgradeStationCabling>(cablingBasePath  + "Cabling");

      for ( int iTell = 0; iTell < cabling -> getNumberOfTell40Board(); iTell++ ) {
	std::string Tell40Path = cablingBasePath + cabling -> getTell40Name( iTell );
        auto tell40 = getDetIfExists<MuonTell40Board>(Tell40Path); 
	if (  tell40 -> Tell40Number() > Muon::Constants::maxTell40Number)    
	  throw GaudiException( fmt::format("Tell40 number {} greater than allowed {}", tell40->Tell40Number(), Muon::Constants::maxTell40Number ), __FILE__, StatusCode::FAILURE);
		
	whichStationIsTell40[tell40->Tell40Number() - 1] = (unsigned int)tell40->getStation() - 1;
	for ( int iPCI = 0; iPCI < tell40->numberOfPCI(); iPCI++){
 	  std::string  pcipath = cablingBasePath + tell40->getPCIName( iPCI );
	  auto pciboard = getDetIfExists<MuonTell40PCI>(pcipath);
	  unsigned int active_link_per_PCI = 0;
	  for ( unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++ ) { 
	    long node = pciboard->getODENumber( ilink );
	    if ( node > 0 ) {
	      active_link_per_PCI++;		
	      tell40PCINumberOfActiveLink[tell40->Tell40Number() - 1][iPCI] = active_link_per_PCI ;
	    } //valid NODE
	  } //loop on Links
      } //loop on PCI per Tell40
    } //loop on Tell40 per station
  } //loop on stations

  ///second loop on links needed to fill mapRegionOfLink and mapStationOfLink
  for ( unsigned int itell = 0; itell < Muon::Constants::maxTell40Number; itell++){
    for ( unsigned int ipci = 0; ipci < Muon::Constants::maxTell40PCINumber; ipci++){
      for ( unsigned int ilink = 0; ilink < Muon::Constants::maxNumberLinks; ilink++){
 	unsigned int node = daqHelper -> getODENumberNoHole(itell, ipci, ilink);
	unsigned int frame = daqHelper -> getODEFrameNumberNoHole(itell, ipci, ilink);
	//std::cout << "Ode " << node << ", frame " << frame <<std::endl;
	if (node > 0) {
 	  for ( unsigned int ich = 0; ich < Muon::Constants::ODEFrameSize; ich++ ) {
	    auto tileID = daqHelper -> getTileIDInNODE(node - 1, frame * Muon::Constants::ODEFrameSize + ich);	    
	    //std::cout << "ich " << ich << ", tileID " << tileID <<std::endl;
	    if ( tileID.isValid() ) {
	      mapRegionOfLink[itell][ipci][ilink] = tileID.region();
	      mapQuarterOfLink[itell][ipci][ilink] = tileID.quarter();
	      //std::cout << "Filling indices  " << itell << ", ipci " << ipci <<", " << ilink << " --> region ";
	      //std::cout << mapRegionOfLink[itell][ipci][ilink] << ", quarter: "<< mapQuarterOfLink[itell][ipci][ilink] << std::endl;
	    } //valid tileID
            mapTileInTell40[itell][ipci][(ilink)*Muon::Constants::ODEFrameSize + ich] = int(tileID);
	  }//loop on channels 
	} //valid node
      }//loop on links
    }//loop on pci boards
  }//loop on tell40s
  

  output.write( whichStationIsTell40, tell40PCINumberOfActiveLink, 
		mapRegionOfLink, mapQuarterOfLink, mapTileInTell40 );

   // std::cout << "DUMPING DIRECTLY THE MAPS FROM THE MUONDUMPER" << std::endl;
   //  for (auto i = 0; i < 2; i++){
   //    std::cout << "Tell40 number " << i << std::endl;
   //    std::cout << "    which_station_is_tell_40 " << whichStationIsTell40[i] << std::endl;
   //    for (auto j = 0; j < Muon::Constants::maxTell40PCINumber; j++){
   //      std::cout << "        pci number " << j << std::endl;
   //      std::cout << "        numberOfActiveLink " << tell40PCINumberOfActiveLink[i][j] << std::endl; 
   //      for (auto k = 0; k < Muon::Constants::maxNumberLinks; k++){
   //  	std::cout <<  "            link number " << k << std::endl;
   //  	std::cout  << "            QuarterOfLink " << mapQuarterOfLink[i][j][k] << ", RegionOfLink " << mapRegionOfLink[i][j][k] << std::endl; 
   // 	for (auto l = 0; l < Muon::Constants::ODEFrameSize; l++){
   // 	  std::cout << "              ODE number " << l << std::endl;
   // 	  std::cout << "              TileInTell40 map " << mapTileInTell40[i][j][k * Muon::Constants::ODEFrameSize + l] << std::endl;	  
   // 	}
   //      }
   //    }    
   //  }
    

  } else {
    version = 2;
    output.write(version);
    
    //DAQ Helper
    auto daqHelper = det.getDAQInfo();    
    	 
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

  } //Run2 encoding

  return std::tuple {output.buffer(), m_id};
}
