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

#include "AllenTransformer.h"

DECLARE_COMPONENT( AllenTransformer )

AllenTransformer::AllenTransformer( const std::string& name, ISvcLocator* pSvcLocator )
: MultiTransformer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenRawInput", "Allen/Raw/Input"},
                     KeyValue{"ODINLocation", LHCb::ODINLocation::Default}},
                    // Outputs
                    {KeyValue{"VeloTracks", "Allen/Track/Velo"},
                     KeyValue{"UTTracks", "Allen/Track/UT"}} ) {}

StatusCode AllenTransformer::initialize() {
  auto sc = MultiTransformer::initialize();
  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

/** Iterates over all tracks in the current event and performs muon id on them.
 * Resulting PID objects as well as muon tracks are stored on the TES.
 */
std::tuple<LHCb::Tracks, LHCb::Tracks> AllenTransformer::operator()(const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const {

  LHCb::Tracks VeloTracks;
  LHCb::Tracks UTTracks;

  return std::make_tuple( std::move( VeloTracks ), std::move( UTTracks ) );
}
