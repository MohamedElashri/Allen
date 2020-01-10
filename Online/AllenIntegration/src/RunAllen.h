
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
#ifndef RUNALLEN_H
#define RUNALLEN_H

#include "GaudiAlg/Transformer.h"

#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>

#include "Event/Track.h"

#include "Constants.cuh"

class RunAllen final : public Gaudi::Functional::MultiTransformer<std::tuple<LHCb::Tracks, LHCb::Tracks>(const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin)> {
 public:
  /// Standard constructor
  RunAllen( const std::string& name, ISvcLocator* pSvcLocator );

  /// initialization
  StatusCode                               initialize() override;

  /// Algorithm execution
  std::tuple<LHCb::Tracks, LHCb::Tracks> operator()( const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const override;

 private:
  Constants m_constants;
 
  
  
};



#endif
