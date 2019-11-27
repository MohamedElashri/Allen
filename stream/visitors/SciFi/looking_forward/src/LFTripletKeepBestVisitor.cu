#include "LFTripletKeepBest.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_triplet_keep_best_t>(
  const lf_triplet_keep_best_t& state,
  lf_triplet_keep_best_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::maximum_number_of_candidates_per_ut_track);
  arguments.set_size<dev_scifi_lf_atomics>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::num_atomics * 2 + 1);
  arguments.set_size<dev_scifi_lf_total_number_of_found_triplets>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0]);
}

template<>
void SequenceVisitor::visit<lf_triplet_keep_best_t>(
  lf_triplet_keep_best_t& state,
  const lf_triplet_keep_best_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_total_number_of_found_triplets>(),
    0,
    arguments.size<dev_scifi_lf_total_number_of_found_triplets>(),
    cuda_stream));
  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_scifi_lf_atomics>(), 0, arguments.size<dev_scifi_lf_atomics>(), cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.offset<dev_scifi_lf_process_track>(),
    arguments.offset<dev_scifi_lf_found_triplets>(),
    arguments.offset<dev_scifi_lf_number_of_found_triplets>(),
    arguments.offset<dev_scifi_lf_total_number_of_found_triplets>());

  state.invoke();
}
