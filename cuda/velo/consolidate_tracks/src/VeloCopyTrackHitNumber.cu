#include "VeloCopyTrackHitNumber.cuh"

void velo_copy_track_hit_number_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_velo_track_hit_number>(host_buffers.velo_track_hit_number_size());
}

void velo_copy_track_hit_number_t::visit(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  algorithm.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_tracks>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>());
}

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number(
  const Velo::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto* event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto accumulated_tracks = dev_atomics_storage[number_of_events + event_number];
  const auto number_of_tracks = dev_atomics_storage[event_number];

  // Pointer to velo_track_hit_number of current event
  uint* velo_track_hit_number = dev_velo_track_hit_number + accumulated_tracks;

  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    velo_track_hit_number[element] = event_tracks[element].hitsNum;
  }
}
