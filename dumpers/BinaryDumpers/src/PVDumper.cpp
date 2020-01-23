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
// Include files

// local
#include "PVDumper.h"
#include "Associators/Associators.h"
#include "Utils.h"
#include <boost/filesystem.hpp>

namespace {

  namespace fs = boost::filesystem;

  void collectProductss( const LHCb::MCVertex& mcpv, const LHCb::MCVertex& mcvtx,
                         std::vector<const LHCb::MCParticle*>& allprods ) {
    for ( const auto& idau : mcvtx.products() ) {
      double dv2 = ( mcpv.position() - idau->originVertex()->position() ).Mag2();
      if ( dv2 > ( 100. * Gaudi::Units::mm ) * ( 100. * Gaudi::Units::mm ) ) continue;
      allprods.emplace_back( idau );
      for ( const auto& ivtx : idau->endVertices() ) { collectProductss( mcpv, *ivtx, allprods ); }
    }
  }
} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT( PVDumper )

//=============================================================================
// Standard constructor, initializes variables
//=============================================================================

PVDumper::PVDumper( const std::string& name, ISvcLocator* pSvcLocator )
    : Consumer( name, pSvcLocator,
                {KeyValue{"MCVerticesLocation", LHCb::MCVertexLocation::Default},
                 KeyValue{"MCPropertyLocation", LHCb::MCPropertyLocation::TrackInfo},
                 KeyValue{"ODINLocation", LHCb::ODINLocation::Default}} ) {}

StatusCode PVDumper::initialize() {
  auto dir = fs::path{m_outputDirectory.value()};
  if ( !fs::exists( dir ) ) {
    boost::system::error_code ec;
    bool                      success = fs::create_directories( dir, ec );
    success &= !ec;
    if ( !success ) {
      error() << "Failed to create directory " << dir.string() << ": " << ec.message() << endmsg;
      return StatusCode::FAILURE;
    }
  }
  return StatusCode::SUCCESS;
}

void PVDumper::operator()( const LHCb::MCVertices& MCVertices, const LHCb::MCProperty& MCProp,
                           const LHCb::ODIN& odin ) const {
  // Binary file to dump MC PVs info
  DumpUtils::FileWriter outfile_PV{m_outputDirectory.value() + "/" + std::to_string( odin.runNumber() ) + "_" +
                                   std::to_string( odin.eventNumber() ) + ".bin"};

  auto goodVertex = []( const auto* v ) {
    return !v->mother() && v->type() == LHCb::MCVertex::MCVertexType::ppCollision;
  };

  int n_PVs = std::count_if( MCVertices.begin(), MCVertices.end(), goodVertex );
  outfile_PV.write( n_PVs );

  MCTrackInfo trInfo{MCProp};
  for ( const auto& mcv : MCVertices ) {
    if ( !goodVertex( mcv ) ) continue;
    const auto& pv = mcv->position();
    outfile_PV.write( count_reconstructible_mc_particles( *mcv, trInfo ), pv.X(), pv.Y(), pv.Z() );
  }
}

// count number reconstructible tracks in the same way as PrimaryVertexChecker
int PVDumper::count_reconstructible_mc_particles( const LHCb::MCVertex& avtx, const MCTrackInfo& trInfo ) const {
  std::vector<const LHCb::MCParticle*> allproducts;
  collectProductss( avtx, avtx, allproducts );

  return std::count_if( allproducts.begin(), allproducts.end(), [&]( const auto* pmcp ) {
    if ( pmcp->particleID().threeCharge() == 0 || !trInfo.hasVelo( pmcp ) ) return false;
    double dv2 = ( avtx.position() - pmcp->originVertex()->position() ).Mag2();
    return dv2 < 0.0000001 && pmcp->p() > 100. * Gaudi::Units::MeV;
  } );
}
