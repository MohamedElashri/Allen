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

__global__ void create_twocluster_views(calo_find_twoclusters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned combo_offset = parameters.dev_ecal_twocluster_offsets[event_number];
  const unsigned n_combos = parameters.dev_ecal_twocluster_offsets[event_number + 1] - combo_offset;

  for (unsigned i = threadIdx.x; i < n_combos; i += blockDim.x) {
    new (parameters.dev_twocluster_view + combo_offset + i) Allen::Views::Physics::CompositeParticle {
      parameters.dev_child_pointers[combo_offset + i], nullptr, nullptr, 2, i};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_twoclusters_view + event_number) Allen::Views::Physics::CompositeParticles {
      parameters.dev_twocluster_view, parameters.dev_ecal_twocluster_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_twoclusters_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_twoclusters_view, number_of_events};
    parameters.dev_multi_event_twoclusters_ptr[0] = parameters.dev_multi_event_twoclusters_view;
  }
}

__global__ void calo_find_twoclusters::calo_find_twoclusters(calo_find_twoclusters::Parameters parameters)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];
  unsigned const ecal_twoclusters_offset = parameters.dev_ecal_twocluster_offsets[event_number];
  unsigned const n_cluster_pairs = parameters.dev_ecal_twocluster_offsets[event_number + 1] - ecal_twoclusters_offset;
  const unsigned* event_child1_idx = parameters.dev_cluster1_idx + ecal_twoclusters_offset;
  const unsigned* event_child2_idx = parameters.dev_cluster2_idx + ecal_twoclusters_offset;

  const auto neutral_particles = parameters.dev_neutral_particles->container(event_number);
  for (unsigned i_combo = threadIdx.x; i_combo < n_cluster_pairs; i_combo += blockDim.x) {
    const auto child1 = neutral_particles.particle_pointer(event_child1_idx[i_combo]);
    const auto child2 = neutral_particles.particle_pointer(event_child2_idx[i_combo]);
    parameters.dev_child_pointers[ecal_twoclusters_offset + i_combo] = {child1, child2, nullptr, nullptr};
  }
}

void calo_find_twoclusters::calo_find_twoclusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const unsigned n_clusters = first<host_number_of_twoclusters_t>(arguments);
  set_size<dev_child_pointers_t>(arguments, n_clusters);
  set_size<dev_twocluster_view_t>(arguments, n_clusters);
  set_size<dev_twoclusters_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_twoclusters_view_t>(arguments, 1);
  set_size<dev_multi_event_twoclusters_ptr_t>(arguments, 1);
}

__host__ void calo_find_twoclusters::calo_find_twoclusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  Allen::Context const& context) const
{
  // Find clusters.
  global_function(calo_find_twoclusters)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments);

  // Make views.
  global_function(create_twocluster_views)(
    dim3(first<host_number_of_events_t>(arguments)), dim3(m_block_dim_x), context)(arguments);
}
