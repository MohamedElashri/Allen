#include "LFExtendTracksUV.cuh"
#include "SequenceVisitor.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(lf_extend_tracks_uv_t)

template<>
void SequenceVisitor::visit<lf_extend_tracks_uv_t>(
  lf_extend_tracks_uv_t& state,
  const lf_extend_tracks_uv_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(128), cuda_stream);

  const auto forwarding_set_arguments = [&state, &constants, &arguments] (const uint8_t relative_extrapolation_layer) {
    state.set_arguments(
      arguments.offset<dev_scifi_hits>(),
      arguments.offset<dev_scifi_hit_count>(),
      arguments.offset<dev_atomics_ut>(),
      arguments.offset<dev_scifi_tracks>(),
      arguments.offset<dev_atomics_scifi>(),
      constants.dev_scifi_geometry,
      constants.dev_looking_forward_constants,
      constants.dev_inv_clus_res,
      arguments.offset<dev_ut_states>(),
      relative_extrapolation_layer);
  };

  // * Forward to UV layers
  for (int i=0; i<6; ++i) {
    forwarding_set_arguments(i);
    state.invoke();
  }

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_atomics_scifi,
    arguments.offset<dev_atomics_scifi>(),
    arguments.size<dev_atomics_scifi>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_scifi_tracks,
    arguments.offset<dev_scifi_tracks>(),
    arguments.size<dev_scifi_tracks>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

  // for (uint i=0; i<host_buffers.host_number_of_selected_events[0]; ++i) {
  //   const auto number_of_tracks = scifi_atomics[i];
  //   int number_of_quadruplets = 0;

  //   for (int j=0; j<number_of_tracks; ++j) {
  //     const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];
  //     if (track.hitsNum == 4) {
  //       ++number_of_quadruplets;
  //     }
  //   }

  //   info_cout << "Event " << i << ", number of quadruplet tracks " << number_of_quadruplets << std::endl;

  //   for (int j=0; j<number_of_tracks; ++j) {
  //     const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];
  //     if (track.hitsNum >= 4) {
  //       info_cout << "Track ";
  //       for (int k=0; k<track.hitsNum; ++k) {
  //         info_cout << track.hits[k] << ", ";
  //       }
  //       info_cout << track.get_quality() << std::endl;
  //     }
  //   }
  //   info_cout << std::endl;

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
