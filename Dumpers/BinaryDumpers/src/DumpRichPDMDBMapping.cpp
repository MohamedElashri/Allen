/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
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
#include "RichFutureDAQ/RichPDMDBDecodeMapping.h"
#include "RichFutureDAQ/RichPackedFrameSizes.h"

// Dumper
#include "Dumper.h"
#include <Dumpers/Utils.h>

namespace {
  struct RichPDMDBMapping {
    RichPDMDBMapping() = default;
    RichPDMDBMapping(std::vector<char>& data, const Rich::Future::DAQ::PDMDBDecodeMapping& tel40Maps)
    {
      Rich::Future::DAQ::Allen::PDMDBDecodeMapping allenTel40Maps {tel40Maps};
      DumpUtils::Writer output {};
      output.write(allenTel40Maps);
      data = output.buffer();
    }
  };
} // namespace

/**
 * @brief Dump cable mapping for the RICH detector.
 */
class DumpRichPDMDBMapping final
  : public Allen::Dumpers::Dumper<void(RichPDMDBMapping const&), LHCb::DetDesc::usesConditions<RichPDMDBMapping>> {
public:
  DumpRichPDMDBMapping(const std::string& name, ISvcLocator* svcLoc);

  void operator()(const RichPDMDBMapping&) const override;

  StatusCode initialize() override;

private:
  std::vector<char> m_data;
};

DECLARE_COMPONENT(DumpRichPDMDBMapping)

DumpRichPDMDBMapping::DumpRichPDMDBMapping(const std::string& name, ISvcLocator* svcLoc) :
  Dumper(name, svcLoc, {KeyValue {"RichPDMDBMappingLocation", location(name, "pdmdbmapping")}})
{}

StatusCode DumpRichPDMDBMapping::initialize()
{
  return Dumper::initialize().andThen([&, this] {
    register_producer(Allen::NonEventData::RichPDMDBMapping::id, "rich_pdmdbmaps", m_data);
    Rich::Future::DAQ::PDMDBDecodeMapping::addConditionDerivation(
      this, Rich::Future::DAQ::PDMDBDecodeMapping::DefaultConditionKey);

    addConditionDerivation(
      {Rich::Future::DAQ::PDMDBDecodeMapping::DefaultConditionKey},
      inputLocation<RichPDMDBMapping>(),
      [&](const Rich::Future::DAQ::PDMDBDecodeMapping& det) {
        RichPDMDBMapping mapping {m_data, det};
        dump();
        return mapping;
      });
  });
}

void DumpRichPDMDBMapping::operator()(const RichPDMDBMapping&) const {}
