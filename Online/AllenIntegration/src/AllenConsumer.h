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
#ifndef ALLENCONSUMER_H
#define ALLENCONSUMER_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

// Include files
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <GaudiAlg/Consumer.h>
#include <GaudiAlg/GaudiHistoAlg.h>

class AllenConsumer : public Gaudi::Functional::Consumer<void(const LHCb::RawEvent&, const LHCb::ODIN&)> {
public:
  /// Standard constructor
  AllenConsumer(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  void operator()(const LHCb::RawEvent& rawEvent, const LHCb::ODIN& odin) const override;

private:
};
#endif // ALLENCONSUMER_H
