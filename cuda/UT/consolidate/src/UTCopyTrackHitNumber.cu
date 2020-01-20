#include "UTCopyTrackHitNumber.cuh"

/**
 * @brief Copies UT track hit numbers on a consecutive container
 */
__global__ void ut_copy_track_hit_number::ut_copy_track_hit_number(ut_copy_track_hit_number::Parameters parameters)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;
  const auto accumulated_tracks = parameters.dev_atomics_ut[event_number];
  const auto number_of_tracks =
    parameters.dev_atomics_ut[event_number + 1] - parameters.dev_atomics_ut[event_number];

  // Pointer to ut_track_hit_number of current event.
  uint* ut_track_hit_number = parameters.dev_ut_track_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    ut_track_hit_number[element] = event_tracks[element].hits_num;
  }
}
