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
#ifndef DUMPVELOUTSTATE_H
#define DUMPVELOUTSTATE_H 1

#include <algorithm>
#include <string>
#include <vector>

#include <Event/Track_v2.h>
#include <GaudiAlg/Consumer.h>
#include <GaudiAlg/ITupleTool.h>

class DumpVeloUTState : public Gaudi::Functional::Consumer<void( const std::vector<LHCb::Event::v2::Track>& )> {
public:
  DumpVeloUTState( const std::string& name, ISvcLocator* pSvcLocator );
  StatusCode initialize() override;

  void operator()( const std::vector<LHCb::Event::v2::Track>& utTracks ) const override;

private:
  ToolHandle<ITupleTool> m_tupleTool{"TupleTool", this};
};

#endif // DUMPVELOUTSTATE_H
