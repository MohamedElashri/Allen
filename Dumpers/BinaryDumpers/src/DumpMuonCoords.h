/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#ifndef DUMPMUONCOORDS_H
#define DUMPMUONCOORDS_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <vector>

// Include files
#include "Event/MuonCoord.h"
#include "Event/ODIN.h"
#include "GaudiAlg/Consumer.h"

/** @class DumpMuonCoords DumpMuonCoords.h
 *  Algorithm that dumps muon coord variables to binary files.
 *
 *  @author Dorothea vom Bruch
 *  @date   2018-09-06
 */
class DumpMuonCoords : public Gaudi::Functional::Consumer<void(const LHCb::ODIN&, const LHCb::MuonCoords&)> {
public:
  /// Standard constructor
  DumpMuonCoords(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  void operator()(const LHCb::ODIN& odin, const LHCb::MuonCoords&) const override;

private:
  Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "muon_coords"};
};
#endif // DUMPMUONCOORDS_H
