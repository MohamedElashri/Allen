/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"
#include <Gaudi/Accumulators/Histogram.h>

// LHCb
#include "Event/MCHit.h"
#include "LHCbMath/SIMDWrapper.h"
// Rec
#include "PrKernel/PrUTHitHandler.h"
// Allen
#include "HostBuffers.cuh"
#include "UTEventModel.cuh"
#include "Logger.h"


using simd = SIMDWrapper::best::types;

class TestUTHits final : public Gaudi::Functional::Consumer<void(const HostBuffers&, const LHCb::MCHits&, const LHCb::Pr::UT::HitHandler&)> {

public:
  /// Standard constructor
  TestUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const HostBuffers&, const LHCb::MCHits&, const LHCb::Pr::UT::HitHandler&) const override;

private:
  mutable Gaudi::Accumulators::BinomialCounter<> m_allen_hit_eff{this, "GPU UT Hit efficiency"};
  mutable Gaudi::Accumulators::BinomialCounter<> m_rec_hit_eff{this, "CPU UT Hit efficiency"};
  // FIXME: histograms don't work yet
  mutable Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float> m_allen_dx{this, "allen_dx",
    ";x(y=0)_{Allen UT Hit} - x_{mid,MC UT Hit};Allen UT Hits / 10 #mum", {200,-1.f,1.f}};
  mutable Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float> m_rec_dx{this, "rec_dx",
    ";x(y=0)_{Rec UT Hit} - x_{mid,MC UT Hit};Rec UT Hits / 10 #mum", {200,-1.f,1.f}};
  mutable Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, unsigned short> m_allen_hit_multiplicity{this, "allen_mult",
    ";Multiplicity of matched Allen UT Hits", {10,0,10}};
  mutable Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, unsigned short> m_rec_hit_multiplicity{this, "rec_mult",
    ";Multiplicity of matched Rec UT Hits", {10,0,10}};
};

DECLARE_COMPONENT(TestUTHits)

TestUTHits::TestUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer( name, pSvcLocator, { KeyValue{"AllenOutput", "Allen/Out/HostBuffers"},
                                KeyValue{"UnpackedUTHits", "/Event/MC/UT/Hits"},
                                KeyValue{"UTHitsLocation", UT::Info::HitLocation} }) {}

