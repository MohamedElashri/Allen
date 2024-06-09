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

class TestAllenRichPixels final : public Gaudi::Functional::Consumer<void(
                                    const std::vector<Allen::RichSmartID>&,
                                    const std::vector<Allen::RichSmartID>&,
                                    const Rich::Future::DAQ::DecodedData&)> {

public:
  /// Standard constructor
  TestAllenRichPixels(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(
    const std::vector<Allen::RichSmartID>&,
    const std::vector<Allen::RichSmartID>&,
    const Rich::Future::DAQ::DecodedData&) const override;
};

DECLARE_COMPONENT(TestAllenRichPixels)

TestAllenRichPixels::TestAllenRichPixels(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"rich1_smart_ids", ""},
     KeyValue {"rich2_smart_ids", ""},
     KeyValue {"RichDecodedData", Rich::Future::DAQ::DecodedDataLocation::Default}})
{}

void TestAllenRichPixels::operator()(
  const std::vector<Allen::RichSmartID>& allen_rich1_smart_ids,
  const std::vector<Allen::RichSmartID>& allen_rich2_smart_ids,
  const Rich::Future::DAQ::DecodedData& rec_rich_pixels) const
{
  auto allen_rich1_ids = allen_rich1_smart_ids;
  std::sort(allen_rich1_ids.begin(), allen_rich1_ids.end(), [](auto a, auto b) { return a.key() < b.key(); });
  auto allen_rich2_ids = allen_rich2_smart_ids;
  std::sort(allen_rich2_ids.begin(), allen_rich2_ids.end(), [](auto a, auto b) { return a.key() < b.key(); });

  std::vector<Allen::RichSmartID> rec_rich1_ids;
  std::vector<Allen::RichSmartID> rec_rich2_ids;
  auto r1i = Rich::Rich1, r2i = Rich::Rich2;
  for (auto& [rD, rec_ids] : std::array {std::tie(r1i, rec_rich1_ids), std::tie(r2i, rec_rich2_ids)}) {
    for (const auto& pD : rec_rich_pixels[rD]) {
      for (const auto& mD : pD) {
        for (const auto& pd : mD) {
          std::transform(pd.smartIDs().begin(), pd.smartIDs().end(), std::back_inserter(rec_ids), [](auto id) {
            return Allen::RichSmartID {id.key()};
          });
        }
      }
    }
    std::sort(rec_ids.begin(), rec_ids.end(), [](auto a, auto b) { return a.key() < b.key(); });
  }

  std::string r1 {"Rich1"}, r2 {"Rich2"};
  for (const auto& [rich, allen_ids, rec_ids] :
       std::array {std::tie(r1, allen_rich1_ids, rec_rich1_ids), std::tie(r2, allen_rich2_ids, rec_rich2_ids)}) {
    if (rec_ids.size() != allen_ids.size()) {
      error() << "Allen and Rec " << rich << " Smart ID containers are not the same size" << endmsg;
    }
    std::vector<Allen::RichSmartID> only_allen, only_rec;
    std::set_difference(
      allen_ids.begin(),
      allen_ids.end(),
      rec_ids.begin(),
      rec_ids.end(),
      std::back_inserter(only_allen),
      [](auto a, auto r) { return a.key() < r.key(); });
    for (auto allen_smart_id : only_allen) {
      error() << "ID " << allen_smart_id << " not present in Rec " << rich << " Smart ID container" << endmsg;
    }

    std::set_difference(
      rec_ids.begin(),
      rec_ids.end(),
      allen_ids.begin(),
      allen_ids.end(),
      std::back_inserter(only_rec),
      [](auto a, auto r) { return a.key() < r.key(); });
    for (auto rec_smart_id : only_rec) {
      error() << "ID " << rec_smart_id.key() << " not present in Allen " << rich << " Smart ID container" << endmsg;
    }
  }
}
