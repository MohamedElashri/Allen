/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"

// Allen
#include "HostBuffers.cuh"
#include "VeloEventModel.cuh"
#include "Logger.h"

class TestVeloClusters final : public Gaudi::Functional::Consumer<void(const HostBuffers&)> {

public:
  /// Standard constructor
  TestVeloClusters(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const HostBuffers&) const override;
};

DECLARE_COMPONENT(TestVeloClusters)

TestVeloClusters::TestVeloClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}})
{}

void TestVeloClusters::operator()(HostBuffers const& host_buffers) const
{
  if (host_buffers.host_number_of_selected_events == 0) return;

  const auto& offsets = host_buffers.velo_clusters_offsets;
  // Single event, but offsets are stored per module pair
  auto const n_clusters = offsets[Velo::Constants::n_module_pairs];
  auto const& module_clusters_num = host_buffers.velo_module_clusters_num;
  auto const& velo_clusters = host_buffers.velo_clusters;

  const auto velo_cluster_container = Velo::ConstClusters {velo_clusters.data(), n_clusters};
  for (unsigned i = 0; i < Velo::Constants::n_module_pairs; ++i) {
    const auto module_hit_start = offsets[i];
    const auto module_hit_num = module_clusters_num[i];

    info() << "Module pair " << i << endmsg;
    for (unsigned hit_number = 0; hit_number < module_hit_num; ++hit_number) {
      const auto hit_index = module_hit_start + hit_number;
      info() << " " << velo_cluster_container.x(hit_index) << ", " << velo_cluster_container.y(hit_index) << ", "
             << velo_cluster_container.z(hit_index) << ", " << velo_cluster_container.id(hit_index) << endmsg;
    }
    info() << endmsg;
  }
}
