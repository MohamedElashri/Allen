/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPFTHITS_H
#define DUMPFTHITS_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <vector>

// Include files
#include "Event/ODIN.h"
#include "GaudiAlg/Consumer.h"
#include "PrKernel/PrFTHitHandler.h"

/** @class DumpFTHits DumpFTHits.h
 *  Algorithm that dumps FT hit variables to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class DumpFTHits : public Gaudi::Functional::Consumer<void(const LHCb::ODIN&, const PrFTHitHandler<PrHit>&)> {
public:
  /// Standard constructor
  DumpFTHits(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  void operator()(const LHCb::ODIN& odin, const PrFTHitHandler<PrHit>& hitHandler) const override;

private:
  Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "scifi_hits"};
};
#endif // DUMPFTHITS_H