void TestUTHits::operator()(HostBuffers const& host_buffers, LHCb::MCHits const& mc_hits, LHCb::Pr::UT::HitHandler const& hit_handler) const
{
  if (host_buffers.host_number_of_selected_events == 0) return;

  // read in offsets and hits from the buffer
  const auto& ut_hit_offsets = host_buffers.ut_hits_offsets;
  const auto& ut_hits = host_buffers.ut_hits;

  const auto n_hits_total_allen = ut_hit_offsets[host_buffers.ut_hits_offsets.size()-1];
  const auto n_hits_total_rec   = hit_handler.nHits();
  // call the UT::Hits_t ctor in UTEventModel.cuh with offset=0
  UT::ConstHits ut_hit_container_allen {ut_hits.data(), n_hits_total_allen};
  const auto& ut_hit_container_rec = hit_handler.hits(); //const LHCb::Pr::UT::Hits&

  info() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  info() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;
  info() << "Number of MC UT hits in this event      " << mc_hits.size() << endmsg;

  constexpr int width = 12;// for printing results
  // there seem to be 4 different zAtYEq0 per layer. the entry/exit points of a MC hit are close-by (at most pm 0.125 mm)
  // TODO: find out what these planes correspond to and how to interact with the detector infrastructure that describes it
  constexpr float tol_x = 1.f, tol_y = 5.f, tol_z = 0.13f;
  //re-organize the hits accordingly to be able to match them
  constexpr unsigned z_planes = 16;
  constexpr std::array<float, z_planes> known_zAtYEq0 = { 2320.28f, 2324.72f, 2330.28f, 2334.72f, 2365.28f, 2369.72f, 2375.28f, 2379.72f,
                                                          2590.28f, 2594.72f, 2600.28f, 2604.72f, 2635.28f, 2639.72f, 2645.28f, 2649.72f };
  std::array<float, z_planes> dxdy_in_plane;
  std::array<std::vector<LHCb::MCHit>,z_planes> regrouped_mc_hits;
  std::array<std::vector<UT::Hit>,z_planes> regrouped_allen_hits, regrouped_rec_hits;

  auto get_z_position_index = [&known_zAtYEq0, &tol_z, &z_planes, this] (const float& z) {
    auto index = std::find_if(known_zAtYEq0.begin(),known_zAtYEq0.end(),[&z, &tol_z](const float& known_z){return abs(z - known_z) < tol_z;}) - known_zAtYEq0.begin();
    if(index>=z_planes || index<0) {
      debug() << "z position "<< z <<" unkown. We have a problem...."<<endmsg;
      index = 0;
    }
    return index;
  };

  // loop sector groups
  for (unsigned sector_group_index = 0; sector_group_index < host_buffers.ut_hits_offsets.size()-1; sector_group_index++) {
    // loop hits in sector group
    for (unsigned hit_idx = ut_hit_offsets[sector_group_index]; hit_idx < ut_hit_offsets[sector_group_index+1]; hit_idx++){
      const auto hit = ut_hit_container_allen.getHit(hit_idx);
      regrouped_allen_hits[get_z_position_index(hit.zAtYEq0)].emplace_back(hit);
    }
  }// end loop sector groups

  // loop UT MCHits
  for(const auto& ut_mc_hit : mc_hits) regrouped_mc_hits[get_z_position_index(ut_mc_hit->entry().z())].emplace_back(*ut_mc_hit);

  // loop SIMD UT Hits
  for ( int i = 0; i < n_hits_total_rec; i += simd::size ){
    std::array<int,simd::size> channelIDs;
    ut_hit_container_rec.channelID<simd::int_v>(i).store(channelIDs.data());
    std::array<float,simd::size> yBegins, yEnds, zAtYEq0s, xAtYEq0s, weights, dxdys;
    ut_hit_container_rec.yBegin<simd::float_v>(i).store(yBegins.data());
    ut_hit_container_rec.yEnd<simd::float_v>(i).store(yEnds.data());
    ut_hit_container_rec.zAtYEq0<simd::float_v>(i).store(zAtYEq0s.data());
    ut_hit_container_rec.xAtYEq0<simd::float_v>(i).store(xAtYEq0s.data());
    ut_hit_container_rec.weight<simd::float_v>(i).store(weights.data());
    ut_hit_container_rec.dxDy<simd::float_v>(i).store(dxdys.data());
    for (std::size_t j = 0; j < simd::size; j++) {
      const auto bogus_plane_index = get_z_position_index(zAtYEq0s[j]);
      regrouped_rec_hits[bogus_plane_index].emplace_back(yBegins[j],yEnds[j],zAtYEq0s[j],xAtYEq0s[j],weights[j],channelIDs[j],0);
      if(dxdys[j]<1e+6)
        dxdy_in_plane[bogus_plane_index] = dxdys[j];//FIXME: this is overwritten each and every time, but hopefully with the same values...
    }
  }

  auto sort_by_x_ut_hit = [](const auto& hit_a, const auto& hit_b) -> bool {return hit_a.xAtYEq0 < hit_b.xAtYEq0;};

  info() << std::string(8*width,'#') << endmsg;
  // loop "z-planes"
  for (unsigned i = 0; i < z_planes; i++) {
    // sort hits by x
    std::sort(regrouped_mc_hits[i].begin(),regrouped_mc_hits[i].end(),[](const auto& hit_a, const auto& hit_b){return hit_a.entry().x() < hit_b.entry().x();});
    std::sort(regrouped_allen_hits[i].begin(),regrouped_allen_hits[i].end(),sort_by_x_ut_hit);
    std::sort(regrouped_rec_hits[i].begin(),regrouped_rec_hits[i].end(),sort_by_x_ut_hit);

    const auto n_allen_hits_in_current_plane = regrouped_allen_hits[i].size();
    std::vector<bool> allen_match_mask(n_allen_hits_in_current_plane,false);

    info() << "UT MC hits in plane " << i << " : " << regrouped_mc_hits[i].size() << endmsg;
    info() << "Printing those that could not be matched " << endmsg;
    info() << std::setw(width) << "Type" << std::setw(width) << "x_entry" << std::setw(width) << "y_entry" << std::setw(width)
           << "z_entry" << std::setw(width) << "z_exit" << std::setw(width) << "time [ns]" << std::setw(width) << "p [MeV]" << std::setw(width) << "dep. E [MeV]" << endmsg;
    info() << std::string(8*width,'-') << endmsg;
    for (const auto& ut_mc_hit : regrouped_mc_hits[i]){
      const auto current_x = ut_mc_hit.midPoint().x();
      const auto current_y = ut_mc_hit.midPoint().y();
      unsigned short hit_mult = 0;
      for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++){
        if(abs((regrouped_allen_hits[i][j].xAtYEq0 + dxdy_in_plane[i]*current_y) - current_x) < tol_x
           && regrouped_allen_hits[i][j].yBegin - tol_y < current_y && current_y < regrouped_allen_hits[i][j].yEnd + tol_y){
          hit_mult++;
          m_allen_dx += regrouped_allen_hits[i][j].xAtYEq0-current_x;
          allen_match_mask[j] = true;
        }
        else if((regrouped_allen_hits[i][j].xAtYEq0 + dxdy_in_plane[i]*current_y) > (current_x + tol_x)) break;
      }
      m_allen_hit_eff += hit_mult>0;
      m_allen_hit_multiplicity += hit_mult;
      if(hit_mult==0){
        //int pid = 0;
        //if(ut_mc_hit.mcParticle()!=nullptr) pid = ut_mc_hit.mcParticle()->particleID().pid(); // this never works in the test i'm running. maybe with a different sample...
        info() << std::setw(width) << "MCHit" << std::setw(width) << ut_mc_hit.entry().x() << std::setw(width) << ut_mc_hit.entry().y()
               << std::setw(width) << ut_mc_hit.entry().z() << std::setw(width) << ut_mc_hit.exit().z() << std::setw(width) << ut_mc_hit.time()
               << std::setw(width) << ut_mc_hit.p() << std::setw(width) << ut_mc_hit.energy() << endmsg;
      }

      // reset and loop rec hits
      hit_mult = 0;
      for (const auto& ut_hit : regrouped_rec_hits[i]){
        if(abs((ut_hit.xAtYEq0 + dxdy_in_plane[i]*current_y)-current_x) < tol_x && ut_hit.yBegin - tol_y < current_y && current_y < ut_hit.yEnd + tol_y){
          hit_mult++;
          m_rec_dx += ut_hit.xAtYEq0-current_x;
        }
        else if((ut_hit.xAtYEq0 + dxdy_in_plane[i]*current_y) > (current_x + tol_x)) break;
      }
      m_rec_hit_eff += hit_mult>0;
      m_rec_hit_multiplicity += hit_mult;
    }
    info() << "Allen UT hits in plane " << i << " : " << n_allen_hits_in_current_plane << endmsg;
    info() << "Printing those that could not be matched " << endmsg;
    info() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "yBegin" << std::setw(width) << "yEnd" << std::setw(width)
           << "zAtYEq0" << std::setw(width) << "xAtYEq0" << std::setw(width) << "weight" << std::setw(width) << "dxdy" << endmsg;
    info() << std::string(8*width,'-') << endmsg;
    for (unsigned j = 0; j < n_allen_hits_in_current_plane; j++){
      if(!allen_match_mask[j])
        info() << std::setw(width) << "Allen Hit" << std::setw(width) << regrouped_allen_hits[i][j].LHCbID << std::setw(width) << regrouped_allen_hits[i][j].yBegin
               << std::setw(width) << regrouped_allen_hits[i][j].yEnd << std::setw(width) << regrouped_allen_hits[i][j].zAtYEq0
               << std::setw(width) << regrouped_allen_hits[i][j].xAtYEq0 << std::setw(width) << regrouped_allen_hits[i][j].weight
               << std::setw(width) << dxdy_in_plane[i] << endmsg;
    }
    info() << "Printing all MC Hits for comparison" << endmsg;
    info() << std::setw(width) << "Type" << std::setw(width) << "x_entry" << std::setw(width) << "y_entry" << std::setw(width)
           << "z_entry" << std::setw(width) << "z_exit" << std::setw(width) << "time [ns]" << std::setw(width) << "p [MeV]" << std::setw(width) << "dep. E [MeV]" << endmsg;
    info() << std::string(8*width,'-') << endmsg;
    for (const auto& ut_mc_hit : regrouped_mc_hits[i])
      info() << std::setw(width) << "MCHit" << std::setw(width) << ut_mc_hit.entry().x() << std::setw(width) << ut_mc_hit.entry().y()
                 << std::setw(width) << ut_mc_hit.entry().z() << std::setw(width) << ut_mc_hit.exit().z() << std::setw(width) << ut_mc_hit.time()
                 << std::setw(width) << ut_mc_hit.p() << std::setw(width) << ut_mc_hit.energy() << endmsg;
  }// end loop z_planes
  info() << std::string(8*width,'#') << endmsg;
}