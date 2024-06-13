/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "VertexDefinitions.cuh"
#include "ParticleTypes.cuh"

/**
 * A CompositeParticleLineWithIndex.
 *
 * It assumes an inheriting class will have the following inputs:
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
 *  DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_svs;
 *  DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
 *  DEVICE_OUTPUT(decisions_t, bool) decisions;
 *
 * It also assumes the OneTrackLine will be defined as:
 *  __device__ bool select(const Parameters& parameters, std::tuple<const Allen::Views::Physics::CompositeParticle,
 * const unsigned) const;
 */
template<typename Derived, typename Parameters>
struct CompositeParticleLineWithIndex : public Line<Derived, Parameters> {

  static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
  {
    return arguments.template first<typename Parameters::host_number_of_svs_t>();
  }

  __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
  {
    const auto particles = parameters.dev_particle_container->container(event_number);
    return particles.offset();
  }

  __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
  {
    const auto particles = parameters.dev_particle_container->container(event_number);
    return particles.size();
  }

  __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
  {
    const auto particles = parameters.dev_particle_container->container(event_number);
    return std::forward_as_tuple(particles.particle(i), particles.offset() + i);
  }
};
