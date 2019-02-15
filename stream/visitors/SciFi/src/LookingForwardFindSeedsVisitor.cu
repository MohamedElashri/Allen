#include "LookingForwardFindSeeds.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<looking_forward_find_seeds_t>(
  looking_forward_find_seeds_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_track_candidates>(host_buffers.host_number_of_selected_events[0] * SciFi::Constants::max_track_candidates);
  arguments.set_size<dev_atomics_scifi>(host_buffers.host_number_of_selected_events[0] * SciFi::num_atomics);
}

template<>
void SequenceVisitor::visit<looking_forward_find_seeds_t>(
  looking_forward_find_seeds_t& state,
  const looking_forward_find_seeds_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_atomics_scifi>(), 0, arguments.size<dev_atomics_scifi>(), cuda_stream));

  // host_buffers.host_number_of_selected_events[0]
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(32), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_x>(),
    arguments.offset<dev_ut_tx>(),
    arguments.offset<dev_ut_z>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_scifi_track_candidates>(),
    arguments.offset<dev_atomics_scifi>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    LookingForward::seeding_station);

  state.invoke();

  // std::vector<SciFi::TrackCandidate> scifi_track_candidates (arguments.size<dev_scifi_track_candidates>() / sizeof(SciFi::TrackCandidate));

  // cudaCheck(cudaMemcpyAsync(host_buffers.host_atomics_scifi,
  //   arguments.offset<dev_atomics_scifi>(),
  //   arguments.size<dev_atomics_scifi>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaCheck(cudaMemcpyAsync(scifi_track_candidates.data(),
  //   arguments.offset<dev_scifi_track_candidates>(),
  //   arguments.size<dev_scifi_track_candidates>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaEventRecord(cuda_generic_event, cuda_stream);
  // cudaEventSynchronize(cuda_generic_event);

  // for (uint i=0; i<host_buffers.host_number_of_selected_events[0]; ++i) {
  //   info_cout << "Event " << i
  //     << ", number of tracks " << host_buffers.host_atomics_scifi[i] << std::endl;
  // }
}
