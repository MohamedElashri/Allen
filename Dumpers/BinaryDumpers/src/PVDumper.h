/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
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
#include "Event/RawEvent.h"
#include "Event/RawBank.h"
#include "GaudiAlg/Transformer.h"

#include "Associators/Associators.h"

/** @class PVDumper PVDumper.h
 *  tool to dump the MC truth informaiton for PVs
 *  based on the PrTrackerDumper code
 *
 *  @author Florian Reiss
 *  @date   2018-12-17
 */
class PVDumper
  : public Gaudi::Functional::Transformer<LHCb::RawEvent(const LHCb::MCVertices& MCVertices, const LHCb::MCProperty&)> {
public:
  /// Standard constructor
  PVDumper(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  LHCb::RawEvent operator()(const LHCb::MCVertices& MCVertices, const LHCb::MCProperty&) const override;

private:
  int count_reconstructible_mc_particles(const LHCb::MCVertex&, const MCTrackInfo&) const;
  LHCb::RawBank::BankType m_bankType = LHCb::RawBank::OTError;
};
#endif // PVDUMPER_H
