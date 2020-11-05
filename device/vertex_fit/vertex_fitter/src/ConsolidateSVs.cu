/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSVs.cuh"

void consolidate_svs::consolidate_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_consolidated_svs_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void consolidate_svs::consolidate_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(consolidate_svs)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), stream)(
    arguments);

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_consolidated_svs_t>(host_buffers.host_secondary_vertices, arguments, stream);
    assign_to_host_buffer<dev_sv_offsets_t>(host_buffers.host_sv_atomics, arguments, stream);
  }
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