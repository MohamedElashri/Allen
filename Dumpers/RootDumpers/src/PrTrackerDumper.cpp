/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "Associators/Associators.h"
#include "Event/MCParticle.h"
#include "Event/MCTrackInfo.h"
#include "Event/MCVertex.h"
#include "Event/ODIN.h"
#include "Event/RawBank.h"
#include "Event/RawEvent.h"
#include "Event/VPLightCluster.h"
#include "UTDAQ/UTInfo.h"
#include "PrKernel/PrFTHitHandler.h"
#include "PrKernel/PrHit.h"
#include "PrKernel/UTHit.h"
#include "PrKernel/UTHitHandler.h"

#include <TFile.h>
#include <TString.h>
#include <TTree.h>

#include <Dumpers/Utils.h>

#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/PhysicalConstants.h"
#include "GaudiKernel/Vector3DTypes.h"

#include <boost/filesystem.hpp>
#include <boost/interprocess/streams/vectorstream.hpp>

#include <cstring>
#include <fstream>
#include <string>

//-----------------------------------------------------------------------------
// Implementation file for class : PrTrackerDumper
//
// 2017-11-06 : Renato Quagliani
// Simple tool dumping all hits in the detector information to enable studies. Format is important depending on what you
// do offline: 1 entry = 1 MCParticle in the event. In the tree there is a particular MCParticle with p< 0, for which
// you get all the hits associated to corresponding to the hits not linked to any MCParticle.
//--- We dump hits associated to MCParticle without any protection against the fact the MCParticle is reconstructible in
// that detector, this can be checked filtering hits for isLong or isDown or hasSciFi etc..
//--- If you want to get for the current event all the hits in SciFi you will need to read all the entries and go
// through the vector of hits of the entry in SciFi when nSciFiHits >0 + go through all hits in the netry for p<0 to get
//--- the non associated hits
//---
// Branches produced regarding the MCParticle information:
/*
  fullInfo   : has full info MCParticle
  hasSciFi   : reconstructible in SciFi
  hasUT      : reconstructible in UT
  hasVelo    : reconstructible in Velo
  isDown     : reconstructible in UT and SciFi
  isDown_noVelo : reconstructible in UT and SciFi but not in Velo
  isLong        : reconstructible in Velo and SciFi
  isLong_andUT  : reconstructible in Velo and SciFi and UT
  p             : track momentum (cut for p>0 & at least having 1 hit in one of sub-detector) [among MCPartcile there
  are also the intermediate particles] pt            : track trsansverse momentum pid           : PID of the particle
  (can distinguish among muon/electrons/pion/kaons/protons etc...) eta           : track pseudorapidity ovtx_x        :
  track origin position X ovtx_y        : track origin position Y ovtx_z        : track origin position Z
  fromBeautyDecay : the track belongs to a decay chain with a b-quark hadron
  fromCharmDecay  : the track belongs to a decay chain with a c-quark hadron
  fromStrangeDecay : the track belongs to a decay chain with a s-quark hadron
  DecayOriginMother_pid : it store the PID of the head particle in the decay chain if found , you can filter based on
  the simulated sample. If for instance you run over Bs->PhiPhi, you can filter the 4 kaons among all tracks requiring
  Bs PID for this variable
*/
/*  VELO related part
  "nVeloHits" : Number of VeloHits associated to the MCParticle
  Velo_x       : vector of x position for Velo  hits (size = nVeloHits)
  Velo_y       : vector of y position for Velo  hits (size = nVeloHits)
  Velo_z       : vector of z position for Velo  hits (size = nVeloHits)
  Velo_Module  : vector of ModuleID Velo  hits (size = nVeloHits)
  Velo_Sensor  : vector of SensorID Velo  hits (size = nVeloHits)
  Velo_Station : vector of StationID Velo  hits (size = nVeloHits)
  Velo_lhcbID  : vector of lhcbID Velo  hits (size = nVeloHits)
*/
/*  SciFi related part
  nFTHits   : Number of FTHits associated to the MCParticle
  FT_x      : vector of x(y=0) position for SciFi
  FT_z      : vector of z(y=0) position for SciFi hits
  FT_w      : vector of weight error   for SciFi hits
  FT_dxdy   : vector of slopes dxdy for SciFi hits
  FT_YMin   : vector of yMin  for SciFi hits
  FT_YMax   : vector of yMax  for SciFi hits
  FT_hitPlaneCode : vector of planeCode  for SciFi hits
  FT_hitzone      : vector of hitzone (up/down)  for SciFi hits
  FT_lhcbID       : vector of lhcbID  for SciFi hits
*/
/* UT related part
   nUTHits   : Number of UTHits associated to the MCParticle
  //---- see private members of UT:Hit in PrKernel package
  UT_cos
  UT_cosT
  UT_dxDy
  UT_lhcbID
  UT_planeCode
  UT_sinT
  UT_size
  UT_tanT
  UT_weight
  UT_xAtYEq0
  UT_xAtYMid
  UT_xMax
  UT_xMin
  UT_xT
  UT_yBegin
  UT_yEnd
  UT_yMax
  UT_yMid
  UT_yMin
  UT_zAtYEq0
*/
//-----------------------------------------------------------------------------

namespace {
  using std::fstream;
  using std::ios;
  using std::make_pair;
  using std::make_unique;
  using std::map;
  using std::ofstream;
  using std::string;
  using std::to_string;
  using std::vector;

  namespace fs = boost::filesystem;
} // namespace

