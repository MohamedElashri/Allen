#include "LFCompositeTrackSeeding.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_composite_track_seeding_t>(
  lf_composite_track_seeding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_triplet_best>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * 4 * LookingForward::maximum_number_of_candidates *
    LookingForward::maximum_number_of_triplets_per_h1);
  arguments.set_size<dev_scifi_lf_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::maximum_number_of_candidates_per_ut_track);
  arguments.set_size<dev_scifi_lf_atomics>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::num_atomics * 2 + 1);
}

template<>
void SequenceVisitor::visit<lf_composite_track_seeding_t>(
  lf_composite_track_seeding_t& state,
  const lf_composite_track_seeding_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.handler_lf_triplet_seeding.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_qop>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>(),
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_triplet_best>());

  state.handler_lf_triplet_keep_best.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_states>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_candidates>(),
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_triplet_best>());

  state.handler_lf_extend_tracks_x.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>());

  state.handler_lf_triplet_seeding.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0]), dim3(32), cuda_stream);
  state.handler_lf_triplet_keep_best.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0], 4), dim3(32), cuda_stream);
  state.handler_lf_extend_tracks_x.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0]), dim3(32, 4), cuda_stream);

  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_scifi_lf_atomics>(), 0, arguments.size<dev_scifi_lf_atomics>(), cuda_stream));

  // Note: The initialization of dev_scifi_lf_triplet_best_chi2 is the highest positive
  //       number represented as fp32 that can be initialized using cudaMemsetAsync,
  //       that is, initializing the bytes individually:
  //       0x7F results in 0x7F7F7F7F, which is 3.3961514e38 in fp32
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_triplet_best>(), 0x7F, arguments.size<dev_scifi_lf_triplet_best>(), cuda_stream));

  state.handler_lf_triplet_seeding.invoke();
  state.handler_lf_triplet_keep_best.invoke();

  // Extrapolate to all other layers
  state.handler_lf_extend_tracks_x.invoke();
}
