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
#ifndef DumpCrossingAngles_H
#define DumpCrossingAngles_H 1

#include <algorithm>
#include <string>
#include <vector>

#include <Event/BeamParameters.h>
#include <GaudiAlg/Consumer.h>
#include <Dumpers/Identifiers.h>
#include "AllenUpdater.h"

class DumpCrossingAngles : public Gaudi::Functional::Consumer<void(const LHCb::BeamParameters&)> {
public:
  DumpCrossingAngles(const std::string& name, ISvcLocator* pSvcLocator);
  StatusCode initialize() override;

  void operator()(const LHCb::BeamParameters& BP) const override;

private:
  mutable std::vector<char> m_data;
  mutable SmartIF<AllenUpdater> m_updater;
  Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "geometry"};
  Gaudi::Property<bool> m_dumpToFile {this, "DumpToFile", false};
};

#endif // DumpCrossingAngles_H