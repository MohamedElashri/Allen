/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"
#include <Gaudi/Accumulators/Histogram.h>

// LHCb
#include "Event/MCHit.h"
#include "Kernel/LHCbID.h"
#include "LHCbMath/SIMDWrapper.h"
#include "Event/VPLightCluster.h"

// Allen
#include "VeloEventModel.cuh"
#include "Logger.h"

using simd = SIMDWrapper::best::types;

class CompareRecAllenVPHits final : public Gaudi::Functional::Consumer<void(
                                      const std::vector<unsigned>&,
                                      const std::vector<unsigned>&,
                                      const std::vector<char>&,
                                      const LHCb::VPLightClusters&)> {

public:
  /// Standard constructor
  CompareRecAllenVPHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(
    const std::vector<unsigned>&,
    const std::vector<unsigned>&,
    const std::vector<char>&,
    const LHCb::VPLightClusters&) const override;
};

DECLARE_COMPONENT(CompareRecAllenVPHits)

CompareRecAllenVPHits::CompareRecAllenVPHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"vp_hits_num", ""},
     KeyValue {"vp_hit_offsets", ""},
     KeyValue {"vp_hits", ""},
     KeyValue {"VPHitsLocation", LHCb::VPClusterLocation::Light}})
{}

void CompareRecAllenVPHits::operator()(
  const std::vector<unsigned>& vp_hits_num,
  const std::vector<unsigned>& vp_hit_offsets,
  const std::vector<char>& vp_hits,
  LHCb::VPLightClusters const& hit_handler) const
{

  // the goal is to compare LHCbIDs of individual hits from data decoded with HLT1 and HLT2.
  std::vector<uint32_t> vp_ids_allen, vp_ids_rec;

  const auto n_hits_total_allen = vp_hit_offsets[Velo::Constants::n_module_pairs];
  const auto n_hits_total_rec = hit_handler.size();
  Velo::ConstClusters vp_hit_container_allen {vp_hits.data(), n_hits_total_allen};

  debug() << "Number of VP hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of VP hits (Rec) in this event   " << n_hits_total_rec << endmsg;

  // HLT1: loop module pairs and fill hit container
  for (unsigned i = 0; i < Velo::Constants::n_module_pairs; ++i) {
    const auto module_hit_start = vp_hit_offsets[i];
    const auto module_hit_num = vp_hits_num[i];
    // loop hits
    for (unsigned hit_number = 0; hit_number < module_hit_num; ++hit_number) {
      const auto hit_index = module_hit_start + hit_number;
      const auto id = vp_hit_container_allen.id(hit_index);
      vp_ids_allen.emplace_back(id & 0xFFFFFFF);
    }
  } // end loop sector groups

  // HLT2: loop cluster hits and fill hit container
  for (uint32_t i = 0; i < n_hits_total_rec; i++) {
    vp_ids_rec.emplace_back(hit_handler[i].channelID().channelID());
  }

  for (const auto& vp_id_allen : vp_ids_allen) {
    // where is std::erase_if https://en.cppreference.com/w/cpp/container/vector/erase2 ?
    // compare by LHCbID and x position (we mostly care about x, and everything below 1 micon difference is not
    // important for us)
    auto tmp_iter = std::remove_if(vp_ids_rec.begin(), vp_ids_rec.end(), [&vp_id_allen](auto& vp_id_rec) {
      return /*LHCbID*/ vp_id_rec == vp_id_allen;
    });
    const auto n_hits_found = std::distance(tmp_iter, vp_ids_rec.end());
    vp_ids_rec.erase(tmp_iter, vp_ids_rec.end());
    if (n_hits_found == 0) {
      error() << "Could not match this VP cluster decoded by Allen to a VP cluster decoded by Rec" << endmsg;
      error() << vp_id_allen << endmsg;
    }
    else if (n_hits_found > 1) {
      error() << "This VP cluster decoded by Allen has multiple VP clusters decoded by Rec" << endmsg;
      error() << vp_id_allen << endmsg;
    }
  }

  if (!vp_ids_rec.empty()) {
    for (const auto& vp_hit_rec : vp_ids_rec) {
      error() << "Lonely Rec hit " << vp_hit_rec << endmsg;
    }
  }
}
