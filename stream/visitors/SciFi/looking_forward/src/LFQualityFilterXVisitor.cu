#include "LFQualityFilterX.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_quality_filter_x_t>(
  lf_quality_filter_x_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_x_filtered_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
  arguments.set_size<dev_scifi_lf_x_filtered_atomics>(
    host_buffers.host_number_of_selected_events[0] * LookingForward::num_atomics * 2 + 1);
  arguments.set_size<dev_scifi_lf_xAtRef>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
  arguments.set_size<dev_scifi_lf_xAtRef>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
  arguments.set_size<dev_scifi_lf_parametrization_x_filter>(
    4 * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
}

template<>
void SequenceVisitor::visit<lf_quality_filter_x_t>(
  lf_quality_filter_x_t& state,
  const lf_quality_filter_x_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_x_filtered_atomics>(),
    0,
    arguments.size<dev_scifi_lf_x_filtered_atomics>(),
    cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0], 24), dim3(32), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_scifi_lf_tracks>(),
    arguments.offset<dev_scifi_lf_atomics>(),
    arguments.offset<dev_scifi_lf_x_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_x_filtered_atomics>(),
    arguments.offset<dev_scifi_lf_xAtRef>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    constants.dev_looking_forward_constants,
    constants.dev_scifi_constArrays,
    arguments.offset<dev_scifi_lf_parametrization>(),
    arguments.offset<dev_scifi_lf_parametrization_x_filter>());

  state.invoke();
}
