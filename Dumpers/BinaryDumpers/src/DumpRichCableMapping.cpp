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

// Gaudi Array properties ( must be first ...)
#include "GaudiKernel/ParsersFactory.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// Rich Kernel
#include "RichFutureKernel/RichAlgBase.h"

// Gaudi Functional
#include "LHCbAlgs/Transformer.h"

// Rich Utils
#include "RichFutureUtils/RichDecodedData.h"
#include "RichUtils/RichException.h"
#include "RichUtils/RichHashMap.h"
#include "RichUtils/RichMap.h"
#include "RichUtils/RichSmartIDSorter.h"

// RICH DAQ
#include "RichFutureDAQ/RichPackedFrameSizes.h"
#include "RichFutureDAQ/RichTel40CableMapping.h"

// Dumper
#include "Dumper.h"
#include <Dumpers/Utils.h>

namespace {
  struct RichCableMapping {
    RichCableMapping() = default;
    RichCableMapping(std::vector<char>& data, const Rich::Future::DAQ::Tel40CableMapping& tel40Maps)
    {
      Rich::Future::DAQ::Allen::Tel40CableMapping allenTel40Maps {tel40Maps};
      DumpUtils::Writer output {};
      output.write(allenTel40Maps);
      data = output.buffer();
    }
  };
} // namespace

/**
 * @brief Dump cable mapping for the RICH detector.
 */
class DumpRichCableMapping final
  : public Allen::Dumpers::Dumper<void(RichCableMapping const&), LHCb::DetDesc::usesConditions<RichCableMapping>> {
public:
  DumpRichCableMapping(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const RichCableMapping&) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpRichCableMapping)

DumpRichCableMapping::DumpRichCableMapping(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"RichCableMappingLocation", location(name, "cablemapping")}})
{}

StatusCode DumpRichCableMapping::initialize()
{
  return Dumper::initialize().andThen([&] {
    register_producer(Allen::NonEventData::RichCableMapping::id, "rich_tel40maps", m_data);

    Rich::Future::DAQ::Tel40CableMapping::addConditionDerivation(
      this, Rich::Future::DAQ::Tel40CableMapping::DefaultConditionKey);

    addConditionDerivation(
      {Rich::Future::DAQ::Tel40CableMapping::DefaultConditionKey},
      inputLocation<RichCableMapping>(),
      [&](const Rich::Future::DAQ::Tel40CableMapping& det) {
        auto cableMapping = RichCableMapping {m_data, det};
        dump();
        return cableMapping;
      });
  });
}

void DumpRichCableMapping::operator()(const RichCableMapping&) const {}
