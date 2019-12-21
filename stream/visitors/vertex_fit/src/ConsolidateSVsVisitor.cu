#include "SequenceVisitor.cuh"
#include "ConsolidateSVs.cuh"

template<>
void SequenceVisitor::set_arguments_size<consolidate_svs_t>(
  const consolidate_svs_t& state,
  consolidate_svs_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_consolidated_svs>(host_buffers.host_number_of_svs[0]);
}

template<>
void SequenceVisitor::visit<consolidate_svs_t>(
  consolidate_svs_t& state,
  const consolidate_svs_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_sv_atomics>(),
    arguments.offset<dev_secondary_vertices>(),
    arguments.offset<dev_consolidated_svs>());
  state.invoke();

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_secondary_vertices,
      arguments.offset<dev_consolidated_svs>(),
      arguments.size<dev_consolidated_svs>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}