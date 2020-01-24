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

/**
 * Convert PV::Vertex into LHCb::Event::v2::RecVertex
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenDecReportsToTES.h"

DECLARE_COMPONENT( AllenDecReportsToTES )

AllenDecReportsToTES::AllenDecReportsToTES( const std::string& name, ISvcLocator* pSvcLocator )
: Transformer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenOutput", "Allen/Out/HostBuffers"}},
                    // Outputs
                    {KeyValue{"OutputDecReports", "Allen/DecReports"}} ) {}

StatusCode AllenDecReportsToTES::initialize() {
  auto sc = Transformer::initialize();

  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

std::vector<uint32_t> AllenDecReportsToTES::operator()(const HostBuffers& host_buffers) const {

  const uint i_event = 0;
  std::vector<uint32_t> dec_reports;
  dec_reports.reserve((2 + Hlt1::Hlt1Lines::End) * i_event);
  // First two words contain the TCK and taskID, then one word per HLT1 line
  for ( uint i = 0; i < (2 + Hlt1::End) * i_event; i++) {
    dec_reports.push_back(host_buffers.host_dec_reports[i]);
  }

  return dec_reports;
}


