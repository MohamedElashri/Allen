#include "pv_beamline_extrapolate.cuh"

__global__ void pv_beamline_extrapolate(
  char* dev_velo_kalman_beamline_states,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtrack_z)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::KalmanStates velo_states =
    Velo::Consolidated::KalmanStates(dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks);
  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);
  const uint total_number_of_tracks = velo_tracks.total_number_of_tracks;

  for (uint index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const KalmanVeloState s = velo_states.get(event_tracks_offset + index);
    PatPV::XYZPoint beamline {0.f, 0.f, 0.f};
    const float dz = (s.tx * (beamline.x - s.x) + s.ty * (beamline.y - s.y)) / (s.tx * s.tx + s.ty * s.ty);
    
    float z = -9999.f;
    if (dz * s.c20 >= 0.f && dz * s.c31 >= 0.f) {
      z = s.z + dz;
    }

    dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + index] = z;
  }

  __syncthreads();

  // Insert in order
  for (uint index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const auto z = dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + index];
    uint insert_position = 0;

    for (uint other = 0; other < number_of_tracks_event; ++other) {
      const auto other_z = dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + other];
      insert_position += z > other_z || (z == other_z && index > other);
    }

    const KalmanVeloState s = velo_states.get(event_tracks_offset + index);
    PVTrack pvtrack = PVTrack {s, z - s.z};
    dev_pvtracks[event_tracks_offset + insert_position] = pvtrack;
    dev_pvtrack_z[event_tracks_offset + index] = z;
  }
}
