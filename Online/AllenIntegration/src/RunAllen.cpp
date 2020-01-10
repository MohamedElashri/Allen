
/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "RunAllen.h"

DECLARE_COMPONENT( RunAllen )

RunAllen::RunAllen( const std::string& name, ISvcLocator* pSvcLocator )
: MultiTransformer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenRawInput", "Allen/Raw/Input"},
                     KeyValue{"ODINLocation", LHCb::ODINLocation::Default}},
                    // Outputs
                    {KeyValue{"VeloTracks", "Allen/Track/Velo"},
                     KeyValue{"UTTracks", "Allen/Track/UT"}} ) {}

StatusCode RunAllen::initialize() {
  auto sc = MultiTransformer::initialize();
  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  // initialize Allen
  
  
  
  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
std::tuple<LHCb::Tracks, LHCb::Tracks> RunAllen::operator()(const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const {

  LHCb::Tracks VeloTracks;
  LHCb::Tracks UTTracks;

  return std::make_tuple( std::move( VeloTracks ), std::move( UTTracks ) );
}
