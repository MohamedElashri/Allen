/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ConsolidateSVs.cuh"

INSTANTIATE_ALGORITHM(consolidate_svs::consolidate_svs_t)

void consolidate_svs::consolidate_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_consolidated_svs_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void consolidate_svs::consolidate_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(consolidate_svs)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(arguments);
}

__global__ void consolidate_svs::consolidate_svs(consolidate_svs::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const unsigned fitted_sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned sv_offset = event_number * VertexFit::max_svs;
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];
  const VertexFit::TrackMVAVertex* event_svs = parameters.dev_secondary_vertices + sv_offset;
  VertexFit::TrackMVAVertex* event_consolidated_svs = parameters.dev_consolidated_svs + fitted_sv_offset;

  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_consolidated_svs[i_sv] = event_svs[i_sv];
  }
}
