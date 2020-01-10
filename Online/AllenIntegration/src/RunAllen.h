
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

// Gaudi includes
#include "GaudiAlg/Transformer.h"

// LHCb includes
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>

// Rec includes
#include "Event/Track.h"

// Allen includes
#include "Constants.cuh"
#include "InputTools.h"
#include "InputReader.h"
#include "RegisterConsumers.h"
#include <Dumpers/IUpdater.h>

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
 
  Gaudi::Property<std::string>       m_updaterName{this, "UpdaterName", "AllenUpdater"};
  Gaudi::Property<std::string>       m_configurationPath{this, "ConfigurationPath", "../Allen/input/detector_configuration/down/"};
  
};



#endif
