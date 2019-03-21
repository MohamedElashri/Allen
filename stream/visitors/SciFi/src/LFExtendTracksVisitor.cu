#include "LFExtendTracks.cuh"
#include "SequenceVisitor.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(lf_extend_tracks_t)

template<>
void SequenceVisitor::visit<lf_extend_tracks_t>(
  lf_extend_tracks_t& state,
  const lf_extend_tracks_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_extrapolation_layer_candidates>(),
    arguments.offset<dev_scifi_tracks>(),
    arguments.offset<dev_atomics_scifi>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_ut_states>(),
    6);

  state.invoke();

  // std::vector<int> scifi_atomics (arguments.size<dev_atomics_scifi>() / sizeof(int));
  // std::vector<SciFi::TrackHits> scifi_tracks (arguments.size<dev_scifi_tracks>() / sizeof(SciFi::TrackHits));

  // cudaCheck(cudaMemcpyAsync(
  //   scifi_atomics.data(),
  //   arguments.offset<dev_atomics_scifi>(),
  //   arguments.size<dev_atomics_scifi>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaCheck(cudaMemcpyAsync(
  //   scifi_tracks.data(),
  //   arguments.offset<dev_scifi_tracks>(),
  //   arguments.size<dev_scifi_tracks>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaEventRecord(cuda_generic_event, cuda_stream);
  // cudaEventSynchronize(cuda_generic_event);

  // for (uint i=0; i<host_buffers.host_number_of_selected_events[0]; ++i) {
  //   const auto number_of_tracks = scifi_atomics[host_buffers.host_number_of_selected_events[0] + i];
  //   info_cout << "Event " << i << ", number of tracks " << number_of_tracks << std::endl;

  //   for (int j=0; j<number_of_tracks; ++j) {
  //     const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];
  //     info_cout << " Track #" << j << " from ut track " << track.ut_track_index
  //       << ", quality " << track.get_quality()
  //       << ", hits: ";

  //     for (int k=0; k<track.hitsNum; ++k) {
  //       info_cout << track.hits[k] << ", ";
  //     }
  //     info_cout << std::endl;
  //   }
  // }
}
