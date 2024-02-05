/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"

// LHCb
#include "Event/PrHits.h"
#include "RichFutureUtils/RichDecodedData.h"

// Allen
#include "RichDecoding.cuh"
#include "RichPDMDBDecodeMapping.cuh"

class TestAllenRichPixels final
  : public Gaudi::Functional::Consumer<
      void(const std::vector<Allen::RichSmartID>&, const Rich::Future::DAQ::DecodedData&)> {

public:
  /// Standard constructor
  TestAllenRichPixels(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<Allen::RichSmartID>&, const Rich::Future::DAQ::DecodedData&) const override;
};

DECLARE_COMPONENT(TestAllenRichPixels)

TestAllenRichPixels::TestAllenRichPixels(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"rich_smart_ids", ""}, KeyValue {"RichDecodedData", Rich::Future::DAQ::DecodedDataLocation::Default}})
{}

void TestAllenRichPixels::operator()(
  const std::vector<Allen::RichSmartID>& allen_rich_smart_ids,
  const Rich::Future::DAQ::DecodedData& rec_rich_pixels) const
{
  std::vector<LHCb::RichSmartID> recIDs;
  for (const auto& rD : rec_rich_pixels) {
    for (const auto& pD : rD) {
      for (const auto& mD : pD) {
        for (const auto& pd : mD) {
          const auto& IDs = pd.smartIDs();
          recIDs.insert(recIDs.end(), IDs.begin(), IDs.end());
        }
      }
    }
  }

  if (recIDs.size() != allen_rich_smart_ids.size()) {
    error() << "Allen and Rec Rich Smart ID containers are not the same size" << endmsg;
  }

  for (const auto smart_id : recIDs) {
    const auto allen_smart_id = Allen::RichSmartID {smart_id.key()};
    if (
      smart_id.pixelDataAreValid() &&
      std::find(allen_rich_smart_ids.begin(), allen_rich_smart_ids.end(), allen_smart_id) ==
        allen_rich_smart_ids.end()) {
      error() << "ID " << allen_smart_id << " not present in Allen Rich Smart ID container" << endmsg;
    }
  }
}
