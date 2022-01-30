/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Include files

// local
#include "PVDumper.h"
#include "Associators/Associators.h"
#include <Dumpers/Utils.h> 
#include <boost/filesystem.hpp>

namespace {

  namespace fs = boost::filesystem;

  void collectProductss(
    const LHCb::MCVertex& mcpv,
    const LHCb::MCVertex& mcvtx,
    std::vector<const LHCb::MCParticle*>& allprods)
  {
    for (const auto& idau : mcvtx.products()) {
      double dv2 = (mcpv.position() - idau->originVertex()->position()).Mag2();
      if (dv2 > (100. * Gaudi::Units::mm) * (100. * Gaudi::Units::mm)) continue;
      allprods.emplace_back(idau);
      for (const auto& ivtx : idau->endVertices()) {
        collectProductss(mcpv, *ivtx, allprods);
      }
    }
  }
} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(PVDumper)

//=============================================================================
// Standard constructor, initializes variables
//=============================================================================

PVDumper::PVDumper(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Input
    {KeyValue {"MCVerticesLocation", LHCb::MCVertexLocation::Default},
     KeyValue {"MCPropertyLocation", LHCb::MCPropertyLocation::TrackInfo}},
    // Output
    KeyValue {"OutputRawEventLocation", "Allen/MCPVRawEvent"})
{}

StatusCode PVDumper::initialize() { return StatusCode::SUCCESS; }

LHCb::RawEvent PVDumper::operator()(const LHCb::MCVertices& MCVertices, const LHCb::MCProperty& MCProp) const
{

  DumpUtils::Writer writer;

  auto goodVertex = [](const auto* v) {
    return !v->mother() && v->type() == LHCb::MCVertex::MCVertexType::ppCollision;
  };

  int n_PVs = std::count_if(MCVertices.begin(), MCVertices.end(), goodVertex);
  writer.write(n_PVs);

  MCTrackInfo trInfo {MCProp};
  for (const auto& mcv : MCVertices) {
    if (!goodVertex(mcv)) continue;
    const auto& pv = mcv->position();
    writer.write(count_reconstructible_mc_particles(*mcv, trInfo), pv.X(), pv.Y(), pv.Z());
  }

  // Write PV MC information to raw event
  LHCb::RawEvent rawEvent;
  constexpr int bankSize = 64512;
  for (const auto [sourceID, data] : LHCb::range::enumerate(LHCb::range::chunk(writer.buffer(), bankSize))) {
    rawEvent.addBank(sourceID, m_bankType, 1, data);
  }

  return rawEvent;
}

// count number reconstructible tracks in the same way as PrimaryVertexChecker
int PVDumper::count_reconstructible_mc_particles(const LHCb::MCVertex& avtx, const MCTrackInfo& trInfo) const
{
  std::vector<const LHCb::MCParticle*> allproducts;
  collectProductss(avtx, avtx, allproducts);

  return std::count_if(allproducts.begin(), allproducts.end(), [&](const auto* pmcp) {
    if (pmcp->particleID().threeCharge() == 0 || !trInfo.hasVelo(pmcp)) return false;
    double dv2 = (avtx.position() - pmcp->originVertex()->position()).Mag2();
    return dv2 < 0.0000001 && pmcp->p() > 100. * Gaudi::Units::MeV;
  });
}
