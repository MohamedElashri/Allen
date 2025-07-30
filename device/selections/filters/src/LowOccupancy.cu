/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\************************************************************************/
#include "LowOccupancy.cuh"

INSTANTIATE_ALGORITHM(low_occupancy::low_occupancy_t)

void low_occupancy::low_occupancy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{

  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void low_occupancy::low_occupancy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(low_occupancy)(dim3(1), dim3(m_block_dim_x), context)(
    arguments,
    size<dev_event_list_t>(arguments),
    first<host_number_of_events_t>(arguments),
    m_minTracks,
    m_maxTracks,
    m_max_ecal_clusters,
    m_min_ecal_clusters);
  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void low_occupancy::low_occupancy(
  low_occupancy::Parameters parameters,
  const unsigned number_of_selected_events,
  const unsigned number_of_events,
  const unsigned minTracks,
  const unsigned maxTracks,
  const unsigned max_ecal_clusters,
  const unsigned min_ecal_clusters)
{

  for (unsigned idx = threadIdx.x; idx < number_of_selected_events; idx += blockDim.x) {

    auto event_number = parameters.dev_event_list[idx];
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_offsets_velo_tracks, parameters.dev_offsets_velo_track_hit_number, event_number, number_of_events};
    const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);
    const unsigned ecal_number_of_clusters =
      parameters.dev_ecal_cluster_offsets[event_number + 1] - parameters.dev_ecal_cluster_offsets[event_number];

    if (
      number_of_velo_tracks >= minTracks && number_of_velo_tracks < maxTracks &&
      ecal_number_of_clusters >= min_ecal_clusters && ecal_number_of_clusters < max_ecal_clusters) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}
