/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CaloPreFilterClusters.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(calo_prefilter_clusters::calo_prefilter_clusters_t)

void calo_prefilter_clusters::calo_prefilter_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const& n_events = first<host_number_of_events_t>(arguments);

  set_size<dev_num_prefiltered_clusters_t>(arguments, n_events);
  set_size<dev_ecal_twocluster_offsets_t>(arguments, n_events + 1);
  set_size<host_total_sum_holder_t>(arguments, 1);
  set_size<dev_prefiltered_clusters_idx_t>(arguments, first<host_ecal_number_of_neutral_clusters_t>(arguments));
}

void calo_prefilter_clusters::calo_prefilter_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_num_prefiltered_clusters_t>(arguments, 0, context);

  global_function(calo_prefilter_clusters)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_prefilter, context)(
    arguments, m_minEt_clusters, m_minE19_clusters);

  global_function(count_twoclusters)(1, dim3(64), context)(arguments);

  PrefixSum::prefix_sum<dev_ecal_twocluster_offsets_t, host_total_sum_holder_t>(*this, arguments, context);
}

__global__ void calo_prefilter_clusters::calo_prefilter_clusters(
  calo_prefilter_clusters::Parameters parameters,
  const float minEt_clusters,
  const float minE19_clusters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto event_neutral_particles = parameters.dev_neutral_particles->container(event_number);
  const unsigned ecal_clusters_offset = event_neutral_particles.offset();
  const unsigned ecal_num_clusters = event_neutral_particles.size();
  unsigned* prefiltered_clusters_idx = parameters.dev_prefiltered_clusters_idx + ecal_clusters_offset;
  unsigned* num_prefiltered_clusters = parameters.dev_num_prefiltered_clusters + event_number;

  __shared__ unsigned num_prefiltered_clusters_shared;
  if (threadIdx.x == 0) {
    num_prefiltered_clusters_shared = 0u;
  }
  __syncthreads();

  for (unsigned i_cluster = threadIdx.x; i_cluster < ecal_num_clusters; i_cluster += blockDim.x) {
    const auto particle = event_neutral_particles.particle(i_cluster);
    const auto cluster = particle.cluster();
    if (cluster.et > minEt_clusters && cluster.CaloNeutralE19 > minE19_clusters) {
      const unsigned idx = atomicAdd(&num_prefiltered_clusters_shared, 1);
      prefiltered_clusters_idx[idx] = i_cluster;
    }
  }

  __syncthreads();
  if (threadIdx.x == 0) {
    *num_prefiltered_clusters = num_prefiltered_clusters_shared;
  }
}

__global__ void calo_prefilter_clusters::count_twoclusters(calo_prefilter_clusters::Parameters parameters)
{
  const unsigned n_events = parameters.dev_number_of_events[0];
  unsigned* num_prefiltered_clusters = parameters.dev_num_prefiltered_clusters;
  unsigned* ecal_num_twoclusters = parameters.dev_ecal_twocluster_offsets;

  for (unsigned i_event = threadIdx.x; i_event < n_events; i_event += blockDim.x) {
    const unsigned n = num_prefiltered_clusters[i_event];
    ecal_num_twoclusters[i_event] = (n * (n - 1)) / 2;
  }
}
