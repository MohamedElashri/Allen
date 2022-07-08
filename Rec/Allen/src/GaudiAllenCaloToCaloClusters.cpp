/*****************************************************************************\
* (c) Copyright 2008-2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
/**
 * Convert AllenCalo to CaloCluster v2
 *
 * author Dorothea vom Bruch
 *
 */

#include "GaudiAllenCaloToCaloClusters.h"

DECLARE_COMPONENT(GaudiAllenCaloToCaloClusters)

GaudiAllenCaloToCaloClusters::GaudiAllenCaloToCaloClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_ecal_cluster_offsets", ""}, KeyValue {"allen_ecal_clusters", ""}},
    // Outputs
    {KeyValue {"AllenEcalClusters", "Allen/Calo/EcalCluster"}})
{}

LHCb::Event::Calo::Clusters GaudiAllenCaloToCaloClusters::operator()(
  const std::vector<unsigned>& host_ecal_cluster_offsets,
  const std::vector<CaloCluster>& host_ecal_clusters) const
{
  LHCb::Event::Calo::Clusters EcalClusters;
  // Make the clusters
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;

  unsigned number_of_ecal_clusters = host_ecal_cluster_offsets[number_of_events] - host_ecal_cluster_offsets[i_event];

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of Ecal clusters to convert = " << number_of_ecal_clusters << endmsg;
  }

  EcalClusters.reserve(number_of_ecal_clusters);

  // Loop over Allen Ecal clusters and convert them
  // Don't need to access them with offset since one event is processed at a time
  int16_t iFirstEntry = 0;
  for (unsigned i = 0; i < number_of_ecal_clusters; i++) {
    const auto& cluster = host_ecal_clusters[i];

    auto seedCellID = LHCb::Detector::Calo::DenseIndex::details::toCellID(cluster.center_id);

    if (msgLevel(MSG::DEBUG)) {
      for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j) {
        debug() << " " << cluster.digits[j];
        debug() << endmsg;
      }
    }

    // Add the all digits, marking the seed ones

    if (LHCb::Detector::Calo::isValid(seedCellID)) {

      auto clusterOut = EcalClusters.emplace_back<SIMDWrapper::InstructionSet::Scalar>();

      auto entry = clusterOut.entries().emplace_back();
      entry.setCellID(seedCellID);
      entry.setEnergy(cluster.e);
      entry.setFraction(1.f);
      entry.setStatus({LHCb::CaloDigitStatus::Mask::UseForEnergy, LHCb::CaloDigitStatus::Mask::SeedCell});

      auto ncells = 0;
      for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j) {
        if (cluster.digits[j] == USHRT_MAX) continue;
        ncells++;
        auto cellID = LHCb::Detector::Calo::DenseIndex::details::toCellID(cluster.digits[j]);
        if (LHCb::Detector::Calo::isValid(cellID)) {

          auto entry = clusterOut.entries().emplace_back();
          entry.setCellID(cellID);
          entry.setEnergy(0.f);
          entry.setFraction(1.f);
          entry.setStatus({LHCb::CaloDigitStatus::Mask::UseForEnergy, LHCb::CaloDigitStatus::Mask::OwnedCell});
        }
      }

      clusterOut.setCellID(seedCellID);
      clusterOut.setType(LHCb::Event::Calo::Clusters::Type::Area3x3);
      clusterOut.setEnergy(cluster.e);
      clusterOut.setPosition({cluster.x, cluster.y, Calo::Constants::z});

      iFirstEntry += ncells + 1; // seed digit+ associated digits making the cluster
    }
    else if (msgLevel(MSG::DEBUG)) {
      debug() << "ECAL CellID " << seedCellID << " corresponding to dense ID " << cluster.center_id << " is invalid!"
              << endmsg;
      debug() << " \t ECAL center_id = " << cluster.center_id << " cellID: " << seedCellID << ", e = " << cluster.e
              << ", x = " << cluster.x << ", y = " << cluster.y;
    }
  }

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of ecal seed clusters: " << EcalClusters.size() << endmsg;
    uint i = 0;
    for (const auto& Cluster : EcalClusters.scalar()) {
      auto cellID = Cluster.cellID();
      const double e = Cluster.energy();
      const double x = Cluster.position().x();
      const double y = Cluster.position().y();
      const double z = Cluster.position().z();

      if (i % 5 == 0) {
        debug() << "Ecal cellID: " << cellID << " energy = " << e << ", x = " << x << ", y = " << y << ", z = " << z
                << endmsg;
        auto digits = Cluster.entries();
        for (const auto& digit : digits)
          debug() << "     cellID: " << digit.cellID() << " energy: " << digit.energy()
                  << " fraction: " << digit.fraction() << " Status: " << digit.status() << endmsg;
      }
      if (i > 50) break;
      ++i;
    }
  }

  return EcalClusters;
}
