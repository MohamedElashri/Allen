#include "ParKalmanVeloOnly.cuh"

__global__ void package_kalman_tracks::package_kalman_tracks(package_kalman_tracks::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Create velo tracks.
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  UT::Consolidated::ConstTracks ut_tracks {parameters.dev_atomics_ut,
                                           parameters.dev_ut_track_hit_number,
                                           parameters.dev_ut_qop,
                                           parameters.dev_ut_track_velo_indices,
                                           event_number,
                                           number_of_events};

  // Create SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_number,
                                                 number_of_events};

  const uint n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (uint i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    // Prepare fit input.
    const int i_ut_track = scifi_tracks.ut_track(i_scifi_track);
    const int i_velo_track = ut_tracks.velo_track(i_ut_track);
    Velo::Consolidated::ConstKalmanStates kalmanvelo_states {parameters.dev_velo_kalman_beamline_states,
                                                             velo_tracks.total_number_of_tracks()};
    parameters.dev_kf_tracks[scifi_tracks.tracks_offset(event_number) + i_scifi_track] =
      ParKalmanFilter::FittedTrack {kalmanvelo_states.get(velo_tracks.tracks_offset(event_number) + i_velo_track),
                                    scifi_tracks.qop(i_scifi_track),
                                    parameters.dev_is_muon[scifi_tracks.tracks_offset(event_number) + i_scifi_track]};
  }
}