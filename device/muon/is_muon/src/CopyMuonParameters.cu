/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CopyMuonParameters.cuh"
#include "CopyTrackParameters.cuh"

INSTANTIATE_ALGORITHM(copy_muon_parameters::copy_muon_parameters_t)

__global__ void copy_muon_parameters::copy_muon_parameters(copy_muon_parameters::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto event_long_tracks = parameters.dev_multi_event_long_tracks_view->container(event_number);
  const auto endvelo_states = parameters.dev_velo_states_view[event_number];
  const unsigned offset_long_tracks = event_long_tracks.offset();
  const uint8_t* is_muon = parameters.dev_is_muon + offset_long_tracks;
  Checker::Track* muon_checker_tracks_event = parameters.dev_muon_checker_tracks + offset_long_tracks;
   
  prepare_long_tracks(event_long_tracks, endvelo_states, muon_checker_tracks_event);

  prepare_muons(event_long_tracks.size(), muon_checker_tracks_event, is_muon);
}

void copy_muon_parameters::copy_muon_parameters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_checker_tracks_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void copy_muon_parameters::copy_muon_parameters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(copy_muon_parameters)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}