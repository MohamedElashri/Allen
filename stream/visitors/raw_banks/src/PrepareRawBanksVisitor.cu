#include "PrepareRawBanks.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<prepare_raw_banks_t>(
  const prepare_raw_banks_t& state,
  prepare_raw_banks_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_passing_event_list>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_number_of_passing_events>(1);
  arguments.set_size<dev_sel_rb_hits>(host_buffers.host_number_of_reconstructed_scifi_tracks[0] * ParKalmanFilter::nMaxMeasurements);
  arguments.set_size<dev_sel_rb_stdinfo>(host_buffers.host_number_of_selected_events[0] * Hlt1::maxStdInfoEvent);
  arguments.set_size<dev_sel_rb_objtyp>(host_buffers.host_number_of_selected_events[0] * (Hlt1::nObjTyp + 1));
  arguments.set_size<dev_sel_rb_substr>(host_buffers.host_number_of_selected_events[0] * Hlt1::subStrDefaultAllocationSize);
  arguments.set_size<dev_sel_rep_offsets>(2 * host_buffers.host_number_of_selected_events[0] + 1);
}

template<>
void SequenceVisitor::visit<prepare_raw_banks_t>(
  prepare_raw_banks_t& state,
  const prepare_raw_banks_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // Initialize number of events passing Hlt1.
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
  
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rb_hits>(),
    0,
    arguments.size<dev_sel_rb_hits>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rb_stdinfo>(),
    0,
    arguments.size<dev_sel_rb_stdinfo>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rb_objtyp>(),
    0,
    arguments.size<dev_sel_rb_objtyp>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rb_substr>(),
    0,
    arguments.size<dev_sel_rb_substr>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rep_offsets>(),
    0,
    arguments.size<dev_sel_rep_offsets>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_number_of_passing_events>(),
    0,
    arguments.size<dev_number_of_passing_events>(),
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
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_sv_atomics>(),
    arguments.offset<dev_candidate_lists>(),
    arguments.offset<dev_candidate_counts>(),
    arguments.offset<dev_n_svs_saved>(),
    arguments.offset<dev_n_tracks_saved>(),
    arguments.offset<dev_n_hits_saved>(),
    arguments.offset<dev_saved_tracks_list>(),
    arguments.offset<dev_saved_svs_list>(),
    arguments.offset<dev_save_track>(),
    arguments.offset<dev_save_sv>(),
    arguments.offset<dev_dec_reports>(),
    arguments.offset<dev_sel_rb_hits>(),
    arguments.offset<dev_sel_rb_stdinfo>(),
    arguments.offset<dev_sel_rb_objtyp>(),
    arguments.offset<dev_sel_rb_substr>(),
    arguments.offset<dev_sel_rep_offsets>(),
    arguments.offset<dev_number_of_passing_events>(),
    arguments.offset<dev_passing_event_list>());
  state.invoke();
  
  // Copy raw bank data.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_dec_reports,
    arguments.offset<dev_dec_reports>(),
    arguments.size<dev_dec_reports>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  // Copy list of passing events.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_number_of_passing_events,
    arguments.offset<dev_number_of_passing_events>(),
    arguments.size<dev_number_of_passing_events>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_passing_event_list,
    arguments.offset<dev_passing_event_list>(),
    arguments.size<dev_passing_event_list>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
  
}
