#include "UTSelectVeloTracks.cuh"
#include <tuple>

__global__ void ut_select_velo_tracks::ut_select_velo_tracks(ut_select_velo_tracks::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  auto ut_number_of_selected_velo_tracks = parameters.dev_ut_number_of_selected_velo_tracks + event_number;
  auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;

  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const uint current_track_offset = event_tracks_offset + i;
    const auto velo_state = velo_states.get(current_track_offset);
    if (
      !velo_state.backward && parameters.dev_accepted_velo_tracks[current_track_offset] &&
      velo_track_in_UTA_acceptance(velo_state)) {
      int current_track = atomicAdd(ut_number_of_selected_velo_tracks, 1);
      ut_selected_velo_tracks[current_track] = i;
    }
  }
}
