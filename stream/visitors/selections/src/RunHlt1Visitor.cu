#include "RunHlt1.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<run_hlt1_t>(
  const run_hlt1_t& state,
  run_hlt1_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_one_track_results>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_two_track_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_single_muon_results>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_disp_dimuon_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_high_mass_dimuon_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_dimuon_soft_results>(host_buffers.host_number_of_svs[0]);
}

template<>
void SequenceVisitor::visit<run_hlt1_t>(
  run_hlt1_t& state,
  const run_hlt1_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_kf_tracks>(),
    arguments.offset<dev_consolidated_svs>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_sv_atomics>(),
    arguments.offset<dev_one_track_results>(),
    arguments.offset<dev_two_track_results>(),
    arguments.offset<dev_single_muon_results>(),
    arguments.offset<dev_disp_dimuon_results>(),
    arguments.offset<dev_high_mass_dimuon_results>(),
    arguments.offset<dev_dimuon_soft_results>());

  state.invoke();

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_one_track_decisions,
      arguments.offset<dev_one_track_results>(),
      arguments.size<dev_one_track_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_two_track_decisions,
      arguments.offset<dev_two_track_results>(),
      arguments.size<dev_two_track_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_single_muon_decisions,
      arguments.offset<dev_single_muon_results>(),
      arguments.size<dev_single_muon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_disp_dimuon_decisions,
      arguments.offset<dev_disp_dimuon_results>(),
      arguments.size<dev_disp_dimuon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_high_mass_dimuon_decisions,
      arguments.offset<dev_high_mass_dimuon_results>(),
      arguments.size<dev_high_mass_dimuon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  cudaCheck(cudaMemcpyAsync(
      host_buffers.host_dimuon_soft_decisions,
      arguments.offset<dev_dimuon_soft_results>(),
      arguments.size<dev_dimuon_soft_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream)); 
  }
}
