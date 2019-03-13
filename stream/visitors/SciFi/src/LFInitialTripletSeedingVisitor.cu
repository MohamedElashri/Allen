#include "LFInitialTripletSeeding.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_initial_triplet_seeding_t>(
  lf_initial_triplet_seeding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_tracks>(host_buffers.host_number_of_selected_events[0] * SciFi::Constants::max_tracks);
  arguments.set_size<dev_atomics_scifi>(host_buffers.host_number_of_selected_events[0] * LookingForward::num_atomics);
  arguments.set_size<dev_scifi_lf_candidates_flag>(host_buffers.host_accumulated_number_of_scifi_hits[0]);
}

template<>
void SequenceVisitor::visit<lf_initial_triplet_seeding_t>(
  lf_initial_triplet_seeding_t& state,
  const lf_initial_triplet_seeding_t::arguments_t& arguments,
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
  
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_candidates_flag>(),
    0,
    arguments.size<dev_scifi_lf_candidates_flag>(),
    cuda_stream));

  // 1, 64: 21.94%
  // 4, 32: 21.67%
  // 8, 64: 15.23%
  // 16, 64: 14.58%
  // 64, 64: 14.72% (sbt: 11.12%)
  // 128, 64: 15.30% (sbt: 10.73%)
  // 32, 32: 18.80% (sbt: 10.49%)
  // 32, 64: 14.44% (sbt: 11.18%)

  // 32, 64, half (casting): 13.79% (sbt: 10.97%)
  // 32, 64, half, with preloaded half x: 13.58% (sbt: 10.77%)
  // as before, common initialization of shared_partial_chi2: 13.53% (11.27%)

  // 32, 64, "minor" improvements in the hot loop: 8.77% (11.97%)
  // 32, 64, optimized math in hottest loop: 8.23% (11.59%) - 0.710094909
  // 32, 64, optimized, with insertion sort and keeping best 20 candidates: 8.81% (11.83%) - 0.744716822

  // With a max_candidates_size of 32: 6.62% (11.91%) (not much faster going from 64 to 32)

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
