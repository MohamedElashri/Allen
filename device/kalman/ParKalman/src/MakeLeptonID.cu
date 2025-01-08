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
#include "MakeLeptonID.cuh"

INSTANTIATE_ALGORITHM(make_lepton_id::make_lepton_id_t)

void make_lepton_id::make_lepton_id_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_scifi_tracks = first<host_number_of_scifi_tracks_t>(arguments);
  set_size<dev_lepton_id_t>(arguments, n_scifi_tracks);
}

void make_lepton_id::make_lepton_id_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(make_lepton_id)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
}

__global__ void make_lepton_id::make_lepton_id(make_lepton_id::Parameters parameters)
{
  if (const auto long_tracks =
        Allen::dyn_cast<const Allen::Views::Physics::MultiEventLongTracks*>(*parameters.dev_tracks_view);
      long_tracks) {
    make_lepton_id_implementation<Allen::Views::Physics::MultiEventLongTracks>(parameters, long_tracks);
  }
  else if (const auto downstream_tracks =
             Allen::dyn_cast<const Allen::Views::Physics::MultiEventDownstreamTracks*>(*parameters.dev_tracks_view);
           downstream_tracks) {
    make_lepton_id_implementation<Allen::Views::Physics::MultiEventDownstreamTracks>(parameters, downstream_tracks);
  }
  else {
    // This flag tell compile this code it not reachable, so it will optimze with it
    Allen::unreachable();
  }
}

template<typename MultiEventTracks>
__device__ void make_lepton_id::make_lepton_id_implementation(
  make_lepton_id::Parameters parameters,
  const MultiEventTracks* dev_long_tracks_view)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // Long tracks.
  const auto long_tracks = dev_long_tracks_view->container(event_number);
  const unsigned n_tracks = long_tracks.size();
  const unsigned offset = long_tracks.offset();
  const auto* event_is_muon = parameters.dev_is_muon + offset;
  const auto* event_is_electron = parameters.dev_is_electron + offset;
  auto* event_lepton_id = parameters.dev_lepton_id + offset;
  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    event_lepton_id[i_track] = event_is_muon[i_track] | (event_is_electron[i_track] << 1);
  }
}