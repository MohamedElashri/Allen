#include "LFCompositeTrackSeeding.cuh"
#include "SequenceVisitor.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(lf_composite_track_seeding_t)

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
  const auto seeding_set_arguments = [&state, &constants, &arguments] (const uint8_t relative_middle_layer) {
    state.handler_lf_triplet_seeding.set_arguments(
      arguments.offset<dev_scifi_hits>(),
      arguments.offset<dev_scifi_hit_count>(),
      arguments.offset<dev_atomics_ut>(),
      arguments.offset<dev_ut_qop>(),
      arguments.offset<dev_ut_states>(),
      constants.dev_scifi_geometry,
      constants.dev_inv_clus_res,
      arguments.offset<dev_scifi_lf_number_of_candidates>(),
      arguments.offset<dev_scifi_lf_candidates>(),
      constants.dev_looking_forward_constants,
      arguments.offset<dev_scifi_tracks>(),
      arguments.offset<dev_atomics_scifi>(),
      arguments.offset<dev_scifi_lf_candidate_atomics>(),
      arguments.offset<dev_scifi_lf_candidates_flag>(),
      relative_middle_layer);
  };

  const auto forwarding_set_arguments = [&state, &constants, &arguments] (const uint8_t relative_extrapolation_layer) {
    state.handler_lf_extend_tracks_x.set_arguments(
      arguments.offset<dev_scifi_hits>(),
      arguments.offset<dev_scifi_hit_count>(),
      arguments.offset<dev_atomics_ut>(),
      arguments.offset<dev_scifi_tracks>(),
      arguments.offset<dev_atomics_scifi>(),
      constants.dev_scifi_geometry,
      constants.dev_looking_forward_constants,
      constants.dev_inv_clus_res,
      arguments.offset<dev_scifi_lf_number_of_candidates>(),
      arguments.offset<dev_scifi_lf_candidates>(),
      arguments.offset<dev_scifi_lf_candidates_flag>(),
      relative_extrapolation_layer);
  };

  state.handler_lf_triplet_seeding.set_opts(dim3(host_buffers.host_number_of_selected_events[0], 32), dim3(64), cuda_stream);
  state.handler_lf_extend_tracks_x.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(128), cuda_stream);

  // We need to:
  // * Forward to layer 4
  // * Seed mid layer 3
  // * Forward to layer 5
  // * Seed mid layer 4
  for (int i=0; i<1; ++i) {
    cudaCheck(cudaMemsetAsync(
      arguments.offset<dev_scifi_lf_candidate_atomics>(),
      0,
      arguments.size<dev_scifi_lf_candidate_atomics>(),
      cuda_stream));

    forwarding_set_arguments(4 + i);
    seeding_set_arguments(3 + i);

    // state.handler_lf_extend_tracks_x.invoke();
    // state.handler_lf_triplet_seeding.invoke();
  }

  // cudaCheck(cudaMemcpyAsync(
  //   host_buffers.host_atomics_scifi,
  //   arguments.offset<dev_atomics_scifi>(),
  //   arguments.size<dev_atomics_scifi>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaCheck(cudaMemcpyAsync(
  //   host_buffers.host_scifi_tracks,
  //   arguments.offset<dev_scifi_tracks>(),
  //   arguments.size<dev_scifi_tracks>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream));

  // cudaEventRecord(cuda_generic_event, cuda_stream);
  // cudaEventSynchronize(cuda_generic_event);

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
