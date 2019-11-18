#include "LFQualityFilter.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_quality_filter_t>(
  lf_quality_filter_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_selected_track_indices>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * SciFi::Constants::max_SciFi_tracks_per_UT_track);
  arguments.set_size<dev_atomics_scifi>(
    host_buffers.host_number_of_selected_events[0] * LookingForward::num_atomics * 2 + 1);
  arguments.set_size<dev_scifi_tracks>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * SciFi::Constants::max_SciFi_tracks_per_UT_track);
  arguments.set_size<dev_scifi_lf_y_parametrization_length_filter>(
    2 * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter);
  arguments.set_size<dev_scifi_lf_parametrization_consolidate>(
    6 * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
    SciFi::Constants::max_SciFi_tracks_per_UT_track);
}

template<>
void SequenceVisitor::visit<lf_quality_filter_t>(
  lf_quality_filter_t& state,
  const lf_quality_filter_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_atomics_scifi>(), 0, arguments.size<dev_atomics_scifi>(), cuda_stream));

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_length_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_length_filtered_atomics>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_scifi_selected_track_indices>(),
    arguments.offset<dev_scifi_tracks>(),
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_parametrization_length_filter>(),
    arguments.offset<dev_scifi_lf_y_parametrization_length_filter>(),
    arguments.offset<dev_scifi_lf_parametrization_consolidate>(),
    arguments.offset<dev_ut_states>());

  state.invoke();

  if (runtime_options.do_check) {
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
  }

  // for (uint i=0; i<host_buffers.host_number_of_selected_events[0]; ++i) {
  //   const auto number_of_tracks = host_buffers.host_atomics_scifi[i];
  // int number_of_quadruplets = 0;

  // for (int j=0; j<number_of_tracks; ++j) {
  //   const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];
  //   if (track.hitsNum == 4) {
  //     ++number_of_quadruplets;
  //   }
  // }

  // info_cout << "Event " << i << ", number of quadruplet tracks " << number_of_quadruplets << std::endl;

  // for (int j=0; j<number_of_tracks; ++j) {
  //   const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];
  //   if (track.hitsNum >= 4) {
  //     info_cout << "Track ";
  //     for (int k=0; k<track.hitsNum; ++k) {
  //       info_cout << track.hits[k] << ", ";
  //     }
  //     info_cout << track.get_quality() << std::endl;
  //   }
  // }
  // info_cout << std::endl;

  // info_cout << "Event " << i << ", number of tracks " << number_of_tracks << std::endl;

  //   for (int j=0; j<number_of_tracks; ++j) {
  //     const auto track = host_buffers.host_scifi_tracks[i * SciFi::Constants::max_tracks + j];
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
