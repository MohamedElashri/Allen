/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"

// LHCb
#include "Event/FTLiteCluster.h"
#include "FTDAQ/FTInfo.h"
#include "Kernel/LHCbID.h"

// Allen
#include "SciFiEventModel.cuh"
#include "Logger.h"

class TestFTClusters final
  : public Gaudi::Functional::Consumer<
      void(const std::vector<unsigned>&, const std::vector<char>&, const LHCb::FTLiteCluster::FTLiteClusters&)> {

public:
  /// Standard constructor
  TestFTClusters(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<unsigned>&, const std::vector<char>&, const LHCb::FTLiteCluster::FTLiteClusters&)
    const override;
};

DECLARE_COMPONENT(TestFTClusters)

TestFTClusters::TestFTClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"scifi_offsets", ""},
     KeyValue {"scifi_hits", ""},
     KeyValue {"FTClusterLocation", LHCb::FTLiteClusterLocation::Default}})
{}

void TestFTClusters::operator()(
  const std::vector<unsigned>& scifi_offsets,
  const std::vector<char>& scifi_hits,
  LHCb::FTLiteCluster::FTLiteClusters const& ft_lite_clusters) const
{

  // the goal is to compare SciFiChannelIDs of individual hits from data decoded with HLT1 and HLT2.
  std::vector<uint32_t> scifi_ids_allen, scifi_ids_rec;

  // read in offsets and hits from the buffer
  const unsigned n_hits_total_allen = scifi_offsets[SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHits scifi_hits_allensoa(scifi_hits.data(), n_hits_total_allen);

  const auto n_hits_total_rec = ft_lite_clusters.size();
  info() << "Number of FT clusters (Allen) in this event " << n_hits_total_allen << endmsg;
  info() << "Number of FT clusters (Rec) in this event   " << n_hits_total_rec << endmsg;

  // HLT1: loop module pairs and fill hit container
  for (unsigned i = scifi_offsets[0]; i < n_hits_total_allen; ++i)
    scifi_ids_allen.emplace_back(scifi_hits_allensoa.id(i));

  // HLT2: loop cluster hits and fill hit container
  for (unsigned i {0}; i < PrFTInfo::NFTZones; ++i)
    for (int quarter = 0; quarter < 2; quarter++)
      for (auto const& clus : ft_lite_clusters.range(i * 2 + quarter))
        scifi_ids_rec.emplace_back(LHCb::LHCbID {LHCb::LHCbID::channelIDtype::FT, clus.channelID()}.lhcbID());

  for (const auto& cluster_id_allen : scifi_ids_allen) {
    auto tmp_iter =
      std::remove_if(scifi_ids_rec.begin(), scifi_ids_rec.end(), [&cluster_id_allen](auto& cluster_id_rec) {
        return cluster_id_rec == cluster_id_allen;
      });
    const auto n_hits_found = std::distance(tmp_iter, scifi_ids_rec.end());
    scifi_ids_rec.erase(tmp_iter, scifi_ids_rec.end());
    if (n_hits_found == 0) {
      error() << "Could not match this VP cluster decoded by Allen to a VP cluster decoded by Rec" << endmsg;
      error() << cluster_id_allen << endmsg;
    }
    else if (n_hits_found > 1) {
      error() << "This VP cluster decoded by Allen has multiple VP clusters decoded by Rec" << endmsg;
      error() << cluster_id_allen << endmsg;
    }
  }

  if (!scifi_ids_rec.empty()) {
    for (const auto& ft_cluster_rec : scifi_ids_rec) {
      error() << "Lonely Rec hit " << ft_cluster_rec << endmsg;
    }
  }
}
