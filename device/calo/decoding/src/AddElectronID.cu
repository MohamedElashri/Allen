/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "AddElectronID.cuh"

INSTANTIATE_ALGORITHM(add_electron_id::add_electron_id_t)

void add_electron_id::add_electron_id_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kf_tracks_with_electron_id_t>(arguments, first<host_number_of_tracks_t>(arguments));
}

void add_electron_id::add_electron_id_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(add_electron_id)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void add_electron_id::add_electron_id(add_electron_id::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned offset = parameters.dev_kf_track_offsets[event_number];
  const unsigned number_of_tracks = parameters.dev_kf_track_offsets[event_number + 1] - offset;
  const ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + offset;
  ParKalmanFilter::FittedTrack* event_tracks_with_id = parameters.dev_kf_tracks_with_electron_id + offset;
  const bool* event_is_electron = parameters.dev_is_electron + offset;

  for (unsigned i_track = threadIdx.x; i_track < number_of_tracks; i_track += blockDim.x) {
    ParKalmanFilter::FittedTrack new_track = event_tracks[i_track];
    new_track.is_electron = event_is_electron[i_track];
    event_tracks_with_id[i_track] = new_track;
  }
}