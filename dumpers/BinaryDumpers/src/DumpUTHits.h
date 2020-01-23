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

#ifndef DUMPUTHITS_H
#define DUMPUTHITS_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <vector>

// Include files
#include "Event/ODIN.h"
#include "GaudiAlg/Consumer.h"
#include "PrKernel/UTHitHandler.h"
#include "PrKernel/UTHitInfo.h"

/** @class DumpUTHits DumpUTHits.h
 *  Algorithm that dumps UT hit variables to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class DumpUTHits : public Gaudi::Functional::Consumer<void( const LHCb::ODIN&, const UT::HitHandler& )> {
public:
  /// Standard constructor
  DumpUTHits( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  void operator()( const LHCb::ODIN& odin, const UT::HitHandler& hitHandler ) const override;

private:
  Gaudi::Property<std::string> m_outputDirectory{this, "OutputDirectory", "ut_hits"};
};
#endif // DUMPUTHITS_H
