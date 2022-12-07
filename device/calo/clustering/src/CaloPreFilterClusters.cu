/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CaloPreFilterClusters.cuh"

INSTANTIATE_ALGORITHM(calo_prefilter_clusters::calo_prefilter_clusters_t)

void calo_prefilter_clusters::calo_prefilter_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const& n_events = first<host_number_of_events_t>(arguments);

  set_size<dev_num_prefiltered_clusters_t>(arguments, n_events);
  set_size<dev_ecal_num_twoclusters_t>(arguments, n_events);
  set_size<dev_prefiltered_clusters_idx_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
}

void calo_prefilter_clusters::calo_prefilter_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_num_prefiltered_clusters_t>(arguments, 0, context);

  global_function(calo_prefilter_clusters)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_prefilter_t>(), context)(arguments);

  global_function(count_twoclusters)(1, dim3(64), context)(arguments);
}

__global__ void calo_prefilter_clusters::calo_prefilter_clusters(calo_prefilter_clusters::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  const CaloCluster* clusters = parameters.dev_ecal_clusters + ecal_clusters_offset;
  const unsigned ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;
  unsigned* prefiltered_clusters_idx = parameters.dev_prefiltered_clusters_idx + ecal_clusters_offset;
  unsigned* num_prefiltered_clusters = parameters.dev_num_prefiltered_clusters + event_number;

  for (unsigned i_cluster = threadIdx.x; i_cluster < ecal_num_clusters; i_cluster += blockDim.x) {
    const CaloCluster& cluster = clusters[i_cluster];
    if (cluster.et > parameters.minEt_clusters && cluster.CaloNeutralE19 > parameters.minE19_clusters) {
      const unsigned idx = atomicAdd(num_prefiltered_clusters, 1);
      prefiltered_clusters_idx[idx] = i_cluster;
    }
  }
}

__global__ void calo_prefilter_clusters::count_twoclusters(calo_prefilter_clusters::Parameters parameters)
{
  const unsigned n_events = parameters.dev_number_of_events[0];
  unsigned* num_prefiltered_clusters = parameters.dev_num_prefiltered_clusters;
  unsigned* ecal_num_twoclusters = parameters.dev_ecal_num_twoclusters;

  for (unsigned i_event = threadIdx.x; i_event < n_events; i_event += blockDim.x) {
    const unsigned n = num_prefiltered_clusters[i_event];
    ecal_num_twoclusters[i_event] = (n * (n - 1)) / 2;
  }
}
