/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#ifndef DUMPMAGNETICFIELD_H
#define DUMPMAGNETICFIELD_H 1

#include <tuple>
#include <vector>

// Gaudi
#include <GaudiAlg/Transformer.h>
#include <GaudiAlg/FunctionalUtilities.h>

// LHCb
#include <Magnet/DeMagnet.h>
#include <DetDesc/GenericConditionAccessorHolder.h>

// Include files
#include <Dumpers/Utils.h>
#include <Dumpers/Identifiers.h>

#include "Dumper.h"

/** @class DumpMagneticField
 *  Dump Magnetic Field Polarity.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-21
 *  This Class dumps Data for Magnetic Field polarity using DD4HEP and Gaudi Algorithm
 *  This Class uses a detector description
 *  This Class is basically an instation of a Gaudi algorithm with specific inputs and outputs:
 *  The role of this class is to get data from TES to Allen for the Magnetic Field
 */
namespace {

  inline const std::string MagFieldCond = LHCb::Det::Magnet::det_path;

  struct MagneticField {
    MagneticField() {};
    MagneticField(std::vector<char>& data, const DeMagnet& magField)
    {
      DumpUtils::Writer output {};
      float polarity = magField.isDown() ? -1.f : 1.f;
      output.write(polarity);
      data = output.buffer();
    }
  };
} // namespace

class DumpMagneticField final
  : public Allen::Dumpers::Dumper<void(MagneticField const&), LHCb::DetDesc::usesConditions<MagneticField>> {
public:
  DumpMagneticField(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const MagneticField& magneticField) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpMagneticField)

// Add the multitransformer call , which keyvalues for Magnetic Field ?

DumpMagneticField::DumpMagneticField(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"MagneticFieldLocation", location(name, "Polarity")}})
{}

StatusCode DumpMagneticField::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::MagneticField::id, "polarity", m_data);
    addConditionDerivation({MagFieldCond}, inputLocation<MagneticField>(), [&](DeMagnet const& magField) {
      auto Polarity = MagneticField {m_data, magField};
      dump();
      return Polarity;
    });
  });
}

void DumpMagneticField::operator()(const MagneticField&) const {}

#endif // DUMPMAGNETICFIELD_H
