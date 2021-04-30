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
// Rec
#include "PrKernel/PrUTHitHandler.h"
// Allen
#include "HostBuffers.cuh"
#include "UTEventModel.cuh"
#include "Logger.h"

using simd = SIMDWrapper::best::types;

class TestUTHits final
  : public Gaudi::Functional::Consumer<void(const HostBuffers&, const LHCb::MCHits&, const LHCb::Pr::UT::HitHandler&)> {

public:
  /// Standard constructor
  TestUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const HostBuffers&, const LHCb::MCHits&, const LHCb::Pr::UT::HitHandler&) const override;

private:
  mutable Gaudi::Accumulators::BinomialCounter<> m_allen_hit_eff {this, "GPU UT Hit efficiency"};
  mutable Gaudi::Accumulators::BinomialCounter<> m_rec_hit_eff {this, "CPU UT Hit efficiency"};
};

DECLARE_COMPONENT(TestUTHits)

TestUTHits::TestUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"},
     KeyValue {"UnpackedUTHits", "/Event/MC/UT/Hits"},
     KeyValue {"UTHitsLocation", UT::Info::HitLocation}})
{}

void TestUTHits::operator()(
  HostBuffers const& host_buffers,
  LHCb::MCHits const& mc_hits,
  LHCb::Pr::UT::HitHandler const& hit_handler) const
{
  if (host_buffers.host_number_of_selected_events == 0) {
    warning() << "No events from Allen. Returning" << endmsg;
    return;
  }

  // read in offsets and hits from the buffer
  const auto& ut_hit_offsets = host_buffers.ut_hits_offsets;
  const auto& ut_hits = host_buffers.ut_hits;

  const auto n_hits_total_allen = ut_hit_offsets[host_buffers.ut_hits_offsets.size() - 1];
  const auto n_hits_total_rec = hit_handler.nHits();
  // call the UT::Hits_t ctor in UTEventModel.cuh with offset=0
  UT::ConstHits ut_hit_container_allen {ut_hits.data(), n_hits_total_allen};
  const auto& ut_hit_container_rec = hit_handler.hits(); // const LHCb::Pr::UT::Hits&

  debug() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;
  debug() << "Number of MC UT hits in this event      " << mc_hits.size() << endmsg;

  constexpr int width = 12; // for printing results
  // there seem to be 4 different zAtYEq0 per layer. the entry/exit points of a MC hit are close-by (the tolerance of pm
  // 0.18 mm works for v4 and v5 decoding/geometry)
  constexpr float tol_x = 1.f, tol_y = 5.f, tol_z = 0.18f;

  // Usually one would get this kind of info from the geometry. The little trick below should work similar, and the
  // cases that it doesn't cover should be pathological... (the trick is simple: fill a vector of unique z-positions.
  // there should be 16 or less if there are no hits in the respective area)
  std::vector<float> known_zAtYEq0;
  for (unsigned sector_group_index = 0; sector_group_index < host_buffers.ut_hits_offsets.size() - 1;
       sector_group_index++)
    for (unsigned hit_idx = ut_hit_offsets[sector_group_index]; hit_idx < ut_hit_offsets[sector_group_index + 1];
         hit_idx++)
      if (
        std::find(known_zAtYEq0.begin(), known_zAtYEq0.end(), ut_hit_container_allen.getHit(hit_idx).zAtYEq0) ==
        known_zAtYEq0.end())
        known_zAtYEq0.emplace_back(ut_hit_container_allen.getHit(hit_idx).zAtYEq0);

  const auto n_z_planes = known_zAtYEq0.size();
  assert(n_z_planes <= 16);
  std::sort(known_zAtYEq0.begin(), known_zAtYEq0.end());
  std::vector<float> dxdy_in_plane(n_z_planes, 0.f);
  std::vector<std::vector<LHCb::MCHit>> regrouped_mc_hits(n_z_planes);
  std::vector<std::vector<UT::Hit>> regrouped_allen_hits(n_z_planes), regrouped_rec_hits(n_z_planes);

  auto get_z_position_index = [&known_zAtYEq0, &tol_z, &n_z_planes, this](const float& z) {
    auto index = std::find_if(
                   known_zAtYEq0.begin(),
                   known_zAtYEq0.end(),
                   [&z, &tol_z](const float& known_z) { return abs(z - known_z) < tol_z; }) -
                 known_zAtYEq0.begin();
    if (static_cast<std::decay<decltype(n_z_planes)>::type>(index) >= n_z_planes || index < 0) {
      // this happens for padded SIMD hits
      // https://gitlab.cern.ch/lhcb/Rec/-/blob/90012e6d0a0d0122496ede72c6dea0dda06e2d9b/Pr/PrKernel/PrKernel/PrUTHitHandler.h#L120
      debug() << "z position " << z << " unkown. We have a problem...." << endmsg;
      index = 0;
    }
    return index;
  };

  // loop sector groups and fill hit container for re-ordering
  for (unsigned sector_group_index = 0; sector_group_index < host_buffers.ut_hits_offsets.size() - 1;
       sector_group_index++) {
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
      regrouped_allen_hits[get_z_position_index(hit.zAtYEq0)].emplace_back(hit);
    }
  } // end loop sector groups

  // loop UT MCHits
  for (const auto& ut_mc_hit : mc_hits)
    regrouped_mc_hits[get_z_position_index(ut_mc_hit->entry().z())].emplace_back(*ut_mc_hit);

  // loop SIMD UT Hits
  for (int i = 0; i < n_hits_total_rec; i += simd::size) {
    std::array<int, simd::size> channelIDs;
    ut_hit_container_rec.channelID<simd::int_v>(i).store(channelIDs.data());
    std::array<float, simd::size> yBegins, yEnds, zAtYEq0s, xAtYEq0s, weights, dxdys;
    ut_hit_container_rec.yBegin<simd::float_v>(i).store(yBegins.data());
    ut_hit_container_rec.yEnd<simd::float_v>(i).store(yEnds.data());
    ut_hit_container_rec.zAtYEq0<simd::float_v>(i).store(zAtYEq0s.data());
    ut_hit_container_rec.xAtYEq0<simd::float_v>(i).store(xAtYEq0s.data());
    ut_hit_container_rec.weight<simd::float_v>(i).store(weights.data());
    ut_hit_container_rec.dxDy<simd::float_v>(i).store(dxdys.data());
    for (std::size_t j = 0; j < simd::size; j++) {
      const auto bogus_plane_index = get_z_position_index(zAtYEq0s[j]);
      regrouped_rec_hits[bogus_plane_index].emplace_back(
        yBegins[j],
        yEnds[j],
        zAtYEq0s[j],
        xAtYEq0s[j],
        weights[j],
        bit_cast<int, unsigned int>(LHCb::LHCbID(channelIDs[j]).lhcbID()),
        0);
      if (dxdys[j] < 1e+6)
        dxdy_in_plane[bogus_plane_index] =
          dxdys[j]; // FIXME: this is overwritten each and every time, but hopefully with the same values...
    }
  }

  // why not also sort hits by x. it can't hurt
  auto sort_by_x_ut_hit = [](const auto& hit_a, const auto& hit_b) -> bool { return hit_a.xAtYEq0 < hit_b.xAtYEq0; };

  debug() << std::string(8 * width, '#') << endmsg;
  // loop "z-planes"
  for (unsigned i = 0; i < n_z_planes; i++) {
    // sort hits by x to be able to stop the truth-matching loop early
    std::sort(regrouped_mc_hits[i].begin(), regrouped_mc_hits[i].end(), [](const auto& hit_a, const auto& hit_b) {
      return hit_a.entry().x() < hit_b.entry().x();
    });
    std::sort(regrouped_allen_hits[i].begin(), regrouped_allen_hits[i].end(), sort_by_x_ut_hit);
    std::sort(regrouped_rec_hits[i].begin(), regrouped_rec_hits[i].end(), sort_by_x_ut_hit);

    const auto n_allen_hits_in_current_plane = regrouped_allen_hits[i].size();
    std::vector<bool> allen_match_mask(n_allen_hits_in_current_plane, false);
    const auto n_rec_hits_in_current_plane = regrouped_rec_hits[i].size();
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
      unsigned short hit_mult = 0;
      // truth matching by comparing MC hit position to decoded strip position. also handles bookkeeping like counters.
      // returns condition whether or not to keep going in loop over decoded hits
      auto simple_truth_matching = [&mch_x, &mch_y, p_dxdy = dxdy_in_plane[i], &tol_x, &tol_y, &hit_mult](
                                     const auto& hit, auto hit_matched) -> bool {
        if (
          abs((hit.xAtYEq0 + p_dxdy * mch_y) - mch_x) < tol_x && hit.yBegin - tol_y < mch_y &&
          mch_y < hit.yEnd + tol_y) {
          hit_mult++;
          hit_matched = true;
          return true;
        }
        else if ((hit.xAtYEq0 + p_dxdy * mch_y) > (mch_x + tol_x))
          return false;
        return true;
      };
      for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++)
        if (!simple_truth_matching(regrouped_allen_hits[i][j], allen_match_mask[j])) break;
      m_allen_hit_eff += hit_mult > 0;

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
        if (!simple_truth_matching(regrouped_rec_hits[i][j], rec_match_mask[j])) break;
      }
      m_rec_hit_eff += hit_mult > 0;
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
            << std::setw(width) << "weight" << std::setw(width) << "dxdy" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++) {
      if (!allen_match_mask[j])
        debug() << std::setw(width) << "Allen Hit" << std::setw(width) << regrouped_allen_hits[i][j].LHCbID
                << std::setw(width) << regrouped_allen_hits[i][j].yBegin << std::setw(width)
                << regrouped_allen_hits[i][j].yEnd << std::setw(width) << regrouped_allen_hits[i][j].zAtYEq0
                << std::setw(width) << regrouped_allen_hits[i][j].xAtYEq0 << std::setw(width)
                << regrouped_allen_hits[i][j].weight << std::setw(width) << dxdy_in_plane[i] << endmsg;
    }
    debug() << "Rec UT hits in plane " << i << " : " << n_rec_hits_in_current_plane << endmsg;
    debug() << "Printing those that could not be matched " << endmsg;
    debug() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "yBegin"
            << std::setw(width) << "yEnd" << std::setw(width) << "zAtYEq0" << std::setw(width) << "xAtYEq0"
            << std::setw(width) << "weight" << std::setw(width) << "dxdy" << endmsg;
    debug() << std::string(8 * width, '-') << endmsg;
    for (unsigned j = 0; j < n_rec_hits_in_current_plane; j++) {
      if (!rec_match_mask[j])
        debug() << std::setw(width) << "Rec Hit" << std::setw(width) << regrouped_rec_hits[i][j].LHCbID
                << std::setw(width) << regrouped_rec_hits[i][j].yBegin << std::setw(width)
                << regrouped_rec_hits[i][j].yEnd << std::setw(width) << regrouped_rec_hits[i][j].zAtYEq0
                << std::setw(width) << regrouped_rec_hits[i][j].xAtYEq0 << std::setw(width)
                << regrouped_rec_hits[i][j].weight << std::setw(width) << dxdy_in_plane[i] << endmsg;
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
