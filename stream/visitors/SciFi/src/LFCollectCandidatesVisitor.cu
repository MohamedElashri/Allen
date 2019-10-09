#include "LFCollectCandidates.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_collect_candidates_t>(
  lf_collect_candidates_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_number_of_candidates>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::number_of_x_layers + 1);

  arguments.set_size<dev_scifi_lf_candidates>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::number_of_x_layers *
    LookingForward::maximum_number_of_candidates);
}

template<>
void SequenceVisitor::visit<lf_collect_candidates_t>(
  lf_collect_candidates_t& state,
  const lf_collect_candidates_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    0,
    arguments.size<dev_scifi_lf_number_of_candidates>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(64, 6), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>());

  state.invoke();
}
