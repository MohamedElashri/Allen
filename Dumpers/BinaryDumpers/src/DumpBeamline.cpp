/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <tuple>
#include <vector>

#include "GaudiKernel/StdArrayAsProperty.h"

#include <DetDesc/GenericConditionAccessorHolder.h>
#include <LHCbDet/InteractionRegion.h>

#include <Dumpers/Identifiers.h>
#include <Dumpers/Utils.h>
#include <DD4hep/GrammarUnparsed.h>

#include "Dumper.h"

namespace {
  struct Beamline {

    Beamline() {}

    Beamline(std::vector<char>& data, LHCb::Conditions::InteractionRegion const& region, std::array<float, 2> offset)
    {
      DumpUtils::Writer output;

      std::vector<double> pos(3);
      region.avgPosition.GetCoordinates(pos.begin(), pos.end());
      pos[0] = pos[0] + offset[0];
      pos[1] = pos[1] + offset[1];

      std::vector<double> sprd(region.spread.begin(), region.spread.end());

      auto as_float = [](auto const& vd) {
        std::vector<float> vf(vd.size());
        std::transform(vd.begin(), vd.end(), vf.begin(), [](double v) { return static_cast<float>(v); });
        return vf;
      };

      // version 1, position, spread
      output.write(1u, as_float(pos), as_float(sprd));
      data = output.buffer();
    }
  };

  using IR = LHCb::Conditions::InteractionRegion;

} // namespace

/** @class DumpBeamline
 *  Dump beamline position.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class DumpBeamline final
  : public Allen::Dumpers::Dumper<void(Beamline const&), LHCb::DetDesc::usesConditions<Beamline>> {
public:
  DumpBeamline(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const Beamline& beamline) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
  Gaudi::Property<std::array<float, 2>> m_offset {this, "Offset", {0.f, 0.f}, "Beamline offset"};
};

DECLARE_COMPONENT(DumpBeamline)

DumpBeamline::DumpBeamline(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"BeamlineLocation", location(name, "beamline")}})
{}

StatusCode DumpBeamline::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::Beamline::id, "beamline", m_data);

    auto ir_loc = location(name(), "interaction_region");

    // First register a derivation on the interaction region
    IR::addConditionDerivation(this, ir_loc);

    // Then derived the interaction region to create the device representation
    addConditionDerivation({ir_loc}, inputLocation<Beamline>(), [&](LHCb::Conditions::InteractionRegion const& ir) {
      auto beamline = Beamline {m_data, ir, m_offset};
      dump();
      return beamline;
    });
  });
}

void DumpBeamline::operator()(const Beamline&) const {}
