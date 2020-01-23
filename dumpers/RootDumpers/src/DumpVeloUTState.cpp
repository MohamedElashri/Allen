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
#include <string>

#include <Event/State.h>
#include <Event/Track_v2.h>

#include "DumpVeloUTState.h"

namespace {
  using std::string;
}

DECLARE_COMPONENT( DumpVeloUTState )

DumpVeloUTState::DumpVeloUTState( const std::string& name, ISvcLocator* pSvcLocator )
    : Consumer( name, pSvcLocator, {KeyValue{"UpstreamTrackLocation", "Rec/Track/Upstream"}} ) {}

StatusCode DumpVeloUTState::initialize() {
  auto sc = Consumer::initialize();
  if ( !sc.isSuccess() ) return sc;
  if ( sc ) m_tupleTool.retrieve();
  return sc;
}

void DumpVeloUTState::operator()( const std::vector<LHCb::Event::v2::Track>& utTracks ) const {
  auto tup = m_tupleTool->nTuple( string{"veloUT_tracks"} );
  for ( const auto& track : utTracks ) {
    for ( auto loc : {LHCb::State::Location::AtTT, LHCb::State::Location::EndVelo} ) {
      if ( track.hasStateAt( loc ) ) {
        auto const* state = track.stateAt( loc );
        tup->column( "qop", state->qOverP() );
        tup->write();
        break;
      }
    }
  }
}
