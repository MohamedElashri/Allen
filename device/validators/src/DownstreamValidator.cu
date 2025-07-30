/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamValidator.cuh"
#include "CopyTrackParameters.cuh"
#include "UTEventModel.cuh"
#include <fstream>

INSTANTIATE_ALGORITHM(downstream_validator::downstream_validator_t)

__global__ void downstream_validator::downstream_validator(downstream_validator::Parameters parameters)
{
  // Basic
  const unsigned event_number = blockIdx.x;

  // Read downstream result
  const auto downstream_tracks = parameters.dev_multi_event_downstream_tracks_view->container(event_number);
  auto downstream_checker_tracks = parameters.dev_downstream_checker_tracks + downstream_tracks.offset();
  prepare_downstream_tracks(
    downstream_tracks, parameters.dev_downstream_track_states_view[event_number], downstream_checker_tracks);
  __syncthreads();
}

void downstream_validator::downstream_validator_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_downstream_checker_tracks_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
}

void downstream_validator::downstream_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(downstream_validator)(first<host_number_of_events_t>(arguments), m_block_dim, context)(arguments);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto downstream_tracks_for_checker = make_host_buffer<dev_downstream_checker_tracks_t>(arguments, context);
  const auto event_tracks_offsets = make_host_buffer<dev_offsets_downstream_tracks_t>(arguments, context);

  std::vector<Checker::Tracks> tracks;
  tracks.resize(event_list.size());
  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto event_offset = event_tracks_offsets[evnum];
    const auto n_tracks = event_tracks_offsets[evnum + 1] - event_offset;
    std::vector<Checker::Track> event_trakcs = {downstream_tracks_for_checker.begin() + event_offset,
                                                downstream_tracks_for_checker.begin() + event_offset + n_tracks};
    tracks[i] = event_trakcs;
  }

  auto& checker = runtime_options.checker_invoker->checker<TrackCheckerDownstream>(name(), m_root_output_filename);
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list);
}
