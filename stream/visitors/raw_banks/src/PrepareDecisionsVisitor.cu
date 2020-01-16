#include "PrepareDecisions.cuh"
#include "SequenceVisitor.cuh"
#include "ParKalmanDefinitions.cuh"
#include "HltSelReport.cuh"

template<>
void SequenceVisitor::set_arguments_size<prepare_decisions_t>(
  const prepare_decisions_t& state,
  prepare_decisions_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  int n_hlt1_lines = Hlt1::Hlt1Lines::End - 2;
  arguments.set_size<dev_dec_reports>((2 + n_hlt1_lines) * host_buffers.host_number_of_selected_events[0]);

  // This is not technically enough to save every single track, but
  // should be more than enough in practice.
  // TODO: Implement some check for this.
  //printf("N(tracks) = %i\n", host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_candidate_lists>(host_buffers.host_number_of_selected_events[0] * Hlt1::maxCandidates * Hlt1::Hlt1Lines::End);
  arguments.set_size<dev_candidate_counts>(host_buffers.host_number_of_selected_events[0] * Hlt1::Hlt1Lines::End);
  arguments.set_size<dev_saved_tracks_list>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_saved_svs_list>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_save_track>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_save_sv>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_n_tracks_saved>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_n_svs_saved>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_n_hits_saved>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_n_passing_decisions>(host_buffers.host_number_of_selected_events[0]);
}

template<>
void SequenceVisitor::visit<prepare_decisions_t>(
  prepare_decisions_t& state,
  const prepare_decisions_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_candidate_lists>(),
    0,
    arguments.size<dev_candidate_lists>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_candidate_counts>(),
    0,
    arguments.size<dev_candidate_counts>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_dec_reports>(),
    0,
    arguments.size<dev_dec_reports>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_save_track>(),
    -1,
    arguments.size<dev_save_track>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_save_sv>(),
    -1,
    arguments.size<dev_save_sv>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_n_tracks_saved>(),
    0,
    arguments.size<dev_n_tracks_saved>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_n_svs_saved>(),
    0,
    arguments.size<dev_n_svs_saved>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_n_hits_saved>(),
    0,
    arguments.size<dev_n_hits_saved>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_track_hits>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_scifi_track_hit_number>(),
    arguments.offset<dev_scifi_qop>(),
    arguments.offset<dev_scifi_states>(),
    arguments.offset<dev_scifi_track_ut_indices>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_scifi_track_hits>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_kf_tracks>(),
    arguments.offset<dev_consolidated_svs>(),
    arguments.offset<dev_sv_atomics>(),
    arguments.offset<dev_sel_results>(),
    arguments.offset<dev_sel_results_atomics>(),
    arguments.offset<dev_candidate_lists>(),
    arguments.offset<dev_candidate_counts>(),
    arguments.offset<dev_n_passing_decisions>(),
    arguments.offset<dev_n_svs_saved>(),
    arguments.offset<dev_n_tracks_saved>(),
    arguments.offset<dev_n_hits_saved>(),
    arguments.offset<dev_saved_tracks_list>(),
    arguments.offset<dev_saved_svs_list>(),
    arguments.offset<dev_dec_reports>(),
    arguments.offset<dev_save_track>(),
    arguments.offset<dev_save_sv>());
  state.invoke();
  
  // Copy list of passing events.
  /*
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_number_of_passing_events,
    arguments.offset<dev_number_of_passing_events>(),
    //arguments.size<dev_number_of_passing_events>(),
    sizeof(uint),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_passing_event_list,
    arguments.offset<dev_passing_event_list>(),
    arguments.size<dev_passing_event_list>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  */
  
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

}