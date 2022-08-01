#pragma once

#include "Line.cuh"
#include "ParticleTypes.cuh"

template<typename Derived, typename Parameters>
struct CaloClusterLine : public Line<Derived, Parameters> {

  static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
  {
    return arguments.template first<typename Parameters::host_ecal_number_of_clusters_t>();
  }

  __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
  {
    const auto calos = parameters.dev_particle_container->container(event_number);
    return calos.offset();
  }

  __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
  {
    const auto calos = parameters.dev_particle_container->container(event_number);
    return calos.size();
  }

  __device__ static std::tuple<const Allen::Views::Physics::NeutralBasicParticle>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
  {
    const auto calos = parameters.dev_particle_container->container(event_number);
    const auto calo = calos.particle(i);
    return std::forward_as_tuple(calo);
  }
};