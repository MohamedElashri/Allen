#include "pv_beamline_extrapolate.cuh"
#include "Invoke.cuh"

void pv_beamline_extrapolate_t::invoke() {
  invoke_helper(handler);
}

__global__ void pv_beamline_extrapolate(
  char* dev_velo_kalman_beamline_states,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::KalmanStates velo_states =
    Velo::Consolidated::KalmanStates(dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks);
  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  for (uint index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    KalmanVeloState s = velo_states.get(event_tracks_offset + index);
    PatPV::XYZPoint beamline {0.f, 0.f, 0.f};
    const auto tx = s.tx;
    const auto ty = s.ty;
    float dz = (tx * (beamline.x - s.x) + ty * (beamline.y - s.y)) / (tx * tx + ty * ty);

    if (dz * s.c20 < 0.f || dz * s.c31 < 0.f) dz = -9999.f;
    PVTrack pvtrack = PVTrack {s, dz};
    dev_pvtracks[event_tracks_offset + index] = pvtrack;
  }
}
