/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
/**
 * Convert Allen and Rec UT hits into the same vector<UT::Hit> type
 *
 * author Da Yu Tou
 *
 */

// stdlib
#include <sstream>
#include <vector>

// Gaudi
#include <LHCbAlgs/Transformer.h>
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Kernel/LHCbID.h"
#include "LHCbMath/SIMDWrapper.h"
#include "Event/PrHits.h"

// Allen
#include "LHCbID.cuh"
#include "UTEventModel.cuh"
#include "Logger.h"
#include "Constants.cuh"

using simd = SIMDWrapper::best::types;

class GaudiAllenTransformAllenRecUTHits final
  : public Gaudi::Functional::MultiTransformer<
      std::tuple<std::vector<UT::Hit>, std::vector<UT::Hit>, std::vector<float>>(
        const std::vector<unsigned>&,
        const std::vector<char>&,
        LHCb::Pr::UT::Hits const& hit_handler,
        const Constants* const&)> {
public:
  // Standard constructor
  GaudiAllenTransformAllenRecUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  // Algorithm execution
  std::tuple<std::vector<UT::Hit>, std::vector<UT::Hit>, std::vector<float>> operator()(
    const std::vector<unsigned>&,
    const std::vector<char>&,
    LHCb::Pr::UT::Hits const&,
    const Constants* const&) const override;
};

DECLARE_COMPONENT(GaudiAllenTransformAllenRecUTHits)

GaudiAllenTransformAllenRecUTHits::GaudiAllenTransformAllenRecUTHits(
  const std::string& name,
  ISvcLocator* pSvcLocator) :
  MultiTransformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"ut_hit_offsets", ""},
     KeyValue {"ut_hits", ""},
     KeyValue {"UTHitsLocation", UTInfo::HitLocation},
     KeyValue {"allen_constants", ""}},
    // Outputs
    {KeyValue {"allen_ut_hits", ""}, KeyValue {"rec_ut_hits", ""}, KeyValue {"rec_ut_dxdys", ""}})
{}

std::tuple<std::vector<UT::Hit>, std::vector<UT::Hit>, std::vector<float>> GaudiAllenTransformAllenRecUTHits::
operator()(
  const std::vector<unsigned>& ut_hit_offsets,
  const std::vector<char>& ut_hits,
  LHCb::Pr::UT::Hits const& hit_handler,
  const Constants* const& allen_constants) const
{
  // read in offsets and hits from the buffer
  const auto n_hits_total_allen = ut_hit_offsets[ut_hit_offsets.size() - 1];
  const auto n_hits_total_rec = hit_handler.nHits();
  // call the UT::Hits_t ctor in UTEventModel.cuh with offset=0
  UT::ConstHits ut_hit_container_allen {ut_hits.data(), n_hits_total_allen};
  const auto& unique_x_sector_layer_offsets = allen_constants->host_unique_x_sector_layer_offsets;
  const auto& ut_hit_container_rec = hit_handler.simd();

  std::vector<UT::Hit> allen_hits, rec_hits;
  // Rec stores dxdy information inside hit, Allen accesses it using place code
  std::vector<float> rec_dxdys;
  allen_hits.reserve(n_hits_total_allen);
  rec_hits.reserve(n_hits_total_rec);
  rec_dxdys.reserve(n_hits_total_rec);

  constexpr int width = 12; // for printing results
  // loop sector groups and fill hit container for re-ordering
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
      debug() << std::setw(width) << "Allen Hit" << std::setw(width) << hit.LHCbID << std::setw(width) << hit.yBegin
              << std::setw(width) << hit.yEnd << std::setw(width) << hit.zAtYEq0 << std::setw(width) << hit.xAtYEq0
              << std::setw(width) << hit.weight << std::setw(width) << 0 << endmsg;
      allen_hits.emplace_back(hit);
    }
  } // end loop sector groups
  // Assign the correct layer to plane_code
  for (unsigned layer = 0; layer < UT::Constants::n_layers; layer++) {
    const unsigned layer_offset = ut_hit_offsets[unique_x_sector_layer_offsets[layer]];
    const unsigned number_of_hits_in_layer = ut_hit_offsets[unique_x_sector_layer_offsets[layer + 1]] - layer_offset;
    for (unsigned i = 0; i < number_of_hits_in_layer; i++) {
      const unsigned hit_idx = layer_offset + i;
      allen_hits[hit_idx].plane_code = layer;
    }
  }

  // loop SIMD UT Hits
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
      const auto channelID = LHCb::Detector::UT::ChannelID(channelIDs[j]);
      const auto lhcbID = bit_cast<int, unsigned int>(LHCb::LHCbID(channelID).lhcbID());
      const auto layer = channelID.layer();
      rec_hits.emplace_back(yBegins[j], yEnds[j], zAtYEq0s[j], xAtYEq0s[j], weights[j], lhcbID, layer);
      rec_dxdys.emplace_back(dxdys[j]);
    }
  }

  rec_hits.resize(n_hits_total_rec);
  return std::make_tuple(allen_hits, rec_hits, rec_dxdys);
}
