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
#ifndef DUMPFORWARDTRACKS_H
#define DUMPFORWARDTRACKS_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <vector>

// Include files
#include "Event/ODIN.h"
#include "Event/Track_v2.h"
#include "GaudiAlg/Consumer.h"

/** @class DumpForwardTracks DumpForwardTracks.h
 *  Algorithm that dumps Forward track LHCbIDs to binary files
 *
 *  @author Dorothea vom Bruch
 *  @date   2019-03-22
 */
class DumpForwardTracks
    : public Gaudi::Functional::Consumer<void( const LHCb::ODIN&, const std::vector<LHCb::Event::v2::Track>& )> {
public:
  /// Standard constructor
  DumpForwardTracks( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  void operator()( const LHCb::ODIN& odin, const std::vector<LHCb::Event::v2::Track>& tracks ) const override;

private:
  Gaudi::Property<std::string> m_outputDirectory{this, "OutputDirectory", "forward_tracks"};
};
#endif // DUMPFORWARDTRACS_H
