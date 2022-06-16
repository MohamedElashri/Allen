/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"

// Allen
#include "VeloEventModel.cuh"
#include "Logger.h"

class TestVeloClusters final
  : public Gaudi::Functional::Consumer<
      void(const std::vector<unsigned>&, const std::vector<unsigned>&, const std::vector<Velo::Clusters>&)> {

public:
  /// Standard constructor
  TestVeloClusters(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<unsigned>&, const std::vector<unsigned>&, const std::vector<Velo::Clusters>&)
    const override;
};

DECLARE_COMPONENT(TestVeloClusters)

TestVeloClusters::TestVeloClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"offsets_estimated_input_size", ""}, {"module_cluster_num", ""}, {"velo_clusters", ""}})
{}

void TestVeloClusters::operator()(
  const std::vector<unsigned>& offsets,
  const std::vector<unsigned>& module_clusters_num,
  const std::vector<Velo::Clusters>& velo_cluster_container_vector) const
{
  // Single event, but offsets are stored per module pair
  const auto& velo_cluster_container = velo_cluster_container_vector[0];
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
