#include "VertexFitter.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<fit_secondary_vertices_t>(
  fit_secondary_vertices_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_secondary_vertices>(host_buffers.host_number_of_svs[0]);
}

template<>
void SequenceVisitor::visit<fit_secondary_vertices_t>(
  fit_secondary_vertices_t& state,
  const fit_secondary_vertices_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(16, 16), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_kf_tracks>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_scifi_track_hit_number>(),
    arguments.offset<dev_scifi_qop>(),
    arguments.offset<dev_scifi_states>(),
    arguments.offset<dev_scifi_track_ut_indices>(),
    arguments.offset<dev_multi_fit_vertices>(),
    arguments.offset<dev_number_of_multi_fit_vertices>(),
    arguments.offset<dev_kalman_pv_ipchi2>(),
    arguments.offset<dev_sv_offsets>(),
    arguments.offset<dev_secondary_vertices>());
  state.invoke();

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_secondary_vertices,
      arguments.offset<dev_secondary_vertices>(),
      arguments.size<dev_secondary_vertices>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}