/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"

// LHCb
#include "MuonDAQ/MuonHitContainer.h"

// Allen
#include "MuonEventModel.cuh"
#include "MuonDefinitions.cuh"
#include "Logger.h"

class TestMuonHits final : public Gaudi::Functional::Consumer<
                             void(const std::vector<unsigned>&, const std::vector<char>&, const MuonHitContainer&)> {

public:
  /// Standard constructor
  TestMuonHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<unsigned>&, const std::vector<char>&, const MuonHitContainer&) const override;
};

DECLARE_COMPONENT(TestMuonHits)

TestMuonHits::TestMuonHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"muon_offsets", ""},
     KeyValue {"muon_hits", ""},
     KeyValue {"MuonHitsLocation", MuonHitContainerLocation::Default}})
{}

void TestMuonHits::operator()(
  const std::vector<unsigned>& muon_hit_offsets,
  const std::vector<char>& muon_hits,
  const MuonHitContainer& muon_hit_container) const
{

  // the goal is to compare tileIDs (maybe?) of individual hits, and their positions from data decoded with HLT1 and
  // HLT2. it's not imperative to store them in another container like this; it's fine to do the comparison on the fly
  // or differently.
  std::vector<Muon::Hit> muon_hits_allen, muon_hits_rec;

  const auto n_hits_total_allen = muon_hit_offsets[Muon::Constants::n_stations];
  const auto muon_hits_allensoa = Muon::ConstHits {muon_hits.data(), n_hits_total_allen};

  size_t n_hits_total_rec = 0;
  for (unsigned station = 0; station < Muon::Constants::n_stations; station++)
    n_hits_total_rec += muon_hit_container.station(station).hits().size();
  debug() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;

  // loop Muon Hits per station and fill hit containers
  for (unsigned station = 0; station < Muon::Constants::n_stations; station++) {
    const auto station_offset = muon_hit_offsets[station];
    const int number_of_hits = muon_hit_offsets[station + 1] - station_offset;
    for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
      const int idx = station_offset + i_hit;
      muon_hits_allen.emplace_back(
        muon_hits_allensoa.x(idx),
        muon_hits_allensoa.dx(idx),
        muon_hits_allensoa.y(idx),
        muon_hits_allensoa.dy(idx),
        muon_hits_allensoa.z(idx),
        muon_hits_allensoa.time(idx),
        muon_hits_allensoa.tile(idx),
        muon_hits_allensoa.uncrossed(idx),
        muon_hits_allensoa.delta_time(idx),
        muon_hits_allensoa.region(idx));
    }
    // LHCb/Rec
    for (const auto& hit : muon_hit_container.station(station).hits()) {
      muon_hits_rec.emplace_back(
        hit.x(),
        hit.dx(),
        hit.y(),
        hit.dy(),
        hit.z(),
        hit.time(),
        hit.tile(),
        hit.uncrossed(),
        hit.deltaTime(),
        hit.region());
    }
  }

  for (const auto& muon_hit_allen : muon_hits_allen) {
    // where is std::erase_if https://en.cppreference.com/w/cpp/container/vector/erase2 ?
    // compare by LHCbID and x position (we mostly care about x, and everything below 1 micon difference is not
    // important for us)
    auto tmp_iter = std::remove_if(muon_hits_rec.begin(), muon_hits_rec.end(), [&muon_hit_allen](auto& muon_hit_rec) {
      return muon_hit_rec.tile == muon_hit_allen.tile && abs(muon_hit_rec.x - muon_hit_allen.x) < 1e-3 &&
             abs(muon_hit_rec.y - muon_hit_allen.y) < 1e-3 && abs(muon_hit_rec.z - muon_hit_allen.z) < 1e-1;
    });
    const auto n_hits_found = std::distance(tmp_iter, muon_hits_rec.end());
    muon_hits_rec.erase(tmp_iter, muon_hits_rec.end());
    if (n_hits_found == 0) {
      error() << "Could not match this Muon Hit decoded by Allen to a Muon hit decoded by Rec" << endmsg;
      error() << muon_hit_allen << endmsg;
    }
    else if (n_hits_found > 1) {
      error() << "This Muon Hit decoded by Allen has multiple Muon hits decoded by Rec" << endmsg;
      error() << muon_hit_allen << endmsg;
    }
    else if (n_hits_found == 1){
      info() << "Successfully matched hit" << muon_hit_allen << endmsg;
    }
  }

  if (!muon_hits_rec.empty()) {
    // error() << "Printing UT hits decoded by Rec that could not be matched to a UT hit in Allen" << endmsg;
    for (const auto& muon_hit_rec : muon_hits_rec)
      error() << "Lonely Rec hit " << muon_hit_rec << endmsg;
  }
}
