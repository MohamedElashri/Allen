#include "MakeNeutralBasicParticles.cuh"

INSTANTIATE_ALGORITHM(make_neutral_basic_particles::make_neutral_particles_t)

void make_neutral_basic_particles::make_neutral_particles_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto n_clusters = first<host_number_of_clusters_t>(arguments);
  set_size<dev_neutral_basic_particle_view_t>(arguments, n_clusters);
  set_size<dev_neutral_basic_particles_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_neutral_particles_view_t>(arguments, 1);
  set_size<dev_multi_event_container_neutral_particles_t>(arguments, 1);
}

void make_neutral_basic_particles::make_neutral_particles_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_neutral_basic_particle_view_t>(arguments, 0, context);
  global_function(make_particles)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

void __global__ make_neutral_basic_particles::make_particles(make_neutral_basic_particles::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;
  const unsigned offset = parameters.dev_ecal_cluster_offsets[event_number];
  const unsigned number_of_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - offset;
  const CaloCluster* event_clusters = parameters.dev_ecal_clusters + offset;

  for (unsigned i = threadIdx.x; i < number_of_clusters; i += blockDim.x) {
    const auto* calo_cluster = event_clusters + i;
    new (parameters.dev_neutral_basic_particle_view + offset + i)
      Allen::Views::Physics::NeutralBasicParticle {calo_cluster};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_neutral_basic_particles_view + event_number) Allen::Views::Physics::NeutralBasicParticles {
      parameters.dev_neutral_basic_particle_view, parameters.dev_ecal_cluster_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_neutral_particles_view) Allen::Views::Physics::MultiEventNeutralBasicParticles {
      parameters.dev_neutral_basic_particles_view, number_of_events};
    parameters.dev_multi_event_container_neutral_particles[0] = parameters.dev_multi_event_neutral_particles_view;
  }
}