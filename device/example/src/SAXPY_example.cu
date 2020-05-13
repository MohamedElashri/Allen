#include "SAXPY_example.cuh"


/**
 * @brief SAXPY example algorithm
 * @detail Calculates for every event y = a*x + x, where x is the number of velo tracks in one event
 */

__global__ void saxpy::saxpy(
  saxpy::Parameters parameters)
  {
    const uint number_of_events = gridDim.x;
    const uint event_number = blockIdx.x * blockDim.x + threadIdx.x;

    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
    const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    
    if (event_number < number_of_events)
      parameters.dev_saxpy_output[event_number] = parameters.saxpy_scale_factor * number_of_tracks_event + number_of_tracks_event;
}
