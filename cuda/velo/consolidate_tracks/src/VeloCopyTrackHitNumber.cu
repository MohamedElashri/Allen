#include "VeloCopyTrackHitNumber.cuh"

using namespace velo_copy_track_hit_number;

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number::velo_copy_track_hit_number(
  dev_tracks_t dev_tracks,
  dev_atomics_velo_t dev_atomics_storage,
  dev_velo_track_hit_number_t dev_velo_track_hit_number)
{
  const auto event_number = blockIdx.x;
  const auto* event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto accumulated_tracks = dev_atomics_storage[event_number];
  const auto number_of_tracks = dev_atomics_storage[event_number + 1] - dev_atomics_storage[event_number];

  // Pointer to velo_track_hit_number of current event
  uint* velo_track_hit_number = dev_velo_track_hit_number + accumulated_tracks;

  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    velo_track_hit_number[element] = event_tracks[element].hitsNum;
  }
}
