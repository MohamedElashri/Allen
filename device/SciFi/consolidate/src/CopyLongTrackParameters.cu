/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CopyLongTrackParameters.cuh"

INSTANTIATE_ALGORITHM(copy_long_track_parameters::copy_long_track_parameters_t)

__global__ void create_long_tracks_for_checker(copy_long_track_parameters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto event_long_tracks = parameters.dev_multi_event_long_tracks_view->container(event_number);
  const auto number_of_tracks_event = event_long_tracks.size();
  const auto offset_long_tracks = event_long_tracks.offset();
  const auto endvelo_states = parameters.dev_velo_states_view[event_number];
  SciFi::LongCheckerTrack* long_checker_tracks_event = parameters.dev_long_checker_tracks + offset_long_tracks;
  for (unsigned i_track = 0; i_track < number_of_tracks_event; i_track ++) {
      SciFi::LongCheckerTrack t;
      const auto long_track = event_long_tracks.track(i_track);

      const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
      const auto velo_track_index = velo_track.track_index();
      const auto velo_state = endvelo_states.state(velo_track_index);

      // momentum
      const auto qop = long_track.qop();
      t.p = 1.f / std::abs(qop);
      t.qop = qop;
      // direction at first state -> velo state of track
      const double tx = velo_state.tx();
      const double ty = velo_state.ty();
      const double slope2 = tx * tx + ty * ty;
      t.pt = std::sqrt(slope2 / (1.0 + slope2)) / std::abs(qop);
      // pseudorapidity
      const double rho = std::sqrt(slope2);
      t.rho = rho;

      // add all hits
      const auto total_number_of_hits = long_track.number_of_hits();
      t.total_number_of_hits = total_number_of_hits;
      for (unsigned int ihit = 0; ihit < total_number_of_hits; ihit++) {
        const auto id = long_track.get_id(ihit);
        t.allids[ihit] = id;
      }
      long_checker_tracks_event[i_track]=t;
  }
}

void copy_long_track_parameters::copy_long_track_parameters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_long_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void copy_long_track_parameters::copy_long_track_parameters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(create_long_tracks_for_checker)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
  assign_to_host_buffer<dev_long_checker_tracks_t>(host_buffers.host_long_checker_tracks, arguments, context);
}