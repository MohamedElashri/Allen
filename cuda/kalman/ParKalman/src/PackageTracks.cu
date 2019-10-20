#include "ParKalmanVeloOnly.cuh"

__global__ void package_kalman_tracks(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  uint* dev_velo_indices,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  char* dev_velo_kalman_beamline_states,
  bool* dev_is_muon,
  ParKalmanFilter::FittedTrack* dev_kf_tracks)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Create velo tracks.
  // Create velo tracks.
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, (uint*) dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_veloUT,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_velo_indices,
                                            event_number,
                                            number_of_events};

  // Create SciFi tracks.
  const SciFi::Consolidated::Tracks scifi_tracks {(uint*) dev_n_scifi_tracks,
                                                  (uint*) dev_scifi_track_hit_number,
                                                  (float*) dev_scifi_qop,
                                                  (MiniState*) dev_scifi_states,
                                                  (uint*) dev_ut_indices,
                                                  event_number,
                                                  number_of_events};

  const uint n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (uint i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    // Prepare fit input.
    const int i_ut_track = scifi_tracks.ut_track[i_scifi_track];
    const int i_velo_track = ut_tracks.velo_track[i_ut_track];
    Velo::Consolidated::KalmanStates kalmanvelo_states {dev_velo_kalman_beamline_states,
                                                        velo_tracks.total_number_of_tracks};
    dev_kf_tracks[scifi_tracks.tracks_offset(event_number) + i_scifi_track] =
      ParKalmanFilter::FittedTrack {kalmanvelo_states.get(velo_tracks.tracks_offset(event_number) + i_velo_track),
                                    scifi_tracks.qop[i_scifi_track],
                                    dev_is_muon[scifi_tracks.tracks_offset(event_number) + i_scifi_track]};
  }
}