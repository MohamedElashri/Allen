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
#include <Gaudi/Accumulators/Histogram.h>

// LHCb
#include "Event/MCHit.h"
#include "Kernel/LHCbID.h"
#include "LHCbMath/SIMDWrapper.h"
#include "Event/PrHits.h"

// Allen
#include "LHCbID.cuh"
#include "UTEventModel.cuh"
#include "Logger.h"
#include "Constants.cuh"

using simd = SIMDWrapper::best::types;

class MCCheckRecAllenUTHits final
  : public Gaudi::Functional::Consumer<
      void(const std::vector<UT::Hit>&, const std::vector<UT::Hit>&, const LHCb::MCHits&)> {

public:
  /// Standard constructor
  MCCheckRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<UT::Hit>&, const std::vector<UT::Hit>&, const LHCb::MCHits&) const override;

private:
  mutable std::unique_ptr<Gaudi::Accumulators::BinomialCounter<>> m_allen_hit_eff;
  mutable std::unique_ptr<Gaudi::Accumulators::BinomialCounter<>> m_rec_hit_eff;

  // To label different UT clustering methods
  Gaudi::Property<std::string> m_weighting_method {this, "WeightingMethod"};
  Gaudi::Property<unsigned> m_max_cluster_size {this, "MaxClusterSize"};

  // Geometrical tolerances
  Gaudi::Property<float> m_tol_x {this, "m_tol_x", 1.f, "X tolerance"};
  Gaudi::Property<float> m_tol_y {this, "m_tol_y", 5.f, "Y tolerance"};
  Gaudi::Property<float> m_tol_z {this, "m_tol_z", 0.18f, "Z tolerance"};
};

DECLARE_COMPONENT(MCCheckRecAllenUTHits)

MCCheckRecAllenUTHits::MCCheckRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"allen_ut_hits", ""}, KeyValue {"rec_ut_hits", ""}, KeyValue {"UnpackedUTHits", "/Event/MC/UT/Hits"}})
{}

