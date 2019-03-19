#include "LFQualityFilterX.cuh"

__global__ void lf_quality_filter_x(
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_filtered_tracks,
  int* dev_scifi_lf_filtered_atomics)
{
  const auto event_number = blockIdx.x;
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const SciFi::TrackHits& track = dev_scifi_lf_tracks[event_number * SciFi::Constants::max_lf_tracks + i];

    // chi2 cut: 1.f
    if (track.hitsNum > 3 || (track.hitsNum == 3 && track.quality < 1.f)) {
      const auto insert_index = atomicAdd(dev_scifi_lf_filtered_atomics + event_number, 1);
      dev_scifi_lf_filtered_tracks[event_number * SciFi::Constants::max_lf_tracks + insert_index] = track;
    }
  }
}
