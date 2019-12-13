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

#include "RunAllen.h"

DECLARE_COMPONENT( RunAllen )

RunAllen::RunAllen( const std::string& name, ISvcLocator* pSvcLocator )
: Consumer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenRawVeloInput", "Allen/Raw/VeloInput"},
                     KeyValue{"AllenRawUTnput", "Allen/Raw/UTInput"},
                     KeyValue{"AllenRawFTClusternput", "Allen/Raw/FTClusterInput"},
                     KeyValue{"AllenRawMuonnput", "Allen/Raw/MuonInput"},
                     KeyValue{"AllenRawVeloOffsets", "Allen/Raw/VeloOffsets"},
                     KeyValue{"AllenRawUTOffsets", "Allen/Raw/UTOffsets"},
                     KeyValue{"AllenRawFTClusterOffsets", "Allen/Raw/FTClusterOffsets"},
                     KeyValue{"AllenRawMuonOffsets", "Allen/Raw/MuonOffsets"}}
                    // Outputs
                    // {KeyValue{"AllenVeloTracks", "Allen/VeloTracks"},
                    //     KeyValue{"AllenUTTracks", "Allen/UTTracks"}}
            ) {}

StatusCode RunAllen::initialize() {
  auto sc = Consumer::initialize();
  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
void RunAllen::operator()(
  const std::vector<uint32_t>& VeloRawInput,
  const std::vector<uint32_t>& UTRawInput,
  const std::vector<uint32_t>& SciFiRawInput,
  const std::vector<uint32_t>& MuonRawInput,
  const std::vector<uint32_t>& VeloRawOffsets,
  const std::vector<uint32_t>& UTRawOffsets,
  const std::vector<uint32_t>& SciFiRawOffsets,
  const std::vector<uint32_t>& MuonRawOffsets) const {

  // LHCb::Tracks VeloTracks;
  // LHCb::Tracks UTTracks;
  
  // return std::make_tuple( std::move( VeloTracks ), std::move( UTTracks ) );
}
