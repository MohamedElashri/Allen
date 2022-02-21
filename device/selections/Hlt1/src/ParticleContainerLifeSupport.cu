#include "ParticleContainerLifeSupport.cuh"

INSTANTIATE_ALGORITHM(particle_container_life_support::particle_container_life_support_t)

void particle_container_life_support::particle_container_life_support_t::set_arguments_size(
  ArgumentReferences<Parameters>,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  return;
}

void particle_container_life_support::particle_container_life_support_t::operator()(
  const ArgumentReferences<Parameters>&,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  return;
}