/** @class PrTrackerDumper PrTrackerDumper.h
 *  TupleTool storing all VPClusters position on tracks (dummy track for noise ones)
 *
 *  @author Renato Quagliani
 *  @date   2017-11-06
 */

class PrTrackerDumper : public Gaudi::Functional::Transformer<LHCb::RawEvent(
                          const LHCb::MCParticles&,
                          const std::vector<LHCb::VPLightCluster>&,
                          const PrFTHitHandler<PrHit>&,
                          const UT::HitHandler&,
                          const LHCb::ODIN&,
                          const LHCb::LinksByKey&)> {
public:
  /// Standard constructor
  PrTrackerDumper(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  void write_MCP_info(
    const int key,
    const int pid,
    const float p,
    const float pt,
    const float eta,
    const float phi,
    const float ovtx_x,
    const float ovtx_y,
    const float ovtx_z,
    const bool isLong,
    const bool isDown,
    const bool hasVelo,
    const bool hasUT,
    const bool hasSciFi,
    const bool fromBeautyDecay,
    const bool fromCharmDecay,
    const bool fromStrangeDecay,
    const int mother_key,
    const int mother_pid,
    const int DecayOriginMother_key,
    const int DecayOriginMother_pid,
    const float DecayOriginMother_pt,
    const float DecayOriginMother_tau,
    const float charge,
    const std::vector<unsigned int> Velo_lhcbID,
    const std::vector<unsigned int> UT_lhcbID,
    const std::vector<unsigned int> SciFi_lhcbID,
    const unsigned int nPrim,
    DumpUtils::Writer& outfile) const;

  LHCb::RawEvent operator()(
    const LHCb::MCParticles& MCParticles,
    const std::vector<LHCb::VPLightCluster>& VPClusters,
    const PrFTHitHandler<PrHit>& ftHits,
    const UT::HitHandler& utHits,
    const LHCb::ODIN& odin,
    const LHCb::LinksByKey& links) const override;

private:
  int mcVertexType(const LHCb::MCParticle& particle) const;
  const LHCb::MCVertex* findMCOriginVertex(const LHCb::MCParticle& particle, const double decaylengthtolerance = 1.e-3)
    const;

  Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "TrackerDumper"};
  Gaudi::Property<bool> m_writeROOT {this, "DumpToROOT", true};
  Gaudi::Property<LHCb::RawBank::BankType> m_bankType {this, "BankType", LHCb::RawBank::OTRaw};
};

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(PrTrackerDumper)

//=============================================================================
// Standard constructor, initializes variables
//=============================================================================

PrTrackerDumper::PrTrackerDumper(const string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    {KeyValue {"MCParticlesLocation", LHCb::MCParticleLocation::Default},
     KeyValue {"VPLightClusterLocation", LHCb::VPClusterLocation::Light},
     KeyValue {"FTHitsLocation", PrFTInfo::FTHitsLocation},
     KeyValue {"UTHitsLocation", UTInfo::HitLocation},
     KeyValue {"ODINLocation", LHCb::ODINLocation::Default},
     KeyValue {"LinkerLocation", Links::location("Pr/LHCbID")}},
    KeyValue {"OutputRawEventLocation", "Allen/MCRawEvent"})
{}

StatusCode PrTrackerDumper::initialize()
{
  auto dir = fs::path {m_outputDirectory.value()};
  if (!fs::exists(dir)) {
    boost::system::error_code ec;
    bool success = fs::create_directories(dir, ec);
    success &= !ec;
    if (!success) {
      error() << "Failed to create directory " << dir.string() << ": " << ec.message() << endmsg;
      return StatusCode::FAILURE;
    }
  }
  return StatusCode::SUCCESS;
}

void PrTrackerDumper::write_MCP_info(
  const int key,
  const int pid,
  const float p,
  const float pt,
  const float eta,
  const float phi,
  const float ovtx_x,
  const float ovtx_y,
  const float ovtx_z,
  const bool isLong,
  const bool isDown,
  const bool hasVelo,
  const bool hasUT,
  const bool hasSciFi,
  const bool fromBeautyDecay,
  const bool fromCharmDecay,
  const bool fromStrangeDecay,
  const int mother_key,
  const int mother_pid,
  const int DecayOriginMother_key,
  const int DecayOriginMother_pid,
  const float DecayOriginMother_pt,
  const float DecayOriginMother_tau,
  const float charge,
  const vector<unsigned int> Velo_lhcbID,
  const vector<unsigned int> UT_lhcbID,
  const vector<unsigned int> SciFi_lhcbID,
  const unsigned int nPrim,
  DumpUtils::Writer& out_buffer) const
{
  out_buffer.write(key);
  out_buffer.write(pid);
  out_buffer.write(p);
  out_buffer.write(pt);
  out_buffer.write(eta);
  out_buffer.write(phi);
  out_buffer.write(ovtx_x);
  out_buffer.write(ovtx_y);
  out_buffer.write(ovtx_z);
  out_buffer.write(isLong);
  out_buffer.write(isDown);
  out_buffer.write(hasVelo);
  out_buffer.write(hasUT);
  out_buffer.write(hasSciFi);
  out_buffer.write(fromBeautyDecay);
  out_buffer.write(fromCharmDecay);
  out_buffer.write(fromStrangeDecay);
  out_buffer.write(mother_key);
  out_buffer.write(mother_pid);
  out_buffer.write(DecayOriginMother_key);
  out_buffer.write(DecayOriginMother_pid);
  out_buffer.write(DecayOriginMother_pt);
  out_buffer.write(DecayOriginMother_tau);
  out_buffer.write(charge);
  out_buffer.write(nPrim);
  int n_IDs = Velo_lhcbID.size();
  out_buffer.write(n_IDs);
  for (unsigned int velo_id : Velo_lhcbID) {
    out_buffer.write(velo_id);
  }
  n_IDs = UT_lhcbID.size();
  out_buffer.write(n_IDs);
  for (unsigned int ut_id : UT_lhcbID) {
    out_buffer.write(ut_id);
  }
  n_IDs = SciFi_lhcbID.size();
  out_buffer.write(n_IDs);
  for (unsigned int scifi_id : SciFi_lhcbID) {
    out_buffer.write(scifi_id);
  }
}

