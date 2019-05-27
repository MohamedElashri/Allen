#include "RateChecker.h"

void checkHlt1Rate(
  const bool* one_track_decisions,
  const bool* two_track_decisions,
  const int* track_atomics,
  const uint* sv_atomics,
  const uint selected_events,
  const uint requested_events)
{

  // Event counters.
  uint n_evts_one_track = 0;
  uint n_evts_two_track = 0;
  uint n_evts_inc = 0;
  
  // Event loop.
  for (uint i_event = 0; i_event < selected_events; i_event++) {
    
    // Check one track decisions.
    bool one_track_pass = false;
    const int* event_tracks_offsets = track_atomics + selected_events;
    const bool* event_one_track_decisions = one_track_decisions + event_tracks_offsets[i_event];
    const int n_tracks_event = track_atomics[i_event];
    for (int i_track = 0; i_track < n_tracks_event; i_track++) {
      if (event_one_track_decisions[i_track]) {
        one_track_pass = true;
        break;
      }
    }

    // Check two track decisions.
    bool two_track_pass = false;
    const bool* event_two_track_decisions = two_track_decisions + sv_atomics[i_event];
    const int n_svs_event = sv_atomics[i_event + 1] - sv_atomics[i_event];
    for (int i_sv = 0; i_sv < n_svs_event; i_sv++) {
      if (event_two_track_decisions[i_sv]) {
        two_track_pass = true;
        break;
      }
    }

    n_evts_one_track += one_track_pass;
    n_evts_two_track += two_track_pass;
    n_evts_inc += one_track_pass || two_track_pass;
    
  }

  // Assume 30 MHz input rate.
  float in_rate = 30000.0;
  printf("One track: %i / %i --> %f kHz\n",
         n_evts_one_track,
         requested_events,
         1. * n_evts_one_track / requested_events * in_rate);
  printf("Two track: %i / %i --> %f kHz\n",
         n_evts_two_track,
         requested_events,
         1. * n_evts_two_track / requested_events * in_rate);
  printf("Inclusive: %i / %i --> %f kHz\n\n",
         n_evts_inc,
         requested_events,
         1. * n_evts_inc / requested_events * in_rate);
}
