/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include <GaudiAlg/Transformer.h>

#include <Dumpers/Identifiers.h>

#include "Dumpers/Utils.h"

namespace {
  inline const std::string beamSpotCond = "/dd/Conditions/Online/Velo/MotionSystem";

  struct Beamline_t {
    double X = std::numeric_limits<double>::signaling_NaN();
    double Y = std::numeric_limits<double>::signaling_NaN();
    Beamline_t(Condition const& c) :
      X {(c.param<double>("ResolPosRC") + c.param<double>("ResolPosLA")) / 2}, Y {c.param<double>("ResolPosY")}
    {}
  };
} // namespace

/** @class DumpBeamline
 *  Dump beamline position.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpBeamline final : public Gaudi::Functional::MultiTransformer<
                             std::tuple<std::vector<char>, std::string>(const Beamline_t&),
                             LHCb::DetDesc::usesConditions<Beamline_t>> {
public:
  DumpBeamline(const std::string& name, ISvcLocator* svcLoc);

  std::tuple<std::vector<char>, std::string> operator()(const Beamline_t& beamline) const override;

  StatusCode initialize() override;

  Gaudi::Property<std::string> m_id {this, "ID", Allen::NonEventData::Beamline::id};
};

DECLARE_COMPONENT(DumpBeamline)

DumpBeamline::DumpBeamline(const std::string& name, ISvcLocator* svcLoc) :
  MultiTransformer(
    name,
    svcLoc,
    {KeyValue {"BeamSpotLocation", "AlgorithmSpecific-" + name + "-beamspot"}},
    {KeyValue {"Converted", "Allen/NonEventData/Beamspot"}, KeyValue {"OutputID", "Allen/NonEventData/BeamspotID"}})
{}

StatusCode DumpBeamline::initialize()
{
  return MultiTransformer::initialize().andThen(
    [&] { addConditionDerivation<Beamline_t(Condition const&)>({beamSpotCond}, inputLocation<Beamline_t>()); });
}

std::tuple<std::vector<char>, std::string> DumpBeamline::operator()(const Beamline_t& beamline) const
{

  DumpUtils::Writer output {};

  output.write(beamline.X, beamline.Y);

  return std::tuple {output.buffer(), m_id};
}
