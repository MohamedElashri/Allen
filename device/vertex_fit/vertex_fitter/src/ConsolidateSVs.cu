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
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(consolidate_svs)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_secondary_vertices,
      data<dev_consolidated_svs_t>(arguments),
      size<dev_consolidated_svs_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_sv_atomics,
      data<dev_sv_offsets_t>(arguments),
      size<dev_sv_offsets_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

__global__ void consolidate_svs::consolidate_svs(consolidate_svs::Parameters parameters)
{
  const uint event_number = blockIdx.x;
  const uint fitted_sv_offset = parameters.dev_sv_offsets[event_number];
  const uint sv_offset = event_number * VertexFit::max_svs;
  const uint n_svs = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];
  const VertexFit::TrackMVAVertex* event_svs = parameters.dev_secondary_vertices + sv_offset;
  VertexFit::TrackMVAVertex* event_consolidated_svs = parameters.dev_consolidated_svs + fitted_sv_offset;

  for (uint i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_consolidated_svs[i_sv] = event_svs[i_sv];
  }
}