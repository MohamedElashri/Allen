#include "LFQualityFilterLength.cuh"

__global__ void lf_quality_filter_length(
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  int* dev_scifi_lf_filtered_atomics)
{
  const auto event_number = blockIdx.x;
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const SciFi::TrackHits& track = dev_scifi_lf_tracks[event_number * SciFi::Constants::max_lf_tracks + i];

    // Apply chi2 cut, as follows:
    // * If number of hits in track is 3, it's very unlikely this is a real track.
    //   Only consider those tracks for not densely populated tracks (< 1000 or so),
    //   and apply a tighter cut nevertheless (< 1.f or so)
    if (track.hitsNum >= 9) {
      const auto insert_index = atomicAdd(dev_scifi_lf_filtered_atomics + event_number, 1);
      dev_scifi_lf_filtered_tracks[event_number * SciFi::Constants::max_lf_tracks + insert_index] = track;
    }
  }
}
