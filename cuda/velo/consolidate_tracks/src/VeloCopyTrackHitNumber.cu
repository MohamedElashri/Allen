#include "VeloCopyTrackHitNumber.cuh"

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void velo_copy_track_hit_number::velo_copy_track_hit_number(
  velo_copy_track_hit_number::Parameters parameters)
{

  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto number_of_tracks =
    parameters.dev_atomics_velo[event_number + 1] - parameters.dev_atomics_velo[event_number];
  const auto number_of_three_hit_tracks = parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
                                          parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];

  // Pointer to velo_track_hit_number of current event
  const auto accumulated_tracks = parameters.dev_atomics_velo[event_number] +
                                  parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];
  uint* velo_track_hit_number = parameters.dev_velo_track_hit_number + accumulated_tracks;

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    velo_track_hit_number[i] = event_tracks[i].hitsNum;
  }

  for (uint i = threadIdx.x; i < number_of_three_hit_tracks; i += blockDim.x) {
    velo_track_hit_number[number_of_tracks + i] = 3;
  }

  if (threadIdx.x == 0) {
    parameters.dev_offsets_all_velo_tracks[event_number + 1] =
      parameters.dev_atomics_velo[event_number + 1] +
      parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1];
  }
}
