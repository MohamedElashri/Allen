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
  const Constants&,
  const HostBuffers&) const
{
  auto n_scifi_tracks = first<host_number_of_scifi_tracks_t>(arguments);
  set_size<dev_lepton_id_t>(arguments, n_scifi_tracks);
}

void make_lepton_id::make_lepton_id_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(make_lepton_id)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void make_lepton_id::make_lepton_id(make_lepton_id::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto scifi_tracks = parameters.dev_scifi_tracks_view[event_number];
  const unsigned offset = scifi_tracks.offset();
  const unsigned n_tracks = scifi_tracks.size();
  const uint8_t* event_is_muon = parameters.dev_is_muon + offset;
  const uint8_t* event_is_electron = parameters.dev_is_electron + offset;
  uint8_t* event_lepton_id = parameters.dev_lepton_id + offset;
  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    event_lepton_id[i_track] = event_is_muon[i_track] | event_is_electron[i_track];
  }
}