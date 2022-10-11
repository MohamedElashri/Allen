/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateMuon.cuh"

#include "Common.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include <string>

INSTANTIATE_ALGORITHM(consolidate_muon::consolidate_muon_t)

void consolidate_muon::consolidate_muon_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_tracks_output_t>(arguments, first<host_muon_total_number_of_tracks_t>(arguments));
}

void consolidate_muon::consolidate_muon_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(consolidate_muon)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments);
}

__global__ void consolidate_muon::consolidate_muon(consolidate_muon::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Input
  auto event_muon_tracks_input =
    parameters.dev_muon_tracks_input + event_number * Muon::Constants::max_number_of_tracks;

  // Output
  auto event_muon_tracks_output = parameters.dev_muon_tracks_output + parameters.dev_muon_tracks_offsets[event_number];

  for (unsigned i_muon_track = threadIdx.x; i_muon_track < parameters.dev_muon_number_of_tracks[event_number];
       i_muon_track += blockDim.x) {
    event_muon_tracks_output[i_muon_track] = event_muon_tracks_input[i_muon_track];
  }
}
