#include "LFTripletSeeding.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_triplet_seeding_t>(
  lf_triplet_seeding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_tracks>(host_buffers.host_number_of_selected_events[0] * SciFi::Constants::max_tracks);
  arguments.set_size<dev_atomics_scifi>(host_buffers.host_number_of_selected_events[0] * SciFi::num_atomics);
  arguments.set_size<dev_scifi_lf_candidates_flag>(host_buffers.host_lf_total_number_of_candidates[0]);
}

template<>
void SequenceVisitor::visit<lf_triplet_seeding_t>(
  lf_triplet_seeding_t& state,
  const lf_triplet_seeding_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_atomics_scifi>(),
    0,
    arguments.size<dev_atomics_scifi>(),
    cuda_stream));

  // No wmma section:
  // 1, 64: 19.53%
  // 1, 256: 23.23%
  // 4, 32: 19.69%
  // 32, 64: 13.04% (sbt: 11.24%)

  // With wmma section (on normal cuda):
  // 1, 64: 21.94%
  // 4, 32: 21.67%
  // 8, 64: 15.23%
  // 16, 64: 14.58%
  // 64, 64: 14.72% (sbt: 11.12%)
  // 128, 64: 15.30% (sbt: 10.73%)
  // 32, 32: 18.80% (sbt: 10.49%)
  // 32, 64: 14.44% (sbt: 11.18%)

  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0], 32), dim3(64), cuda_stream);
  state.set_arguments(
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
    arguments.offset<dev_scifi_lf_candidates_flag>(),
    1);

  state.invoke();

  // std::vector<int> scifi_atomics(arguments.size<dev_atomics_scifi>() / sizeof(dev_atomics_scifi::type));
  // std::vector<SciFi::TrackHits> scifi_tracks(arguments.size<dev_scifi_tracks>() / sizeof(dev_scifi_tracks::type));

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
  //   info_cout << "Event " << i
  //     << ", number of track candidates " << scifi_atomics[i] << std::endl;
  // }

  // for (uint i=0; i<host_buffers.host_number_of_selected_events[0]; ++i) {
  //   for (int j=0; j<scifi_atomics[i]; ++j) {
  //     const auto track = scifi_tracks[i * SciFi::Constants::max_tracks + j];

  //     info_cout << "Track " << track.hits[0] << ", "
  //       << track.hits[1] << ", "
  //       << track.hits[2] << ", "
  //       << track.quality
  //       << std::endl;
  //   }
  // }
}
