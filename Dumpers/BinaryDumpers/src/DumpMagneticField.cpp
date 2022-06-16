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

class DumpMagneticField final : public Gaudi::Functional::MultiTransformer<
                                  std::tuple<std::vector<char>, std::string>(const DeMagnet&),
                                  LHCb::DetDesc::usesConditions<DeMagnet>> {
public:
  DumpMagneticField(const std::string& name, ISvcLocator* svcLoc);

  std::tuple<std::vector<char>, std::string> operator()(const DeMagnet& magField) const override;

  Gaudi::Property<std::string> m_id {this,
                                     "ID",
                                     Allen::NonEventData::MagneticField::id}; // Allen Namespace from Identifiers.h
};

DECLARE_COMPONENT(DumpMagneticField)

// Add the multitransformer call , which keyvalues for Magnetic Field ?

DumpMagneticField::DumpMagneticField(const std::string& name, ISvcLocator* svcLoc) :
  MultiTransformer(
    name,
    svcLoc,
    {KeyValue {"Magnet", LHCb::Det::Magnet::det_path}},
    {KeyValue {"Converted", "Allen/NonEventData/MagField"}, KeyValue {"OutputID", "Allen/NonEventData/MagFieldID"}})
{}

std::tuple<std::vector<char>, std::string> DumpMagneticField::operator()(const DeMagnet& magField) const
{

  // auto& magnetSvc = detector();

  DumpUtils::Writer output {};
  float polarity = magField.isDown() ? -1.f : 1.f;
  output.write(polarity);

  // Final data output

  return std::tuple {output.buffer(), m_id};
}

#endif // DUMPMAGNETICFIELD_H
