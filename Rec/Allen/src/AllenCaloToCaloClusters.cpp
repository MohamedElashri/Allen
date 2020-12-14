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

/**
 * Convert AllenCalo to CaloCluster v2
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenCaloToCaloClusters.h"

DECLARE_COMPONENT(AllenCaloToCaloClusters)

AllenCaloToCaloClusters::AllenCaloToCaloClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"AllenEcalClusters", "Allen/Calo/EcalCluster"},
     KeyValue {"AllenHcalClusters", "Allen/Calo/HcalCluster"}})
{}

std::tuple<LHCb::Event::Calo::Clusters, LHCb::Event::Calo::Clusters> AllenCaloToCaloClusters::operator()(
  const HostBuffers& host_buffers) const
{
  // avoid long names
  // using namespace LHCb::CaloDataFunctor;
  LHCb::Event::Calo::Clusters EcalClusters;
  LHCb::Event::Calo::Clusters HcalClusters;
  // Make the clusters
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;

  unsigned number_of_ecal_clusters =
    host_buffers.host_ecal_cluster_offsets[number_of_events] - host_buffers.host_ecal_cluster_offsets[i_event];
  unsigned number_of_hcal_clusters =
    host_buffers.host_hcal_cluster_offsets[number_of_events] - host_buffers.host_hcal_cluster_offsets[i_event];
  CaloCluster* ecal_clusters = (CaloCluster*) (host_buffers.host_ecal_clusters.data());
  CaloCluster* hcal_clusters = (CaloCluster*) (host_buffers.host_hcal_clusters.data());

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of Ecal clusters to convert = " << number_of_ecal_clusters << endmsg;
    debug() << "Number of Hcal clusters to convert = " << number_of_hcal_clusters << endmsg;
  }

  EcalClusters.reserveForEntries(number_of_ecal_clusters);
  HcalClusters.reserveForEntries(number_of_hcal_clusters);

  // Loop over Allen Ecal clusters and convert them
  // Don't need to access them with offset since one event is processed at a time
  int16_t iFirstEntry = 0;
  for (unsigned i = 0; i < number_of_ecal_clusters; i++) {
    const auto& cluster = ecal_clusters[i];

    auto seedCellID = LHCb::Calo::DenseIndex::details::toCellID(cluster.center_id);

    if (msgLevel(MSG::DEBUG) && i < 50 && i % 5 == 0) {
      if (LHCb::Calo::isValid(seedCellID))
        debug() << "ECAL CellID " << seedCellID << " corresponding to dense ID " << cluster.center_id << " is invalid!"
                << endmsg;
      debug() << " \t ECAL center_id = " << cluster.center_id << " cellID: " << seedCellID << ", e = " << cluster.e
              << ", x = " << cluster.x << ", y = " << cluster.y;
      for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j)
        debug() << " " << cluster.digits[j];
      debug() << endmsg;
    }

    // Add the all digits, marking the seed ones
    EcalClusters.emplace_back(seedCellID, cluster.e, 1.0, LHCb::CaloDigitStatus::Mask::SeedCell);
    for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j) {
      auto cellID = LHCb::Calo::DenseIndex::details::toCellID(cluster.digits[j]);
      EcalClusters.emplace_back(cellID, 0., 1.0, LHCb::CaloDigitStatus::Mask::OwnedCell);
    }
    LHCb::Event::Calo::v2::Clusters::which_entries_t entries {iFirstEntry, Calo::Constants::max_neighbours + 1};
    Gaudi::XYZPoint position {cluster.x, cluster.y, 0.};

    EcalClusters.emplace_back(seedCellID, LHCb::Event::Calo::Clusters::Type::Area3x3, entries, cluster.e, position);

    iFirstEntry += Calo::Constants::max_neighbours + 1; // seed digit+ associated digits making the cluster
  }

  // Loop over Allen Hcal clusters and convert them

  iFirstEntry = 0;
  for (unsigned i = 0; i < number_of_hcal_clusters; i++) {
    const auto& cluster = hcal_clusters[i];

    auto seedCellID = LHCb::Calo::DenseIndex::details::toCellID(cluster.center_id);

    if (msgLevel(MSG::DEBUG) && i < 50 && i % 5 == 0) {
      if (LHCb::Calo::isValid(seedCellID))
        debug() << "HCAL CellID " << seedCellID << " corresponding to dense ID " << cluster.center_id << " is invalid!"
                << endmsg;
      debug() << " \t HCAL center_id = " << cluster.center_id << " cellID: " << seedCellID << ", e = " << cluster.e
              << ", x = " << cluster.x << ", y = " << cluster.y;
      for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j)
        debug() << " " << cluster.digits[j];
      debug() << endmsg;
    }

    // Add the all digits, marking the seed ones
    HcalClusters.emplace_back(seedCellID, cluster.e, LHCb::CaloDigitStatus::Mask::SeedCell);
    for (unsigned j = 0; j < Calo::Constants::max_neighbours; ++j) {
      auto cellID = LHCb::Calo::DenseIndex::details::toCellID(cluster.digits[j]);
      HcalClusters.emplace_back(cellID, .0, LHCb::CaloDigitStatus::Mask::OwnedCell);
    }
    LHCb::Event::Calo::v2::Clusters::which_entries_t entries {iFirstEntry, Calo::Constants::max_neighbours + 1};
    Gaudi::XYZPoint position {cluster.x, cluster.y, 0.};

    HcalClusters.emplace_back(seedCellID, LHCb::Event::Calo::Clusters::Type::Area3x3, entries, cluster.e, position);

    iFirstEntry += Calo::Constants::max_neighbours + 1; // seed digit+ associated digits making the cluster
  }
  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of ecal seed clusters: " << EcalClusters.size() << endmsg;
    uint i = 0;
    for (const auto& Cluster : EcalClusters) {
      auto cellID = Cluster.cellID();
      const double e = Cluster.energy();
      const double x = Cluster.position().x();
      const double y = Cluster.position().y();
      const double z = Cluster.position().z();
      // const double et = e * sqrt( x * x + y * y ) / sqrt( x * x + y * y + z * z );

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
    debug() << "Number of hcal seed clusters: " << HcalClusters.size() << endmsg;
    i = 0;
    for (const auto& Cluster : HcalClusters) {
      auto cellID = Cluster.cellID();
      const double e = Cluster.energy();
      const double x = Cluster.position().x();
      const double y = Cluster.position().y();
      const double z = Cluster.position().z();
      // const double et = e * sqrt( x * x + y * y ) / sqrt( x * x + y * y + z * z );

      if (i % 5 == 0) {
        debug() << "Hcal cellID: " << cellID << " energy = " << e << ", x = " << x << ", y = " << y << ", z = " << z
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

  return {EcalClusters, HcalClusters};
}
