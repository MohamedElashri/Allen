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

#ifndef DUMPMUONCOMMONHITS_H
#define DUMPMUONCOMMONHITS_H 1

#include <cstring>
#include <string>
#include <vector>

// Include files
#include "Event/ODIN.h"
#include "GaudiAlg/Consumer.h"
#include "MuonDAQ/CommonMuonHit.h"
#include "MuonDAQ/MuonHitContainer.h"
#include "MuonDet/DeMuonDetector.h"

/** @class DumpMuonCommonHits DumpMuonCommonHits.h
 *  Algorithm that dumps muon common hit variables to binary files.
 *
 *  @author Dorothea vom Bruch
 *  @date   2018-09-06
 */
class DumpMuonCommonHits : public Gaudi::Functional::Consumer<void( const LHCb::ODIN&, const MuonHitContainer& )> {
public:
  /// Standard constructor
  DumpMuonCommonHits( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  void operator()( const LHCb::ODIN& odin, const MuonHitContainer& hitHandler ) const override;

private:
  Gaudi::Property<std::string> m_outputDirectory{this, "OutputDirectory", "muon_common_hits"};
};
#endif // DUMPMUONCOMMONHITS_H
