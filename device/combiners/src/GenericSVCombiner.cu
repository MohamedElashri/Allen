/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "GenericSVCombiner.cuh"

INSTANTIATE_ALGORITHM(GenericSVCombiner::generic_sv_combiner_t)

__global__ void create_combo_views(GenericSVCombiner::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned combo_offset = parameters.dev_combo_offsets[event_number];
  const unsigned n_combos = parameters.dev_combo_offsets[event_number + 1] - combo_offset;

  for (unsigned i = threadIdx.x; i < n_combos; i += blockDim.x) {
    new (parameters.dev_combo_view + combo_offset + i) Allen::Views::Physics::CompositeParticle {
      parameters.dev_child_pointers[combo_offset + i], nullptr, nullptr, 2, i};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_combos_view + event_number)
      Allen::Views::Physics::CompositeParticles {parameters.dev_combo_view, parameters.dev_combo_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_combos_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_combos_view, number_of_events};
    parameters.dev_multi_event_combos_ptr[0] = parameters.dev_multi_event_combos_view;
  }
}

void GenericSVCombiner::generic_sv_combiner_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_child_pointers_t>(arguments, first<host_number_of_combos_t>(arguments));
  set_size<dev_combo_view_t>(arguments, first<host_number_of_combos_t>(arguments));
  set_size<dev_combos_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_combos_view_t>(arguments, 1);
  set_size<dev_multi_event_combos_ptr_t>(arguments, 1);
}

void GenericSVCombiner::generic_sv_combiner_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(combine_generic_svs)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_filter, context)(arguments);

  global_function(create_combo_views)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim_filter, context)(
    arguments);
}

__global__ void GenericSVCombiner::combine_generic_svs(GenericSVCombiner::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned combo_offset = parameters.dev_combo_offsets[event_number];
  const unsigned n_combos = parameters.dev_combo_offsets[event_number + 1] - combo_offset;
  const unsigned idx_offset = parameters.dev_max_combo_offsets[event_number];
  const unsigned* event_child1_idx = parameters.dev_child1_idx + idx_offset;
  const unsigned* event_child2_idx = parameters.dev_child2_idx + idx_offset;

  // Secondary Vertices
  const auto svs1 = parameters.dev_secondary_vertices_1->container(event_number);
  const auto svs2 = parameters.dev_secondary_vertices_2->container(event_number);
  for (unsigned i_combo = threadIdx.x; i_combo < n_combos; i_combo += blockDim.x) {
    const auto child1 = svs1.particle_pointer(event_child1_idx[i_combo]);
    const auto child2 = svs2.particle_pointer(event_child2_idx[i_combo]);

    parameters.dev_child_pointers[combo_offset + i_combo] = {child1, child2, nullptr, nullptr};
  }
}
