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
#include <vector>

#include "DumpCrossingAngles.h"
#include <Dumpers/Utils.h>
#include "LHCbAlgs/Consumer.h"
namespace {
  struct CrossingAngles {

    CrossingAngles() {}

    CrossingAngles(std::vector<char>& data, const LHCb::BeamParameters& BP)
    {

      DumpUtils::Writer output;
      auto as_float = [](auto const& vd) {
        std::vector<float> vf(vd.size());
        std::transform(vd.begin(), vd.end(), vf.begin(), [](double v) { return static_cast<float>(v); });
        return vf;
      };
      std::vector<double> cross_angles(2);
      cross_angles[0] = BP.horizontalCrossingAngle();
      cross_angles[1] = BP.verticalCrossingAngle();

      // version 2, position, spread, effectie crossing angles
      output.write(as_float(cross_angles));
      data = output.buffer();
    }
  };
} // namespace

DECLARE_COMPONENT(DumpCrossingAngles)

DumpCrossingAngles::DumpCrossingAngles(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(name, pSvcLocator, {KeyValue {"GenBeamlineLocation", LHCb::BeamParametersLocation::Default}})
{}

StatusCode DumpCrossingAngles::initialize()
{
  auto sc = Consumer::initialize();

  m_updater = service<AllenUpdater>("AllenUpdater", true);
  if (!m_updater) {
    this->error() << "Failed to retrieve AllenUpdater" << endmsg;
  }
  m_updater->registerProducer(
    Allen::NonEventData::CrossingAngles::id, [this]() -> std::optional<std::vector<char>> { return {m_data}; });

  return sc;
  // register_producer(Allen::NonEventData::CrossingAngles::id, "crossing_angles", m_data);
}

void DumpCrossingAngles::operator()(const LHCb::BeamParameters& BP) const { CrossingAngles(m_data, BP); }