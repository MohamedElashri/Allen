#include "SequenceVisitor.cuh"
#include "ConsolidateUT.cuh"

template<>
void SequenceVisitor::set_arguments_size<consolidate_ut_tracks_t>(
  consolidate_ut_tracks_t& state,
  consolidate_ut_tracks_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_ut_track_hits>(host_buffers.host_accumulated_number_of_ut_hits[0] * sizeof(UT::Hit));
  arguments.set_size<dev_ut_qop>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_track_velo_indices>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_x>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_z>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_tx>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
}

template<>
void SequenceVisitor::visit<consolidate_ut_tracks_t>(
  consolidate_ut_tracks_t& state,
  const consolidate_ut_tracks_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_ut_hits>(),
    arguments.offset<dev_ut_hit_offsets>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_x>(),
    arguments.offset<dev_ut_tx>(),
    arguments.offset<dev_ut_z>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_ut_tracks>(),
    constants.dev_unique_x_sector_layer_offsets.data());

  state.invoke();

  if (runtime_options.do_check) {
    // Transmission device to host of UT consolidated tracks
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_atomics_ut,
      arguments.offset<dev_atomics_ut>(),
      (2 * host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_hit_number,
      arguments.offset<dev_ut_track_hit_number>(),
      arguments.size<dev_ut_track_hit_number>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_hits,
      arguments.offset<dev_ut_track_hits>(),
      host_buffers.host_accumulated_number_of_hits_in_ut_tracks[0] * sizeof(UT::Hit),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_qop,
      arguments.offset<dev_ut_qop>(),
      arguments.size<dev_ut_qop>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_x,
      arguments.offset<dev_ut_x>(),
      arguments.size<dev_ut_x>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_tx,
      arguments.offset<dev_ut_tx>(),
      arguments.size<dev_ut_tx>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_z,
      arguments.offset<dev_ut_z>(),
      arguments.size<dev_ut_z>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_velo_indices,
      arguments.offset<dev_ut_track_velo_indices>(),
      arguments.size<dev_ut_track_velo_indices>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}