void MCCheckRecAllenUTHits::operator()(
  const std::vector<UT::Hit>& allen_hits,
  const std::vector<UT::Hit>& rec_hits,
  const LHCb::MCHits& mc_hits) const
{
  // Different counter names for different UT decoding settings
  // Need to do it this way because m_max_cluster_size and m_weighting_method will only be known
  //   during first invocation of operator()
  if (!m_allen_hit_eff) {
    const std::string label =
      "UT " + m_weighting_method + " clusters max " + std::to_string(static_cast<unsigned>(m_max_cluster_size)) + ": ";
    m_allen_hit_eff = std::make_unique<Gaudi::Accumulators::BinomialCounter<>>(this, label + "GPU Hit efficiency");
    m_rec_hit_eff = std::make_unique<Gaudi::Accumulators::BinomialCounter<>>(this, label + "CPU Hit efficiency");
  }

  const auto n_hits_total_allen = allen_hits.size();
  const auto n_hits_total_rec = rec_hits.size();

  debug() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;
  debug() << "Number of MC UT hits in this event      " << mc_hits.size() << endmsg;

  constexpr int width = 12; // for printing results
  // there seem to be 4 different zAtYEq0 per layer. the entry/exit points of a MC hit are close-by (the tolerance of pm
  // 0.18 mm works for v4 and v5 decoding/geometry)

  // Usually one would get this kind of info from the geometry. The little trick below should work similar, and the
  // cases that it doesn't cover should be pathological... (the trick is simple: fill a vector of unique z-positions.
  // there should be 16 or less if there are no hits in the respective area)
  std::vector<float> known_zAtYEq0;
  for (const auto& hit : allen_hits) {
    const bool is_unique_zAtYEq0 =
      std::find(known_zAtYEq0.begin(), known_zAtYEq0.end(), hit.zAtYEq0) == known_zAtYEq0.end();
    if (is_unique_zAtYEq0) known_zAtYEq0.emplace_back(hit.zAtYEq0);
  }

  const auto n_z_planes = known_zAtYEq0.size();
  assert(n_z_planes <= 16);
  std::sort(known_zAtYEq0.begin(), known_zAtYEq0.end());
  std::vector<std::vector<LHCb::MCHit>> regrouped_mc_hits(n_z_planes);
  std::vector<std::vector<UT::Hit>> regrouped_allen_hits(n_z_planes), regrouped_rec_hits(n_z_planes);

  auto get_z_position_index = [&known_zAtYEq0, &n_z_planes, this, tol_z = static_cast<float>(m_tol_z)](const float& z) {
    auto index = std::find_if(
                   known_zAtYEq0.begin(),
                   known_zAtYEq0.end(),
                   [&z, tol_z](const float& known_z) { return abs(z - known_z) < tol_z; }) -
                 known_zAtYEq0.begin();
    if (static_cast<std::decay<decltype(n_z_planes)>::type>(index) >= n_z_planes || index < 0) {
      // this happens for padded SIMD hits
      // https://gitlab.cern.ch/lhcb/Rec/-/blob/90012e6d0a0d0122496ede72c6dea0dda06e2d9b/Pr/PrKernel/PrKernel/PrUTHitHandler.h#L120
      debug() << "z position " << z << " unkown. We have a problem...." << endmsg;
      index = 0;
    }
    return index;
  };

  // Loop reconstructed UT hits
  for (const auto& hit : allen_hits) {
    regrouped_allen_hits[get_z_position_index(hit.zAtYEq0)].emplace_back(hit);
  }
  for (const auto& hit : rec_hits) {
    regrouped_rec_hits[get_z_position_index(hit.zAtYEq0)].emplace_back(hit);
  }

  // Loop UT MCHits
  for (const auto& hit : mc_hits)
    regrouped_mc_hits[get_z_position_index(hit->entry().z())].emplace_back(*hit);

  // why not also sort hits by x. it can't hurt
  auto sort_by_x_ut_hit = [](const auto& hit_a, const auto& hit_b) -> bool { return hit_a.xAtYEq0 < hit_b.xAtYEq0; };

  debug() << std::string(8 * width, '#') << endmsg;
  // loop "z-planes"
  for (unsigned i = 0; i < n_z_planes; i++) {
    const auto n_allen_hits_in_current_plane = regrouped_allen_hits[i].size();
    const auto n_rec_hits_in_current_plane = regrouped_rec_hits[i].size();

    // sort hits by x for more readable debug messages
    std::sort(regrouped_mc_hits[i].begin(), regrouped_mc_hits[i].end(), [](const auto& hit_a, const auto& hit_b) {
      return hit_a.entry().x() < hit_b.entry().x();
    });
    std::sort(regrouped_allen_hits[i].begin(), regrouped_allen_hits[i].end(), sort_by_x_ut_hit);
    std::sort(regrouped_rec_hits[i].begin(), regrouped_rec_hits[i].end(), sort_by_x_ut_hit);

    std::vector<bool> allen_match_mask(n_allen_hits_in_current_plane, false);
    std::vector<bool> rec_match_mask(n_rec_hits_in_current_plane, false);

    debug() << "UT MC hits in plane " << i << " : " << regrouped_mc_hits[i].size() << endmsg;
    debug() << "Printing those that could not be matched " << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "x_entry" << std::setw(width) << "y_entry"
            << std::setw(width) << "z_entry" << std::setw(width) << "z_exit" << std::setw(width) << "time [ns]"
            << std::setw(width) << "p [MeV]" << std::setw(width) << "dep. E [MeV]" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (const auto& ut_mc_hit : regrouped_mc_hits[i]) {
      const auto mch_x = ut_mc_hit.midPoint().x();
      const auto mch_y = ut_mc_hit.midPoint().y();
      unsigned hit_mult = 0;

      // truth matching by comparing MC hit position to decoded strip position. also handles bookkeeping like counters.
      auto simple_truth_matching = [&mch_x,
                                    &mch_y,
                                    tol_x = static_cast<float>(m_tol_x),
                                    tol_y = static_cast<float>(m_tol_y)](const auto& hit, auto hit_matched) -> bool {
        const bool in_x_tolerance = abs((hit.xAtYEq0 + hit.dxDy * mch_y) - mch_x) < tol_x;
        const bool in_y_tolerance = hit.yBegin - tol_y < mch_y && mch_y < hit.yEnd + tol_y;
        const bool matched = in_x_tolerance && in_y_tolerance;
        hit_matched = matched;
        return matched;
      };

      for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++) {
        if (simple_truth_matching(regrouped_allen_hits[i][j], allen_match_mask[j])) {
          hit_mult++;
        }
      }
      (*m_allen_hit_eff) += hit_mult > 0;

      if (hit_mult == 0) {
        // int pid = 0;
        // if(ut_mc_hit.mcParticle()!=nullptr) pid = ut_mc_hit.mcParticle()->particleID().pid(); // this never works in
        // the test i'm running. maybe with a different sample...
        debug() << std::setw(width) << "AMCHit" << std::setw(width) << ut_mc_hit.entry().x() << std::setw(width)
                << ut_mc_hit.entry().y() << std::setw(width) << ut_mc_hit.entry().z() << std::setw(width)
                << ut_mc_hit.exit().z() << std::setw(width) << ut_mc_hit.time() << std::setw(width) << ut_mc_hit.p()
                << std::setw(width) << ut_mc_hit.energy() << endmsg;
      }

      // reset and loop rec hits
      hit_mult = 0;
      for (unsigned j = 0; j < n_rec_hits_in_current_plane; j++) {
        if (simple_truth_matching(regrouped_rec_hits[i][j], rec_match_mask[j])) {
          hit_mult++;
        }
      }
      (*m_rec_hit_eff) += hit_mult > 0;
      if (hit_mult == 0) {
        // int pid = 0;
        // if(ut_mc_hit.mcParticle()!=nullptr) pid = ut_mc_hit.mcParticle()->particleID().pid();
        debug() << std::setw(width) << "RMCHit" << std::setw(width) << ut_mc_hit.entry().x() << std::setw(width)
                << ut_mc_hit.entry().y() << std::setw(width) << ut_mc_hit.entry().z() << std::setw(width)
                << ut_mc_hit.exit().z() << std::setw(width) << ut_mc_hit.time() << std::setw(width) << ut_mc_hit.p()
                << std::setw(width) << ut_mc_hit.energy() << endmsg;
      }
    }

    // So far we've asked the question which of the MCHits was not found in the decoding.
    // Now we look at extra hits from the decoding (noise) that could not be associated to a MCHit
    // All of this is debug output
    debug() << "Allen UT hits in plane " << i << " : " << n_allen_hits_in_current_plane << endmsg;
    debug() << "Printing those that could not be matched " << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "yBegin"
            << std::setw(width) << "yEnd" << std::setw(width) << "zAtYEq0" << std::setw(width) << "xAtYEq0"
            << std::setw(width) << "dxDy" << std::setw(width) << "weight" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++) {
      if (!allen_match_mask[j])
        debug() << std::setw(width) << "Allen Hit" << std::setw(width) << regrouped_allen_hits[i][j].LHCbID
                << std::setw(width) << regrouped_allen_hits[i][j].yBegin << std::setw(width)
                << regrouped_allen_hits[i][j].yEnd << std::setw(width) << regrouped_allen_hits[i][j].zAtYEq0
                << std::setw(width) << regrouped_allen_hits[i][j].xAtYEq0 << std::setw(width)
                << regrouped_allen_hits[i][j].dxDy << std::setw(width) << regrouped_allen_hits[i][j].weight << endmsg;
    }
    debug() << "Rec UT hits in plane " << i << " : " << n_rec_hits_in_current_plane << endmsg;
    debug() << "Printing those that could not be matched " << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "yBegin"
            << std::setw(width) << "yEnd" << std::setw(width) << "zAtYEq0" << std::setw(width) << "xAtYEq0"
            << std::setw(width) << "dxDy" << std::setw(width) << "weight" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (unsigned j = 0; j < n_rec_hits_in_current_plane; j++) {
      if (!rec_match_mask[j])
        debug() << std::setw(width) << "Rec Hit" << std::setw(width) << regrouped_rec_hits[i][j].LHCbID
                << std::setw(width) << regrouped_rec_hits[i][j].yBegin << std::setw(width)
                << regrouped_rec_hits[i][j].yEnd << std::setw(width) << regrouped_rec_hits[i][j].zAtYEq0
                << std::setw(width) << regrouped_rec_hits[i][j].xAtYEq0 << std::setw(width)
                << regrouped_rec_hits[i][j].dxDy << std::setw(width) << regrouped_rec_hits[i][j].weight << endmsg;
    }
    debug() << "Printing all MC Hits for comparison" << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "x_entry" << std::setw(width) << "y_entry"
            << std::setw(width) << "z_entry" << std::setw(width) << "z_exit" << std::setw(width) << "time [ns]"
            << std::setw(width) << "p [MeV]" << std::setw(width) << "dep. E [MeV]" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (const auto& ut_mc_hit : regrouped_mc_hits[i])
      debug() << std::setw(width) << "MCHit" << std::setw(width) << ut_mc_hit.entry().x() << std::setw(width)
              << ut_mc_hit.entry().y() << std::setw(width) << ut_mc_hit.entry().z() << std::setw(width)
              << ut_mc_hit.exit().z() << std::setw(width) << ut_mc_hit.time() << std::setw(width) << ut_mc_hit.p()
              << std::setw(width) << ut_mc_hit.energy() << endmsg;
  } // end loop n_z_planes
  debug() << std::string(8 * width, '#') << endmsg;
}
