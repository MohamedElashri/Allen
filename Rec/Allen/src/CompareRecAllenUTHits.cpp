/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"
#include <Gaudi/Accumulators/Histogram.h>

// LHCb
#include "Kernel/LHCbID.h"
#include "LHCbMath/SIMDWrapper.h"
#include "Event/PrHits.h"

// Allen
#include "UTEventModel.cuh"
#include "Logger.h"

using simd = SIMDWrapper::best::types;

class CompareRecAllenUTHits final
  : public Gaudi::Functional::Consumer<
      void(const std::vector<unsigned>&, const std::vector<char>&, const LHCb::Pr::UT::Hits&)> {

public:
  /// Standard constructor
  CompareRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<unsigned>&, const std::vector<char>&, const LHCb::Pr::UT::Hits&) const override;
};

DECLARE_COMPONENT(CompareRecAllenUTHits)

CompareRecAllenUTHits::CompareRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ut_hit_offsets", ""}, KeyValue {"ut_hits", ""}, KeyValue {"UTHitsLocation", UTInfo::HitLocation}})
{}

void CompareRecAllenUTHits::operator()(
  const std::vector<unsigned>& ut_hit_offsets,
  const std::vector<char>& ut_hits,
  const LHCb::Pr::UT::Hits& hit_handler) const
{

  // the goal is to compare LHCbIDs of individual hits, and their positions from data decoded with HLT1 and HLT2.
  std::vector<UT::Hit> ut_hits_allen, ut_hits_rec;

  // read in offsets and hits from the buffer
  const auto n_hits_total_allen = ut_hit_offsets[ut_hit_offsets.size() - 1];
  const auto n_hits_total_rec = hit_handler.nHits();
  // call the UT::Hits_t ctor in UTEventModel.cuh with offset=0
  UT::ConstHits ut_hit_container_allen {ut_hits.data(), n_hits_total_allen};
  const auto& ut_hit_container_rec = hit_handler.simd();

  debug() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;

  constexpr int width = 12; // for printing results

  // Allen: loop sector groups and fill hit container for re-ordering
  for (unsigned sector_group_index = 0; sector_group_index < ut_hit_offsets.size() - 1; sector_group_index++) {
    // loop hits in sector group
    debug() << "Got " << ut_hit_offsets[sector_group_index + 1] - ut_hit_offsets[sector_group_index]
            << " Allen UT hits sector group " << sector_group_index << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "yBegin"
            << std::setw(width) << "yEnd" << std::setw(width) << "zAtYEq0" << std::setw(width) << "xAtYEq0"
            << std::setw(width) << "weight" << std::setw(width) << "dxdy" << endmsg;
    for (unsigned hit_idx = ut_hit_offsets[sector_group_index]; hit_idx < ut_hit_offsets[sector_group_index + 1];
         hit_idx++) {
      const auto hit = ut_hit_container_allen.getHit(hit_idx);
      debug() << hit << endmsg;
      ut_hits_allen.emplace_back(hit);
    }
  } // end loop sector groups

  // Rec: loop SIMD UT Hits and fill hit container
  for (int i = 0; i < n_hits_total_rec; i += simd::size) {
    const auto mH = ut_hit_container_rec[i];
    std::array<int, simd::size> channelIDs;
    mH.get<LHCb::Pr::UT::UTHitsTag::channelID>().store(channelIDs.data());
    std::array<float, simd::size> yBegins, yEnds, zAtYEq0s, xAtYEq0s, weights, dxdys;
    mH.get<LHCb::Pr::UT::UTHitsTag::yBegin>().store(yBegins.data());
    mH.get<LHCb::Pr::UT::UTHitsTag::yEnd>().store(yEnds.data());
    mH.get<LHCb::Pr::UT::UTHitsTag::zAtYEq0>().store(zAtYEq0s.data());
    mH.get<LHCb::Pr::UT::UTHitsTag::xAtYEq0>().store(xAtYEq0s.data());
    mH.get<LHCb::Pr::UT::UTHitsTag::weight>().store(weights.data());
    mH.get<LHCb::Pr::UT::UTHitsTag::dxDy>().store(dxdys.data());
    for (std::size_t j = 0; j < simd::size; j++) {
      ut_hits_rec.emplace_back(
        yBegins[j],
        yEnds[j],
        zAtYEq0s[j],
        xAtYEq0s[j],
        weights[j],
        bit_cast<int, unsigned int>(LHCb::LHCbID(LHCb::Detector::UT::ChannelID(channelIDs[j])).lhcbID()),
        0);
    }
  }

  for (const auto& ut_hit_allen : ut_hits_allen) {
    // where is std::erase_if https://en.cppreference.com/w/cpp/container/vector/erase2 ?
    // compare by LHCbID and x position (we mostly care about x, and everything below 1 micon difference is not
    // important for us)
    auto tmp_iter = std::remove_if(ut_hits_rec.begin(), ut_hits_rec.end(), [&ut_hit_allen](auto& ut_hit_rec) {
      return /*LHCbID*/ ut_hit_rec == ut_hit_allen && abs(ut_hit_rec.xAtYEq0 - ut_hit_allen.xAtYEq0) < 1e-3;
    });
    const auto n_hits_found = std::distance(tmp_iter, ut_hits_rec.end());
    ut_hits_rec.erase(tmp_iter, ut_hits_rec.end());
    if (n_hits_found == 0) {
      error() << "Could not match this UT Hit decoded by Allen to a UT hit decoded by Rec" << endmsg;
      error() << ut_hit_allen << endmsg;
    }
    else if (n_hits_found > 1) {
      error() << "This UT Hit decoded by Allen has multiple UT hits decoded by Rec" << endmsg;
      error() << ut_hit_allen << endmsg;
    }
  }

  if (!ut_hits_rec.empty()) {
    // error() << "Printing UT hits decoded by Rec that could not be matched to a UT hit in Allen" << endmsg;
    for (const auto& ut_hit_rec : ut_hits_rec) {
      if (ut_hit_rec.LHCbID != 805306369) // skip bogus hits from SIMD padding
        error() << "Lonely Rec hit " << ut_hit_rec << endmsg;
    }
  }
}
