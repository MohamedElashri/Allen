/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CaloFilterClusters.cuh"

INSTANTIATE_ALGORITHM(calo_filter_clusters::calo_filter_clusters_t)

void calo_filter_clusters::calo_filter_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const& n_events = first<host_number_of_events_t>(arguments);

  set_size<dev_cluster_atomics_t>(arguments, n_events);
  set_size<dev_cluster1_idx_t>(arguments, Calo::Constants::max_ndiclusters * n_events);
  set_size<dev_cluster2_idx_t>(arguments, Calo::Constants::max_ndiclusters * n_events);
  set_size<dev_cluster_prefilter_result_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
}

void calo_filter_clusters::calo_filter_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_cluster_atomics_t>(arguments, 0, context);

  global_function(prefilter_clusters)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_prefilter_t>(), context)(arguments);

  global_function(filter_clusters)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_filter_t>(), context)(
    arguments);
}

__global__ void calo_filter_clusters::prefilter_clusters(calo_filter_clusters::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  const CaloCluster* clusters = parameters.dev_ecal_clusters + ecal_clusters_offset;
  const unsigned ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;
  bool* event_prefilter_result = parameters.dev_cluster_prefilter_result + ecal_clusters_offset;

  for (unsigned i_cluster = threadIdx.x; i_cluster < ecal_num_clusters; i_cluster += blockDim.x) {
    const CaloCluster& cluster = clusters[i_cluster];
    const bool dec = cluster.et < parameters.minEt_clusters || cluster.CaloNeutralE19 < parameters.minE19_clusters;
    event_prefilter_result[i_cluster] = dec;
  }
}

__global__ void calo_filter_clusters::filter_clusters(calo_filter_clusters::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = event_number * Calo::Constants::max_ndiclusters;
  unsigned* event_cluster_number = parameters.dev_cluster_atomics + event_number;
  unsigned* event_cluster1_idx = parameters.dev_cluster1_idx + idx_offset;
  unsigned* event_cluster2_idx = parameters.dev_cluster2_idx + idx_offset;

  const unsigned ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  const bool* event_prefilter_result = parameters.dev_cluster_prefilter_result + ecal_clusters_offset;
  const unsigned ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;

  // Loop over clusters.
  for (unsigned i_cluster = threadIdx.x; i_cluster < ecal_num_clusters; i_cluster += blockDim.x) {

    // Filter first cluster.
    if (event_prefilter_result[i_cluster]) continue;

    for (unsigned j_cluster = threadIdx.y + i_cluster + 1; j_cluster < ecal_num_clusters; j_cluster += blockDim.y) {

      // Filter second cluster.
      if (event_prefilter_result[j_cluster]) continue;
      if (*event_cluster_number == Calo::Constants::max_ndiclusters) continue;

      unsigned dicluster_idx = atomicAdd(event_cluster_number, 1);
      event_cluster1_idx[dicluster_idx] = i_cluster;
      event_cluster2_idx[dicluster_idx] = j_cluster;
    }
  }
}
