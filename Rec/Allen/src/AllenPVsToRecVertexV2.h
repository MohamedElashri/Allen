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
#ifndef ALLENPVSTORECVERTEXV2_H
#define ALLENPVSTORECVERTEXV2_H

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"
#include "Event/RecVertex_v2.h"
#include "DetDesc/Condition.h"
#include "DetDesc/ConditionAccessorHolder.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

namespace ConditionHolders {
  inline const std::string beamSpotCond = "/dd/Conditions/Online/Velo/MotionSystem";

  struct Beamline_t {
    double X = std::numeric_limits<double>::signaling_NaN();
    double Y = std::numeric_limits<double>::signaling_NaN();
    Beamline_t(Condition const& c) :
      X {(c.param<double>("ResolPosRC") + c.param<double>("ResolPosLA")) / 2}, Y {c.param<double>("ResolPosY")}
    {}
  };
} // namespace ConditionHolders

class AllenPVsToRecVertexV2 final
  : public Gaudi::Functional::Transformer<
      std::vector<LHCb::Event::v2::RecVertex>(const HostBuffers&, const ConditionHolders::Beamline_t&),
      LHCb::DetDesc::usesConditions<ConditionHolders::Beamline_t>> {
public:
  /// Standard constructor
  AllenPVsToRecVertexV2(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::vector<LHCb::Event::v2::RecVertex> operator()(const HostBuffers&, const ConditionHolders::Beamline_t&)
    const override;

private:
  Gaudi::Property<uint32_t> m_minNumTracksPerVertex {this, "MinNumTracksPerVertex", 4};
  Gaudi::Property<float> m_maxVertexRho {this,
                                         "BeamSpotRCut",
                                         0.3 * Gaudi::Units::mm,
                                         "Maximum distance of vertex to beam line"};
  mutable Gaudi::Accumulators::SummingCounter<unsigned int> m_nbPVsCounter {this, "Nb PVs"};
};

#endif
