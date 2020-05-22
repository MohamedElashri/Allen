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

DECLARE_COMPONENT(AllenDecReportsToTES)

AllenDecReportsToTES::AllenDecReportsToTES(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputDecReports", "Allen/Out/RawDecReports"}})
{}

StatusCode AllenDecReportsToTES::initialize()
{
  auto sc = Transformer::initialize();

  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

LHCb::RawEvent AllenDecReportsToTES::operator()(const HostBuffers& host_buffers) const
{

  std::vector<unsigned int> dec_reports;
  // First two words contain the TCK and taskID, then one word per HLT1 line
  dec_reports.reserve(2 + host_buffers.host_number_of_hlt1_lines);
  for (uint i = 0; i < 2 + host_buffers.host_number_of_hlt1_lines; i++) {
    dec_reports.push_back(host_buffers.host_dec_reports[i]);
  }
  LHCb::RawEvent raw_event;
  // SourceID_Hlt1 = 1, SourceID_BitShift = 13, VersionNumber = 2
  // defined in: https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/src/component/HltDecReportsWriter.h
  // to do: make header in LHCb available for inclusion from other projects
  raw_event.addBank(int(1 << 13), LHCb::RawBank::HltDecReports, 2u, dec_reports);

  return raw_event;
}
