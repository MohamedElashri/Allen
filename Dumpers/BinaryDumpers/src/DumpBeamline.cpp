/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include <yaml-cpp/yaml.h>
#include <DetDesc/GenericConditionAccessorHolder.h>

#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include <DD4hep/GrammarUnparsed.h>

#include "Dumper.h"

#include "AllenUpdater.h"

namespace {
  inline const std::string beamSpotCond = "/dd/Conditions/Online/Velo/MotionSystem";

  struct Beamline_t {
    double X = std::numeric_limits<double>::signaling_NaN();
    double Y = std::numeric_limits<double>::signaling_NaN();

    Beamline_t() {}

    Beamline_t(std::vector<char>& data, YAML::Node const& n) :
      X {(n["ResolPosRC"].as<double>() + n["ResolPosLA"].as<double>()) / 2}, Y {n["ResolPosY"].as<double>()}
    {
      DumpUtils::Writer output;
      output.write(X, Y);
      data = output.buffer();
    }
  };
} // namespace

/** @class DumpBeamline
 *  Dump beamline position.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpBeamline final
  : public Allen::Dumpers::Dumper<void(Beamline_t const&), LHCb::DetDesc::usesConditions<Beamline_t>> {
public:
  DumpBeamline(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const Beamline_t& beamline) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpBeamline)

DumpBeamline::DumpBeamline(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"BeamSpotLocation", "AlgorithmSpecific-" + name + "-beamspot"}})
{}

StatusCode DumpBeamline::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::Beamline::id, "beamline", m_data);
    addConditionDerivation({beamSpotCond}, inputLocation<Beamline_t>(), [&](YAML::Node const& n) {
      auto beamline = Beamline_t {m_data, n};
      dump();
      return beamline;
    });
  });
}

void DumpBeamline::operator()(const Beamline_t&) const {}
