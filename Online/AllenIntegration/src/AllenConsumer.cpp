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
#include <vector>

#include <boost/filesystem.hpp>

#include <GaudiKernel/ParsersFactory.h>

#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <Event/VPLightCluster.h>

#include "AllenConsumer.h"


// Declaration of the Algorithm Factory
DECLARE_COMPONENT( AllenConsumer )

AllenConsumer::AllenConsumer( const std::string& name, ISvcLocator* pSvcLocator )
    : Consumer( name, pSvcLocator,
                {KeyValue{"RawEventLocation", LHCb::RawEventLocation::Default},
                 KeyValue{"ODINLocation", LHCb::ODINLocation::Default}} ) {}

StatusCode AllenConsumer::initialize() {
 
  return StatusCode::SUCCESS;
}

void AllenConsumer::operator()( const LHCb::RawEvent& rawEvent, const LHCb::ODIN& odin ) const {

  std::cout << "Working on a bank" << std::endl;
}
