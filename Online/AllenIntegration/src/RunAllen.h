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
#ifndef RUNALLEN_H
#define RUNALLEN_H

#include "GaudiAlg/Transformer.h"
#include "GaudiAlg/Consumer.h"

#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <GaudiAlg/Consumer.h>

#include "Event/Track.h"


class RunAllen final : public Gaudi::Functional::Consumer<void(
  const std::vector<uint32_t>& VeloRawInput,
  const std::vector<uint32_t>& UTRawInput,
  const std::vector<uint32_t>& SciFiRawInput,
  const std::vector<uint32_t>& MuonRawInput,
  const std::vector<uint32_t>& VeloRawOffsets,
  const std::vector<uint32_t>& UTRawOffsets,
  const std::vector<uint32_t>& SciFiRawOffsets,
  const std::vector<uint32_t>& MuonRawOffsets)> {
 public:
  /// Standard constructor
  RunAllen( const std::string& name, ISvcLocator* pSvcLocator );

  /// initialization
  StatusCode                               initialize() override;

  /// Algorithm execution
  void operator()(
    const std::vector<uint32_t>& VeloRawInput,
    const std::vector<uint32_t>& UTRawInput,
    const std::vector<uint32_t>& SciFiRawInput,
    const std::vector<uint32_t>& MuonRawInput,
    const std::vector<uint32_t>& VeloRawOffsets,
    const std::vector<uint32_t>& UTRawOffsets,
    const std::vector<uint32_t>& SciFiRawOffsets,
    const std::vector<uint32_t>& MuonRawOffsets) const override;

 private:
 
 
  
  
};



#endif
