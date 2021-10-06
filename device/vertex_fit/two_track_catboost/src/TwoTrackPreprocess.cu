/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoTrackPreprocess.cuh"

INSTANTIATE_ALGORITHM(two_track_preprocess::two_track_preprocess_t)

void two_track_preprocess::two_track_preprocess_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_two_track_preprocess_output_t>(arguments, 4 * first<host_number_of_svs_t>(arguments));
}

void two_track_preprocess::two_track_preprocess_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(two_track_preprocess)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

/**
 * Loads in and preprocesses data for evaluation by the twoTrack catboost classifier
 * Gets a vector of [sv.sumpt, log10(sv.chi2), log10(sv.fdchi2), sv.ntrks16] for each secondary vertex
 */
__global__ void two_track_preprocess::two_track_preprocess(two_track_preprocess::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - sv_offset;

  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    const unsigned i_out = 4 * (sv_offset + i_sv);
    VertexFit::TrackMVAVertex vertex = parameters.dev_consolidated_svs[sv_offset + i_sv];
    parameters.dev_two_track_preprocess_output[i_out] = vertex.sumpt;
    parameters.dev_two_track_preprocess_output[i_out + 1] = log10f(vertex.chi2);
    parameters.dev_two_track_preprocess_output[i_out + 2] = log10f(vertex.fdchi2);
    parameters.dev_two_track_preprocess_output[i_out + 3] = vertex.ntrks16;
  }
}
