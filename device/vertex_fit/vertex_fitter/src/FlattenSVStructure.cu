/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "FlattenSVStructure.cuh"

INSTANTIATE_ALGORITHM(flatten_svs::flatten_svs_t)

__device__ void fill_sv_info(
  char* base_pointer,
  const unsigned index,
  const float x,
  const float y,
  const float z,
  const float px,
  const float py,
  const float pz)
{
  float* fbase = reinterpret_cast<float*>(base_pointer);
  const unsigned nvrt = Allen::Views::Physics::SecondaryVertex::nb_elements_vrt;
  fbase[nvrt * index] = x;
  fbase[nvrt * index + 1] = y;
  fbase[nvrt * index + 2] = z;
  fbase[nvrt * index + 3] = px;
  fbase[nvrt * index + 4] = py;
  fbase[nvrt * index + 5] = pz;
}

__global__ void flatten_svs::create_flat_views(flatten_svs::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const auto particles = parameters.dev_input_sv_mec->container(event_number);
  const unsigned offset = particles.offset();

  parameters.dev_sv_info_view[event_number] = Allen::Views::Physics::SecondaryVertices {
    parameters.dev_sv_info, parameters.dev_composite_offsets, event_number, number_of_events};

  for (unsigned i = threadIdx.x; i < particles.size(); i += blockDim.x) {
    const auto sv = particles.particle(i);
    std::array<const Allen::Views::Physics::IParticle*, 4> children = {nullptr, nullptr, nullptr, nullptr};
    unsigned i_flat_child = 0;

    // Assume the first child is an SV and the second is a track, which is the
    // output of the SV+track combiner.
    const auto* composite_substr = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
    const unsigned n_subsubstr = composite_substr->number_of_children();
    for (unsigned i_subsubstr = 0; i_subsubstr < n_subsubstr; i_subsubstr++) {
      const auto* subsubstr = composite_substr->child(i_subsubstr);
      children[i_flat_child] = subsubstr;
      i_flat_child++;
    }

    const auto* basic_substr = static_cast<const Allen::Views::Physics::BasicParticle*>(sv.child(1));
    children[i_flat_child] = sv.child(1);
    i_flat_child++;

    // Use the SV position and the SV+track momentum.
    fill_sv_info(
      parameters.dev_sv_info,
      i + offset,
      composite_substr->vertex().x(),
      composite_substr->vertex().y(),
      composite_substr->vertex().z(),
      composite_substr->vertex().px() + basic_substr->state().px(),
      composite_substr->vertex().py() + basic_substr->state().py(),
      composite_substr->vertex().pz() + basic_substr->state().pz());

    // Create the composite view.
    new (parameters.dev_composite_view + offset + i) Allen::Views::Physics::CompositeParticle {
      children, parameters.dev_sv_info_view + event_number, &(sv.pv()), i_flat_child, i};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_composites_view + event_number) Allen::Views::Physics::CompositeParticles {
      parameters.dev_composite_view, parameters.dev_composite_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_composites_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_composites_view, number_of_events};
    parameters.dev_multi_event_composites_ptr[0] = parameters.dev_multi_event_composites_view;
  }
}

void flatten_svs::flatten_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_composite_view_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_composites_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sv_info_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_composites_view_t>(arguments, 1);
  set_size<dev_multi_event_composites_ptr_t>(arguments, 1);
  set_size<dev_sv_info_t>(
    arguments,
    (Allen::Views::Physics::SecondaryVertex::nb_elements_vrt +
     Allen::Views::Physics::SecondaryVertex::nb_elements_cov) *
      sizeof(uint32_t) * first<host_number_of_svs_t>(arguments));
}

void flatten_svs::flatten_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(create_flat_views)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(arguments);
}
