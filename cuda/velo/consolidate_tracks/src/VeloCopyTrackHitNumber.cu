#include "VeloCopyTrackHitNumber.cuh"

using namespace velo_copy_track_hit_number;

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number::velo_copy_track_hit_number(
  dev_tracks_t dev_tracks,
  dev_atomics_velo_t dev_atomics_storage,
  dev_velo_track_hit_number_t dev_velo_track_hit_number,
  dev_offsets_number_of_three_hit_tracks_filtered_t dev_offsets_number_of_three_hit_tracks_filtered,
  dev_offsets_all_velo_tracks_t dev_offsets_all_velo_tracks) {

  const auto event_number = blockIdx.x;
  const auto event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto number_of_tracks = dev_atomics_storage[event_number + 1] - dev_atomics_storage[event_number];
  const auto number_of_three_hit_tracks = dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
                                          dev_offsets_number_of_three_hit_tracks_filtered[event_number];

  // Pointer to velo_track_hit_number of current event
  const auto accumulated_tracks =
    dev_atomics_storage[event_number] + dev_offsets_number_of_three_hit_tracks_filtered[event_number];
  uint* velo_track_hit_number = dev_velo_track_hit_number + accumulated_tracks;

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    velo_track_hit_number[i] = event_tracks[i].hitsNum;
  }

  for (uint i = threadIdx.x; i < number_of_three_hit_tracks; i += blockDim.x) {
    velo_track_hit_number[number_of_tracks + i] = 3;
  }

  if (threadIdx.x == 0) {
    dev_offsets_all_velo_tracks[event_number + 1] =
      dev_atomics_storage[event_number + 1] + dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1];
  }
}
