/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <CaloFindTwoClusters.cuh>

INSTANTIATE_ALGORITHM(calo_find_twoclusters::calo_find_twoclusters_t)

__device__ void twoclusters(
  Allen::device::span<const CaloCluster> clusters,
  Allen::device::span<const unsigned> clusters1_idx,
  Allen::device::span<const unsigned> clusters2_idx,
  const unsigned num_clusters_idx,
  Allen::device::span<TwoCaloCluster> twoclusters)
{
  for (unsigned c = threadIdx.x; c < num_clusters_idx; c += blockDim.x) {
    const unsigned& cluster1_idx = clusters1_idx[c];
    const unsigned& cluster2_idx = clusters2_idx[c];
    const CaloCluster& cluster1 = clusters[cluster1_idx];
    const CaloCluster& cluster2 = clusters[cluster2_idx];
    twoclusters[c] = TwoCaloCluster(cluster1, cluster2);
  }
}

__global__ void calo_find_twoclusters::calo_find_twoclusters(calo_find_twoclusters::Parameters parameters)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];
  unsigned const ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_twoclusters_offset = parameters.dev_ecal_twocluster_offsets[event_number];
  unsigned const ecal_num_clusters_idx =
    parameters.dev_ecal_twocluster_offsets[event_number + 1] - ecal_twoclusters_offset;

  twoclusters(
    parameters.dev_ecal_clusters.subspan(ecal_clusters_offset),
    parameters.dev_cluster1_idx.subspan(ecal_twoclusters_offset),
    parameters.dev_cluster2_idx.subspan(ecal_twoclusters_offset),
    ecal_num_clusters_idx,
    parameters.dev_ecal_twoclusters.subspan(ecal_twoclusters_offset));
}

void calo_find_twoclusters::calo_find_twoclusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const unsigned n_clusters_idx = first<host_number_of_twoclusters_t>(arguments);
  set_size<dev_ecal_twoclusters_t>(arguments, n_clusters_idx);
}

__host__ void calo_find_twoclusters::calo_find_twoclusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  Allen::Context const& context) const
{
  // Find clusters.
  global_function(calo_find_twoclusters)(
    dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(arguments);
}
