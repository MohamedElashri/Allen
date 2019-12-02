#include "pv_beamline_calculate_denom.cuh"
#include "Invoke.cuh"

void pv_beamline_calculate_denom_t::invoke() {
  invoke_helper(handler);
}

__global__ void pv_beamline_calculate_denom(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtracks_denom,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};

  const uint number_of_tracks = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const float* zseeds = dev_zpeaks + event_number * PV::max_number_vertices;
  const uint number_of_seeds = dev_number_of_zpeaks[event_number];

  const PVTrack* tracks = dev_pvtracks + event_tracks_offset;
  float* pvtracks_denom = dev_pvtracks_denom + event_tracks_offset;

  // Precalculate all track denoms
  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    auto track_denom = 0.f;
    const auto track = tracks[i];

    for (uint j = 0; j < number_of_seeds; ++j) {
      const auto dz = zseeds[j] - track.z;
      const float2 res = track.x + track.tx * dz;
      const auto chi2 = res.x * res.x * track.W_00 + res.y * res.y * track.W_11;
      track_denom += expf(chi2 * (-0.5f));
    }

    pvtracks_denom[i] = track_denom;
  }
}
