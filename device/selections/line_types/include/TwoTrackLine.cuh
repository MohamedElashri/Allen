/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "VertexDefinitions.cuh"
#include "ParticleTypes.cuh"
#include "LHCbIDContainer.cuh"

/**
 * A TwoTrackLine.
 *
 * It assumes an inheriting class will have the following inputs:
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
 *  DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_svs;
 *  DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
 *  DEVICE_OUTPUT(decisions_t, bool) decisions;
 *
 * It also assumes the OneTrackLine will be defined as:
 *  __device__ bool select(const Parameters& parameters, std::tuple<const VertexFit::TrackMVAVertex&> input) const;
 */
template<typename Derived, typename Parameters>
struct TwoTrackLine : public Line<Derived, Parameters> {
  constexpr static auto lhcbid_container = LHCbIDContainer::sv;

  static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
  {
    return first<typename Parameters::host_number_of_svs_t>(arguments);
  }

  __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
  {
    return parameters.dev_sv_offsets[event_number];
  }

  __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
  {
    const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles&>(parameters.dev_particle_container[0].particle_container(event_number));
    const auto particle = particles.particle(i);
    return std::forward_as_tuple(particle);
  }
};
