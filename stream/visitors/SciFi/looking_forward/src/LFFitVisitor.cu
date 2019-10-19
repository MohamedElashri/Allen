#include "LFFit.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_fit_t>(
  lf_fit_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_track_params>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter * SciFi::Tracking::nTrackParams);
}

template<>
void SequenceVisitor::visit<lf_fit_t>(
  lf_fit_t& state,
  const lf_fit_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(512), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_scifi_lf_length_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_length_filtered_atomics>(),
    arguments.offset<dev_scifi_lf_xAtRef_after_length_filter>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    constants.dev_scifi_constArrays,
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_track_params>());

  state.invoke();
}
