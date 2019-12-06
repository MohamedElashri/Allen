#include "ParKalmanVeloOnly.cuh"

void package_kalman_tracks_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_kf_tracks>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
}

void package_kalman_tracks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_scifi_track_hit_number>(),
    arguments.offset<dev_scifi_qop>(),
    arguments.offset<dev_scifi_states>(),
    arguments.offset<dev_scifi_track_ut_indices>(),
    arguments.offset<dev_velo_kalman_beamline_states>(),
    arguments.offset<dev_is_muon>(),
    arguments.offset<dev_kf_tracks>());
}

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