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
 * Convert AllenCalo to CaloCluster
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenCaloToCaloClusters.h"

DECLARE_COMPONENT(AllenCaloToCaloClusters)

AllenCaloToCaloClusters::AllenCaloToCaloClusters(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputCalo", "Allen/Calo/CaloCluster"}})
{}

std::vector<LHCb::CaloCluster> AllenCaloToCaloClusters::operator()(const HostBuffers& host_buffers) const
{
  // avoid long names
  // using namespace LHCb::CaloDataFunctor;
  //  typedef LHCb::CaloClusters Clusters;
  std::vector<LHCb::CaloCluster> Clusters;
  // Make the clusters
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  //  const CaloCluster::CaloCluster allen_caloclusters

  unsigned number_of_ecal_clusters = host_buffers.host_ecal_cluster_offsets[number_of_events] - host_buffers.host_ecal_cluster_offsets[i_event]; 
  unsigned number_of_hcal_clusters = host_buffers.host_hcal_cluster_offsets[number_of_events] - host_buffers.host_hcal_cluster_offsets[i_event];
  CaloCluster* ecal_clusters = (CaloCluster*)(host_buffers.host_ecal_clusters.data());
  CaloCluster* hcal_clusters = (CaloCluster*)(host_buffers.host_hcal_clusters.data());

  if (msgLevel(MSG::DEBUG)) {
    debug() << "Number of Ecal clusters to convert = " << number_of_ecal_clusters << endmsg;
    debug() << "Number of Hcal clusters to convert = " << number_of_hcal_clusters << endmsg;
  }

  // Loop over Allen clusters and convert them
  // Don't need to access them with offset since one event is processed at a time
  for (unsigned i = 0; i < number_of_ecal_clusters; i++) {
    const auto& cluster = ecal_clusters[i];
    if (msgLevel(MSG::DEBUG)) {
      debug() << " \t ECAL center_id = " << cluster.center_id << ", e = " << cluster.e << ", x = " << cluster.x << ", y = " << cluster.y << endmsg;
    }
  } 
  
  for (unsigned i = 0; i < number_of_hcal_clusters; i++) {
    const auto& cluster = hcal_clusters[i];
    if (msgLevel(MSG::DEBUG)) {
      debug() << " \t HCAL center_id = " << cluster.center_id << ", e = " << cluster.e << ", x = " << cluster.x << ", y = " << cluster.y << endmsg;
    }
  } 

 
  return Clusters;
}
