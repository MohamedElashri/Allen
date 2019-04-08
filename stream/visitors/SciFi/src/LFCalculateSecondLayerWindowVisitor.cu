#include "LFCalculateSecondLayerWindow.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_calculate_second_layer_window_t>(
  lf_calculate_second_layer_window_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_second_layer_candidates>(8 * host_buffers.host_lf_total_size_first_window_layer[0] + 1);
}

template<>
void SequenceVisitor::visit<lf_calculate_second_layer_window_t>(
  lf_calculate_second_layer_window_t& state,
  const lf_calculate_second_layer_window_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_second_layer_candidates>(),
    0,
    arguments.size<dev_scifi_lf_second_layer_candidates>(),
    cuda_stream
  ));

  // 1, 32: 19.06%
  // 2, 16: 15.58%
  // 4, 16: 15.83%
  // 8, 16: 16.79%
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(2, 16), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_first_layer_candidates>(),
    arguments.offset<dev_scifi_lf_second_layer_candidates>(),
    arguments.offset<dev_ut_states>(),
    LookingForward::seeding_station);

  state.invoke();
}
