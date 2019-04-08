#include "LFFindCompatibleWindows.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_find_compatible_windows_t>(
  lf_find_compatible_windows_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // 2 windows of size 2
  arguments.set_size<dev_scifi_lf_compatible_windows>(host_buffers.host_lf_total_number_of_candidates[0] * 2 * 2);
}

template<>
void SequenceVisitor::visit<lf_find_compatible_windows_t>(
  lf_find_compatible_windows_t& state,
  const lf_find_compatible_windows_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_compatible_windows>(),
    0,
    arguments.size<dev_scifi_lf_compatible_windows>(),
    cuda_stream));

  // Scan:
  // 64, 8 - 14.03%
  // 32, 8, 2 - 8.27%
  // 32, 8, 4 - 6.74%
  // 16, 8, 8 - 7.26%
  // 32, 4, 8 - 8.19%
  // 64, 4, 4 - 7.03%

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(32, 8, 4), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_states>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_initial_windows>(),
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>(),
    arguments.offset<dev_scifi_lf_compatible_windows>(),
    constants.dev_looking_forward_constants);

  state.invoke();

}
