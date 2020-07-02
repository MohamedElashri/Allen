#include "VeloCopyTrackHitNumber.cuh"

void velo_copy_track_hit_number::velo_copy_track_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_number_of_reconstructed_velo_tracks_t>(arguments, 1);
  set_size<dev_velo_track_hit_number_t>(
    arguments,
    first<host_number_of_velo_tracks_at_least_four_hits_t>(arguments) +
      first<host_number_of_three_hit_tracks_filtered_t>(arguments));

  // Note: Size is "+ 1" due to it storing offsets.
  set_size<dev_offsets_all_velo_tracks_t>(arguments, first<host_number_of_selected_events_t>(arguments) + 1);
}

void velo_copy_track_hit_number::velo_copy_track_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_offsets_all_velo_tracks_t>(arguments, 0, cuda_stream);

  global_function(velo_copy_track_hit_number)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);

  cudaCheck(cudaMemcpyAsync(
    data<host_number_of_reconstructed_velo_tracks_t>(arguments),
    data<dev_offsets_all_velo_tracks_t>(arguments) + (size<dev_offsets_all_velo_tracks_t>(arguments) / sizeof(unsigned)) -
      1,
    sizeof(unsigned), // Note: Only the last element needs to be copied here.
    cudaMemcpyDeviceToHost,
    cuda_stream));
}

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number::velo_copy_track_hit_number(
  velo_copy_track_hit_number::Parameters parameters)
{

  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto number_of_tracks =
    parameters.dev_offsets_velo_tracks[event_number + 1] - parameters.dev_offsets_velo_tracks[event_number];
  const auto number_of_three_hit_tracks = parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
                                          parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];

  // Pointer to velo_track_hit_number of current event
  const auto accumulated_tracks = parameters.dev_offsets_velo_tracks[event_number] +
                                  parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];
  unsigned* velo_track_hit_number = parameters.dev_velo_track_hit_number + accumulated_tracks;

  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    velo_track_hit_number[i] = event_tracks[i].hitsNum;
  }

  for (unsigned i = threadIdx.x; i < number_of_three_hit_tracks; i += blockDim.x) {
    velo_track_hit_number[number_of_tracks + i] = 3;
  }

  if (threadIdx.x == 0) {
    parameters.dev_offsets_all_velo_tracks[event_number + 1] =
      parameters.dev_offsets_velo_tracks[event_number + 1] +
      parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1];
  }
}