int computeNbUTHits(const UT::HitHandler& prUTHitHandler)
{
  int nbHits = 0;
  for (int iStation = 1; iStation < 3; ++iStation) {
    for (int iLayer = 1; iLayer < 3; ++iLayer) {
      for (int iRegion = 1; iRegion < 4; ++iRegion) {
        for (int iSector = 1; iSector < 99; ++iSector) {
          nbHits += prUTHitHandler.hits(iStation, iLayer, iRegion, iSector).size();
        }
      }
    }
  }
  return nbHits;
}

double mcpTau(const LHCb::MCParticle* mcp)
{
  if (mcp->originVertex()) {
    Gaudi::XYZPoint mcp_ovtx = mcp->originVertex()->position();
    Gaudi::XYZPoint mcp_evtx = mcp->endVertices()[0]->position();
    Gaudi::XYZVector dir = mcp_evtx - mcp_ovtx;
    double tau = mcp->momentum().M() * dir.Dot(mcp->momentum().Vect()) / mcp->momentum().Vect().mag2();
    tau /= Gaudi::Units::c_light;
    tau /= Gaudi::Units::picosecond;
    return tau;
  }
  return 0;
}

LHCb::RawEvent PrTrackerDumper::operator()(
  const LHCb::MCParticles& MCParticles,
  const vector<LHCb::VPLightCluster>& VPClusters,
  const PrFTHitHandler<PrHit>& prFTHitHandler,
  const UT::HitHandler& prUTHitHandler,
  const LHCb::ODIN& odin,
  const LHCb::LinksByKey& links) const
{
  LHCb::RawEvent rawEvent;
  // boost::interprocess::basic_vectorstream<std::vector<char>> rawBuffer;
  DumpUtils::Writer rawBuffer {};

  // Look for associated MC  particle to the hit
  InputLinks<ContainedObject, LHCb::MCParticle> HitMCParticleLinks(links);
  string filename =
    (m_outputDirectory.value() + "/DumperFTUTHits_runNb_" + to_string(odin.runNumber()) + "_evtNb_" +
     to_string(odin.eventNumber()) + ".root");
  std::optional<TFile> file;
  if (m_writeROOT) { // save one ROOT file per event
    file.emplace(filename.c_str(), "RECREATE");
  }
  else { // write to temporary ROOT file, overwrite with next event
    file.emplace("tmp.root", "RECREATE");
  }
  TTree* tree = new TTree("Hits_detectors", "Hits_detectors");

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Loaded VPClusters , N hits " << VPClusters.size() << endmsg;
    debug() << "Loaded FTHits     , N hits " << prFTHitHandler.hits().size() << endmsg;
    debug() << "Loaded UTHits     , N hits " << prUTHitHandler.nbHits() << endmsg;
    debug() << "--- dealing with FT Hits ---" << endmsg;
  }
  // SciFi
  map<const LHCb::MCParticle*, std::vector<PrHit>> FTHits_on_MCParticles;
  vector<PrHit> non_Assoc_FTHits;
  for (unsigned int zone = 0; LHCb::Detector::FT::nbZones() > zone; ++zone) {
    for (const auto& hit : prFTHitHandler.hits(zone)) {
      // get the LHCbID from the PrHit
      LHCb::LHCbID lhcbid = hit.id();

      // Get the linking to the MCParticle given the LHCbID
      auto mcparticlesrelations = HitMCParticleLinks.from(lhcbid.lhcbID());
      if (mcparticlesrelations.empty()) {
        non_Assoc_FTHits.push_back(hit);
      }
      for (const auto& mcp : mcparticlesrelations) {
        // MCP is MCParticle*
        auto MCP = mcp.to();
        //---> weightassociation = mcp.weight();
        FTHits_on_MCParticles[MCP].push_back(hit);
      }
    }
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- dealing with UT Hits ---" << endmsg;
  }
  // UT detector. loop over all hits in detector, extract for each MCParticle the vector<Hit> , then
  // See Pr/PrKernel/UTHit definitions to know the info to store
  map<const LHCb::MCParticle*, vector<UT::Hit>> UTHits_on_MCParticles;
  vector<UT::Hit> non_Assoc_UTHits;
  for (int iStation = 1; iStation < 3; ++iStation) {
    for (int iLayer = 1; iLayer < 3; ++iLayer) {
      for (int iRegion = 1; iRegion < 4; ++iRegion) {
        for (int iSector = 1; iSector < 99; ++iSector) {
          for (auto& hit : prUTHitHandler.hits(iStation, iLayer, iRegion, iSector)) {
            LHCb::LHCbID lhcbid = hit.lhcbID();
            auto mcparticlesrelations = HitMCParticleLinks.from(lhcbid.lhcbID());
            if (mcparticlesrelations.empty()) {
              non_Assoc_UTHits.push_back(hit);
            }
            else {
              for (const auto& mcp : mcparticlesrelations) {
                auto MCP = mcp.to();
                //---> weightassociation = mcp.weight();
                UTHits_on_MCParticles[MCP].push_back(hit);
              }
            }
          }
        }
      }
    }
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- dealing with VeloPix hits ---" << endmsg;
  }
  // VP Detector
  map<const LHCb::MCParticle*, vector<LHCb::VPLightCluster>> VPHits_on_MCParticles;
  std::vector<LHCb::VPLightCluster> non_Assoc_VPHits;
  if (msgLevel(MSG::DEBUG)) {
    debug() << "Nb Velo Clusters in TES = " << VPClusters.size() << endmsg;
  }
  for (const auto& vpclus : VPClusters) {
    LHCb::LHCbID lhcbid = LHCb::LHCbID(vpclus.channelID());
    auto mcparticlesrelations = HitMCParticleLinks.from(lhcbid.lhcbID());
    if (mcparticlesrelations.empty()) {
      non_Assoc_VPHits.push_back(vpclus);
    }
    else {
      for (const auto& mcp : mcparticlesrelations) {
        auto MCP = mcp.to();
        VPHits_on_MCParticles[MCP].push_back(vpclus);
      }
    }
  }

  //---- We use trackInfo for a given MCParticle to know if the particle is reconstructible or not
  const auto trackInfo = MCTrackInfo {*get<LHCb::MCProperty>(LHCb::MCPropertyLocation::TrackInfo)};

  // Velo
  vector<float> Velo_x;
  vector<float> Velo_y;
  vector<float> Velo_z;
  vector<int> Velo_Module;
  vector<int> Velo_Sensor;
  vector<int> Velo_Station;
  vector<unsigned int> Velo_lhcbID;
  int nVeloHits;
  // branches for consistency checks offline when calculating nb hits in various detectors
  int nbHits_in_Velo;
  int nbHits_in_UT;
  int nbHits_in_SciFi;

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Creating branches in TTree ---" << endmsg;
  }

  tree->Branch("nbHits_in_Velo", &nbHits_in_Velo);
  tree->Branch("nbHits_in_UT", &nbHits_in_UT);
  tree->Branch("nbHits_in_SciFi", &nbHits_in_SciFi);
  nbHits_in_Velo = VPClusters.size();
  nbHits_in_UT = computeNbUTHits(prUTHitHandler);
  nbHits_in_SciFi = (int) prFTHitHandler.hits().size();

  tree->Branch("nVeloHits", &nVeloHits);
  tree->Branch("Velo_x", &Velo_x);
  tree->Branch("Velo_y", &Velo_y);
  tree->Branch("Velo_z", &Velo_z);
  tree->Branch("Velo_Module", &Velo_Module);
  tree->Branch("Velo_Sensor", &Velo_Sensor);
  tree->Branch("Velo_Station", &Velo_Station);
  tree->Branch("Velo_lhcbID", &Velo_lhcbID);

  // SciFi
  vector<float> FT_hitx;
  vector<float> FT_hitz;
  vector<float> FT_hitw;
  vector<float> FT_hitDXDY;
  vector<float> FT_hitDZDY;
  vector<float> FT_hitYMin;
  vector<float> FT_hitYMax;
  vector<int> FT_hitPlaneCode;
  vector<int> FT_hitzone;
  vector<unsigned int> FT_lhcbID;

  int nFTHits;
  tree->Branch("nFTHits", &nFTHits);
  tree->Branch("FT_x", &FT_hitx);
  tree->Branch("FT_z", &FT_hitz);
  tree->Branch("FT_w", &FT_hitw);
  tree->Branch("FT_dxdy", &FT_hitDXDY);
  tree->Branch("FT_dzdy", &FT_hitDZDY);
  tree->Branch("FT_YMin", &FT_hitYMin);
  tree->Branch("FT_YMax", &FT_hitYMax);
  tree->Branch("FT_hitPlaneCode", &FT_hitPlaneCode);
  tree->Branch("FT_hitzone", &FT_hitzone);
  tree->Branch("FT_lhcbID", &FT_lhcbID);

  // UT info
  vector<float> UT_cos;
  vector<float> UT_cosT;
  vector<float> UT_dxDy;
  vector<unsigned int> UT_lhcbID;
  vector<int> UT_planeCode;
  vector<float> UT_sinT;
  vector<int> UT_size;
  vector<float> UT_tanT;
  vector<float> UT_weight;
  vector<float> UT_xAtYEq0;
  vector<float> UT_xAtYMid;
  vector<float> UT_xMax;
  vector<float> UT_xMin;
  vector<float> UT_xT;
  vector<float> UT_yBegin;
  vector<float> UT_yEnd;
  vector<float> UT_yMax;
  vector<float> UT_yMid;
  vector<float> UT_yMin;
  vector<float> UT_zAtYEq0;

  int nUTHits;
  tree->Branch("nUTHits", &nUTHits);
  tree->Branch("UT_cos", &UT_cos);
  tree->Branch("UT_cosT", &UT_cosT);
  tree->Branch("UT_dxDy", &UT_dxDy);
  tree->Branch("UT_lhcbID", &UT_lhcbID);
  tree->Branch("UT_planeCode", &UT_planeCode);
  tree->Branch("UT_sinT", &UT_sinT);
  tree->Branch("UT_size", &UT_size);
  tree->Branch("UT_tanT", &UT_tanT);
  tree->Branch("UT_weight", &UT_weight);
  tree->Branch("UT_xAtYEq0", &UT_xAtYEq0);
  tree->Branch("UT_xAtYMid", &UT_xAtYMid);
  tree->Branch("UT_xMax", &UT_xMax);
  tree->Branch("UT_xMin", &UT_xMin);
  tree->Branch("UT_xT", &UT_xT);
  tree->Branch("UT_yBegin", &UT_yBegin);
  tree->Branch("UT_yEnd", &UT_yEnd);
  tree->Branch("UT_yMax", &UT_yMax);
  tree->Branch("UT_yMid", &UT_yMid);
  tree->Branch("UT_yMin", &UT_yMin);
  tree->Branch("UT_zAtYEq0", &UT_zAtYEq0);

  bool fullInfo;
  bool hasSciFi;
  bool hasUT;
  bool hasVelo;
  bool isDown;
  bool isDown_noVelo;
  bool isLong;
  bool isLong_andUT;
  double p;
  double pt;
  double eta;
  double phi;
  // vertex origin of the particle
  double ovtx_x;
  double ovtx_y;
  double ovtx_z;
  int pid;
  bool fromBeautyDecay;
  bool fromCharmDecay;
  bool fromStrangeDecay;
  int DecayOriginMother_pid;
  int key;
  int DecayOriginMother_key;
  float DecayOriginMother_pt;
  float DecayOriginMother_tau;
  float charge;

  tree->Branch("fullInfo", &fullInfo);
  tree->Branch("hasSciFi", &hasSciFi);
  tree->Branch("hasUT", &hasUT);
  tree->Branch("hasVelo", &hasVelo);
  tree->Branch("isDown", &isDown);
  tree->Branch("isDown_noVelo", &isDown_noVelo);
  tree->Branch("isLong", &isLong);
  tree->Branch("key", &key);
  tree->Branch("isLong_andUT", &isLong_andUT);
  tree->Branch("p", &p);
  tree->Branch("pt", &pt);
  tree->Branch("pid", &pid);
  tree->Branch("eta", &eta);
  tree->Branch("phi", &phi);
  tree->Branch("ovtx_x", &ovtx_x);
  tree->Branch("ovtx_y", &ovtx_y);
  tree->Branch("ovtx_z", &ovtx_z);
  tree->Branch("fromBeautyDecay", &fromBeautyDecay);
  tree->Branch("fromCharmDecay", &fromCharmDecay);
  tree->Branch("fromStrangeDecay", &fromStrangeDecay);
  tree->Branch("DecayOriginMother_pid", &DecayOriginMother_pid);
  tree->Branch("DecayOriginMother_key", &DecayOriginMother_key);
  tree->Branch("DecayOriginMother_pt", &DecayOriginMother_pt);
  tree->Branch("DecayOriginMother_tau", &DecayOriginMother_tau);
  tree->Branch("charge", &charge);

  // Count number of reconstructible primary vertices
  LHCb::MCVertices* mcVert = getIfExists<LHCb::MCVertices>(LHCb::MCVertexLocation::Default);
  if (mcVert == nullptr) {
    error() << "Could not find MCVertices at " << LHCb::MCParticleLocation::Default << endmsg;
  }
  unsigned int nPrim = 0;
  for (LHCb::MCVertices::iterator itV = mcVert->begin(); mcVert->end() != itV; ++itV) {
    if ((*itV)->isPrimary()) {
      int nbVisible = 0;
      for (const auto* mcparticle : MCParticles) {
        if (mcparticle->primaryVertex() == *itV) {
          if (trackInfo.hasVelo(mcparticle)) nbVisible++;
        }
      }
      if (nbVisible > 4) ++nPrim;
    }
  }

  // Count number of MC partcles with hits in trackers
  unsigned int nMCPsWithHits = 0;
  for (const auto* mcparticle : MCParticles) {
    nVeloHits = nFTHits = nUTHits = 0;
    if (VPHits_on_MCParticles.find(mcparticle) != VPHits_on_MCParticles.end())
      nVeloHits = (int) VPHits_on_MCParticles[mcparticle].size();
    if (FTHits_on_MCParticles.find(mcparticle) != FTHits_on_MCParticles.end())
      nFTHits = (int) FTHits_on_MCParticles[mcparticle].size();
    if (UTHits_on_MCParticles.find(mcparticle) != UTHits_on_MCParticles.end())
      nUTHits = (int) UTHits_on_MCParticles[mcparticle].size();
    if (nFTHits == 0 && nVeloHits == 0 && nUTHits == 0) continue;
    nMCPsWithHits++;
  }

  rawBuffer.write(nMCPsWithHits);

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Filling information of MCParticles ---" << endmsg;
  }

  for (const auto* mcparticle : MCParticles) {
    //---- We can speed up things if we filter only tracks which are either reconstructible in Velo or UT or SciFi,
    //---- Here is very inefficient, we go through ALL MCParticles in the chain, even the non-final states one
    /*
      if( ! ( trackInfo.hasVelo( mcparticle) || trackInfo.hasT( mcparticle) || trackInfo.hasSciFiT( mcparticle) ) ){
        continue;
      };
    */
    // Velo
    nVeloHits = 0;
    Velo_x.clear();
    Velo_y.clear();
    Velo_z.clear();
    Velo_Module.clear();
    Velo_Sensor.clear();
    Velo_Station.clear();
    Velo_lhcbID.clear();

    if (VPHits_on_MCParticles.find(mcparticle) != VPHits_on_MCParticles.end()) {
      nVeloHits = (int) VPHits_on_MCParticles[mcparticle].size();
      for (auto& vphit : VPHits_on_MCParticles[mcparticle]) {
        Velo_x.push_back(vphit.x());
        Velo_y.push_back(vphit.y());
        Velo_z.push_back(vphit.z());
        Velo_Module.push_back(to_unsigned(vphit.channelID().sensor()) / 4);
        Velo_Sensor.push_back(to_unsigned(vphit.channelID().sensor()));
        Velo_Station.push_back(vphit.channelID().station());
        Velo_lhcbID.push_back(LHCb::LHCbID(vphit.channelID()).lhcbID());
      }
    }

    nFTHits = 0;
    // SciFi
    FT_hitz.clear();
    FT_hitx.clear();
    FT_hitw.clear();
    FT_hitPlaneCode.clear();
    FT_hitzone.clear();
    FT_hitDXDY.clear();
    FT_hitDZDY.clear();
    FT_hitYMin.clear();
    FT_hitYMax.clear();
    FT_lhcbID.clear();

    if (FTHits_on_MCParticles.find(mcparticle) != FTHits_on_MCParticles.end()) {
      nFTHits = (int) FTHits_on_MCParticles[mcparticle].size();
      for (auto& fthit : FTHits_on_MCParticles[mcparticle]) {
        FT_hitz.push_back(fthit.z());
        FT_hitx.push_back(fthit.x());
        FT_hitw.push_back(fthit.w());
        FT_hitPlaneCode.push_back(fthit.planeCode());
        FT_hitzone.push_back(fthit.zone());
        FT_hitDXDY.push_back(fthit.dxDy());
        FT_hitDZDY.push_back(fthit.dzDy());
        FT_hitYMin.push_back(fthit.yMin());
        FT_hitYMax.push_back(fthit.yMax());
        FT_lhcbID.push_back(fthit.id().lhcbID());
      }
    }

    nUTHits = 0;
    UT_cos.clear();
    UT_cosT.clear();
    UT_dxDy.clear();
    UT_lhcbID.clear();
    UT_planeCode.clear();
    UT_sinT.clear();
    UT_size.clear();
    UT_tanT.clear();
    UT_weight.clear();
    UT_xAtYEq0.clear();
    UT_xAtYMid.clear();
    UT_xMax.clear();
    UT_xMin.clear();
    UT_xT.clear();
    UT_yBegin.clear();
    UT_yEnd.clear();
    UT_yMax.clear();
    UT_yMid.clear();
    UT_yMin.clear();
    UT_zAtYEq0.clear();
    if (UTHits_on_MCParticles.find(mcparticle) != UTHits_on_MCParticles.end()) {
      nUTHits = (int) UTHits_on_MCParticles[mcparticle].size();
      for (const auto& uthit : UTHits_on_MCParticles[mcparticle]) {
        UT_cos.push_back(uthit.cos());
        UT_cosT.push_back(uthit.cosT());
        UT_dxDy.push_back(uthit.dxDy());
        UT_lhcbID.push_back(uthit.lhcbID().lhcbID());
        UT_planeCode.push_back(uthit.planeCode());
        UT_sinT.push_back(uthit.sinT());
        UT_size.push_back(uthit.size());
        UT_tanT.push_back(uthit.tanT());
        UT_weight.push_back(uthit.weight());
        UT_xAtYEq0.push_back(uthit.xAtYEq0());
        UT_xAtYMid.push_back(uthit.xAtYMid());
        UT_xMax.push_back(uthit.xMax());
        UT_xMin.push_back(uthit.xMin());
        UT_xT.push_back(uthit.xT());
        UT_yBegin.push_back(uthit.yBegin());
        UT_yEnd.push_back(uthit.yEnd());
        UT_yMax.push_back(uthit.yMax());
        UT_yMid.push_back(uthit.yMid());
        UT_yMin.push_back(uthit.yMin());
        UT_zAtYEq0.push_back(uthit.zAtYEq0());
      }
    }

    // probably if fullInfo ==0 skip does the same , to check
    fullInfo = trackInfo.fullInfo(mcparticle);
    hasSciFi = trackInfo.hasT(mcparticle);
    hasUT = trackInfo.hasUT(mcparticle);
    hasVelo = trackInfo.hasVelo(mcparticle);
    isDown = hasSciFi && hasUT;
    isDown_noVelo = hasSciFi && hasUT && !hasVelo;
    isLong = hasSciFi && hasVelo;
    isLong_andUT = hasSciFi && hasVelo && hasUT;
    p = mcparticle->p();
    pt = mcparticle->pt();
    eta = mcparticle->momentum().Eta();
    phi = mcparticle->momentum().phi();
    pid = mcparticle->particleID().pid(); // offline you want to match the PID eventually to the e+, e- or whatever
    fromBeautyDecay = false;
    fromCharmDecay = false;
    fromStrangeDecay = false;
    DecayOriginMother_pid = -999999;
    ovtx_x = std::numeric_limits<double>::min();
    ovtx_y = std::numeric_limits<double>::min();
    ovtx_z = std::numeric_limits<double>::min();
    key = mcparticle->key();
    DecayOriginMother_key = mcparticle->key();
    DecayOriginMother_pt = -1;
    DecayOriginMother_tau = -1;
    charge = mcparticle->particleID().threeCharge() / 3.f;

    // navigate decay back to mother origin
    if (nullptr != mcparticle->originVertex()) {
      // store the mcparticle origin vertex information , and navigate back to mother of the particle!

      ovtx_x = mcparticle->originVertex()->position().x();
      ovtx_y = mcparticle->originVertex()->position().y();
      ovtx_z = mcparticle->originVertex()->position().z();
      const LHCb::MCParticle* mother = mcparticle->originVertex()->mother();
      if (nullptr != mother) {
        if (nullptr != mother->originVertex()) {
          double rOrigin = mother->originVertex()->position().rho();
          if (fabs(rOrigin) < 5.) { // radial origin position of the mother within 5 mm from beam pipe
            int pid = abs(mother->particleID().pid());
            if (
              130 == pid ||  // K0L
              310 == pid ||  // K0S
              3122 == pid || // Lambda
              3222 == pid || // Sigma+
              3212 == pid || // Sigma0
              3112 == pid || // Sigma-
              3322 == pid || // Xsi0
              3312 == pid || // Xsi-
              3334 == pid    // Omega-
            ) {
              fromStrangeDecay = true;
            }
          }
        }
      }
      while (nullptr != mother) {
        // Bottom.
        if (mother->particleID().hasBottom() && (mother->particleID().isMeson() || mother->particleID().isBaryon())) {
          DecayOriginMother_pid = mother->particleID().pid();
          DecayOriginMother_key = mother->key();
          DecayOriginMother_pt = mother->momentum().Pt();
          fromBeautyDecay = true;
          DecayOriginMother_tau = mcpTau(mother);
        }
        // Charm.
        if (mother->particleID().hasCharm() && (mother->particleID().isMeson() || mother->particleID().isBaryon())) {
          DecayOriginMother_pid = mother->particleID().pid();
          DecayOriginMother_key = mother->key();
          DecayOriginMother_pt = mother->momentum().Pt();
          fromCharmDecay = true;
          DecayOriginMother_tau = mcpTau(mother);
        }
        // Higgs/EW.
        if (
          mother->particleID().pid() == 23 || std::abs(mother->particleID().pid()) == 24 ||
          mother->particleID().pid() == 25) {
          DecayOriginMother_pid = mother->particleID().pid();
          DecayOriginMother_key = mother->key();
          DecayOriginMother_pt = mother->momentum().Pt();
          DecayOriginMother_tau = 0.;
        }
        mother = mother->originVertex()->mother();
      }
    }

    // skip the MC particles without any hits in the tracking system
    if (nFTHits == 0 && nVeloHits == 0 && nUTHits == 0) continue;
    int mother_key = mcparticle->key();
    int mother_pid = mcparticle->particleID().pid();
    if (nullptr != mcparticle->originVertex() && nullptr != mcparticle->originVertex()->mother()) {
      mother_key = mcparticle->originVertex()->mother()->key();
      mother_pid = mcparticle->originVertex()->mother()->particleID().pid();
    }

    // boost::interprocess::basic_vectorstream<std::vector<char>> m_buffer;
    // std::ostream* raw = &rawBuffer;
    write_MCP_info(
      key,
      pid,
      p,
      pt,
      eta,
      phi,
      ovtx_x,
      ovtx_y,
      ovtx_z,
      isLong,
      isDown,
      hasVelo,
      hasUT,
      hasSciFi,
      fromBeautyDecay,
      fromCharmDecay,
      fromStrangeDecay,
      mother_key,
      mother_pid,
      DecayOriginMother_key,
      DecayOriginMother_pid,
      DecayOriginMother_pt,
      DecayOriginMother_tau,
      charge,
      Velo_lhcbID,
      UT_lhcbID,
      FT_lhcbID,
      nPrim,
      rawBuffer);
    tree->Fill();
  } // MCParticles

  // write rawBuffer to rawEvent
  constexpr int bankSize = 64512;
  for (const auto [sourceID, data] : LHCb::range::enumerate(LHCb::range::chunk(rawBuffer.buffer(), bankSize))) {
    rawEvent.addBank(sourceID, m_bankType, 1, data);
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Filling information of MCParticles DONE ---" << endmsg;
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Filling Extra entry in TTree [Fake MCParticle ( p<0)] for hits having no association to any "
               "MCParticle ---"
            << endmsg;
  }

  // We filled the tree with hits having a MCParticle linked to [ no filter done if the particle is reconstructible or
  // not in Velo/UT/SciFi]
  //---- Offline, to grab the hits on reconstructible tracks plot the ones having the flag hasUT or hasT or hasVelo or
  // combine the flags to your preference

  // Empty the vectors of info before fillong the remaining non-associated hits [offline you want to check uniqueness of
  // lhcbID info to have the actual hits to use for tracking, since 1 hit can be associated to more MCParticles]
  FT_hitz.clear();
  FT_hitx.clear();
  FT_hitw.clear();
  FT_hitPlaneCode.clear();
  FT_hitzone.clear();
  FT_hitDXDY.clear();
  FT_hitDZDY.clear();
  FT_hitYMin.clear();
  FT_hitYMax.clear();
  FT_lhcbID.clear();
  // store all remaining hits in a dummy tuple, non associated ones in FT for the event!
  nFTHits = non_Assoc_FTHits.size();

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Fake MCParticle , FTHits ----" << endmsg;
  }

  for (const auto& fthit : non_Assoc_FTHits) {
    FT_hitz.push_back(fthit.z());
    FT_hitx.push_back(fthit.x());
    FT_hitw.push_back(fthit.w());
    FT_hitPlaneCode.push_back(fthit.planeCode());
    FT_hitzone.push_back(fthit.zone());
    FT_hitDXDY.push_back(fthit.dxDy());
    FT_hitDZDY.push_back(fthit.dzDy());
    FT_hitYMin.push_back(fthit.yMin());
    FT_hitYMax.push_back(fthit.yMax());
    FT_lhcbID.push_back(fthit.id().lhcbID());
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Fake MCParticle , UTHits ----" << endmsg;
  }

  nUTHits = non_Assoc_UTHits.size();
  // Empty the vectors of info before fillong the remaining non-associated hits [offline you want to check uniqueness of
  // lhcbID info to have the actual hits to use for tracking, since 1 hit can be associated to more MCParticles]
  UT_cos.clear();
  UT_cosT.clear();
  UT_dxDy.clear();
  UT_lhcbID.clear();
  UT_planeCode.clear();
  UT_sinT.clear();
  UT_size.clear();
  UT_tanT.clear();
  UT_weight.clear();
  UT_xAtYEq0.clear();
  UT_xAtYMid.clear();
  UT_xMax.clear();
  UT_xMin.clear();
  UT_xT.clear();
  UT_yBegin.clear();
  UT_yEnd.clear();
  UT_yMax.clear();
  UT_yMid.clear();
  UT_yMin.clear();
  UT_zAtYEq0.clear();
  for (const auto& uthit : non_Assoc_UTHits) {
    UT_cos.push_back(uthit.cos());
    UT_cosT.push_back(uthit.cosT());
    UT_dxDy.push_back(uthit.dxDy());
    UT_lhcbID.push_back(uthit.lhcbID().lhcbID());
    UT_planeCode.push_back(uthit.planeCode());
    UT_sinT.push_back(uthit.sinT());
    UT_size.push_back(uthit.size());
    UT_tanT.push_back(uthit.tanT());
    UT_weight.push_back(uthit.weight());
    UT_xAtYEq0.push_back(uthit.xAtYEq0());
    UT_xAtYMid.push_back(uthit.xAtYMid());
    UT_xMax.push_back(uthit.xMax());
    UT_xMin.push_back(uthit.xMin());
    UT_xT.push_back(uthit.xT());
    UT_yBegin.push_back(uthit.yBegin());
    UT_yEnd.push_back(uthit.yEnd());
    UT_yMax.push_back(uthit.yMax());
    UT_yMid.push_back(uthit.yMid());
    UT_yMin.push_back(uthit.yMin());
    UT_zAtYEq0.push_back(uthit.zAtYEq0());
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "--- Fake MCParticle , Velo Hits ----" << endmsg;
  }

  // velo part
  Velo_x.clear();
  Velo_y.clear();
  Velo_z.clear();
  Velo_Module.clear();
  Velo_Sensor.clear();
  Velo_Station.clear();
  Velo_lhcbID.clear();
  nVeloHits = non_Assoc_VPHits.size();
  for (const auto& vphit : non_Assoc_VPHits) {
    Velo_x.push_back(vphit.x());
    Velo_y.push_back(vphit.y());
    Velo_z.push_back(vphit.z());
    Velo_Module.push_back(to_unsigned(vphit.channelID().sensor()) / 4);
    Velo_Sensor.push_back(to_unsigned(vphit.channelID().sensor()));
    Velo_Station.push_back(vphit.channelID().station());
    Velo_lhcbID.push_back(LHCb::LHCbID(vphit.channelID()).lhcbID());
  }

  fullInfo = false;
  hasSciFi = false;
  hasUT = false;
  hasVelo = false;
  isDown = false;
  isDown_noVelo = false;
  isLong = false;
  isLong_andUT = false;
  p = -9999999999999.;
  pt = -9999999999999.;
  eta = -9999999999999.;
  phi = -9999999999999.;
  pid = -999999;
  fromBeautyDecay = false;
  fromCharmDecay = false;
  fromStrangeDecay = false;
  DecayOriginMother_pid = -999999;
  DecayOriginMother_key = -999999;
  DecayOriginMother_pt = -999999;
  DecayOriginMother_tau = -999999;
  ovtx_x = -9999999999999.;
  ovtx_y = -9999999999999.;
  ovtx_z = -9999999999999.;
  key = -999999;
  tree->Fill();

  file->Write();
  file->Close();

  return rawEvent;
}

int PrTrackerDumper::mcVertexType(const LHCb::MCParticle& particle) const
{
  const LHCb::MCVertex& vertex = findMCOriginVertex(particle);
  return vertex.type();
}
const LHCb::MCVertex* PrTrackerDumper::findMCOriginVertex(
  const LHCb::MCParticle& particle,
  const double decaylengthtolerance) const
{

  const LHCb::MCVertex* ov = particle.originVertex();
  if (!ov) return ov;
  const LHCb::MCParticle* mother = ov->mother();
  if (mother && mother != &particle) {
    const LHCb::MCVertex* mov = mother->originVertex();
    if (!mov) return ov;
    const double d = (mov->position() - ov->position()).R();
    if (mov == ov || d < decaylengthtolerance) {
      ov = findMCOriginVertex(*mother, decaylengthtolerance);
    }
  }
  return ov;
}
