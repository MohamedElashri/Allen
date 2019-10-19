#include "LFTripletSeeding.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<lf_triplet_seeding_t>(
  lf_triplet_seeding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_lf_triplet_best>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * 4 * LookingForward::maximum_number_of_candidates *
    LookingForward::maximum_number_of_triplets_per_h1);
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
  state.set_arguments(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_qop>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_number_of_candidates>(),
    arguments.offset<dev_scifi_lf_candidates>(),
    constants.dev_looking_forward_constants,
    arguments.offset<dev_scifi_lf_triplet_best>());

  state.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0]), dim3(32), cuda_stream);

  state.invoke();
}
