/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "LHCbIDContainer.cuh"
#include "ParKalmanFilter.cuh"
#include "ParticleTypes.cuh"

/**
 * A OneTrackLine.
 *
 * It assumes an inheriting class will have the following inputs:
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
 *  DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_tracks;
 *  DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
 *
 * It also assumes the OneTrackLine will be defined as:
 *  __device__ bool select(const Parameters& parameters, std::tuple<const Allen::Views::Physics::BasicParticle> input)
 * const;
 */
template<typename Derived, typename Parameters>
struct OneTrackLine : public Line<Derived, Parameters> {
  constexpr static auto lhcbid_container = LHCbIDContainer::track;

  static unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) { return 64; }

  static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
  {
    return first<typename Parameters::host_number_of_reconstructed_scifi_tracks_t>(arguments);
  }

  __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
  {
    const auto tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(parameters.dev_particle_container[0].particle_container(event_number));
    return tracks.offset();
  }

  __device__ static std::tuple<const Allen::Views::Physics::BasicParticle>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
  {
    const auto tracks = static_cast<const Allen::Views::Physics::BasicParticles&>(parameters.dev_particle_container[0].particle_container(event_number));
    const auto track = tracks.particle(i);
    return std::forward_as_tuple(track);
  }
};
