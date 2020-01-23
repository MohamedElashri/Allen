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
#ifndef PVDUMPER_H
#define PVDUMPER_H 1

#include <cstring>
#include <fstream>
#include <string>

// Include files
#include "Event/MCParticle.h"
#include "Event/MCTrackInfo.h"
#include "Event/MCVertex.h"
#include "Event/ODIN.h"
#include "GaudiAlg/Consumer.h"
#include "Linker/LinkerWithKey.h"

/** @class PVDumper PVDumper.h
 *  tool to dump the MC truth informaiton for PVs
 *  based on the PrTrackerDumper code
 *
 *  @author Florian Reiss
 *  @date   2018-12-17
 */
class PVDumper : public Gaudi::Functional::Consumer<void( const LHCb::MCVertices& MCVertices, const LHCb::MCProperty&,
                                                          const LHCb::ODIN& )> {
public:
  /// Standard constructor
  PVDumper( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  void operator()( const LHCb::MCVertices& MCVertices, const LHCb::MCProperty&, const LHCb::ODIN& odin ) const override;

private:
  int count_reconstructible_mc_particles( const LHCb::MCVertex&, const MCTrackInfo& ) const;

  Gaudi::Property<std::string> m_outputDirectory{this, "OutputDirectory", "MC_info/PVs"};
};
#endif // PVDUMPER_H
