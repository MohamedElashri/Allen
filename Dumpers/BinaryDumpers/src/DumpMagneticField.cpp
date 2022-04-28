/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef DUMPMAGNETICFIELD_H
#define DUMPMAGNETICFIELD_H 1


#include <tuple>
#include <vector>

//#include "DumpMagneticField.h"


// Include files
#include "DumpGeometry.h"
#include <Dumpers/Utils.h>
#include <Dumpers/Identifiers.h>

// LHCb
#include <Kernel/ILHCbMagnetSvc.h>
#include "Magnet/DeMagnet.h"
#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include "DetDesc/IConditionDerivationMgr.h"

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiAlg/FunctionalUtilities.h"



/** @class DumpMagneticField
 *  Dump Magnetic Field Polarity.
 *
 *  @author Nabil Garroum
 *  @date   2022-04-21
 */


class DumpMagneticField final
  : public Gaudi::Functional::MultiTransformer<std::tuple<std::vector<char>, std::string>(
                                                const DeMagnet&),
                                            LHCb::DetDesc::usesConditions<DeMagnet>> {
public:

  DumpMagneticField( const std::string& name, ISvcLocator* svcLoc );

  std::tuple<std::vector<char>, std::string> operator()( const DeMagnet& magField ) const override;

  Gaudi::Property<std::string> m_id{this, "ID", Allen::NonEventData::MagneticField::id}; // Allen Namespace from Identifiers.h
};



DECLARE_COMPONENT(DumpMagneticField)

// Add the multitransformer call , which keyvalues for Magnetic Field ?

DumpMagneticField::DumpMagneticField( const std::string& name, ISvcLocator* svcLoc )
    : MultiTransformer( name, svcLoc,
                   {KeyValue{"Magnet", LHCb::Det::Magnet::det_path}},
                   {KeyValue{"Converted", "Allen/NonEventData/MagField"},
                    KeyValue{"OutputID", "Allen/NonEventData/MagFieldID"}}) {}

std::tuple<std::vector<char>, std::string> DumpMagneticField::operator()( const DeMagnet& magField ) const
{

  //auto& magnetSvc = detector();

  DumpUtils::Writer output {};
  float polarity = magField.isDown() ? -1.f : 1.f;
  output.write(polarity);

  //return {{std::tuple {output.buffer(), "polarity", Allen::NonEventData::MagneticField::id}}};

  return std::tuple {output.buffer(), m_id};
}

#endif // DUMPMAGNETICFIELD_H