#include "LFQualityFilterX.cuh"

__global__ void lf_quality_filter_collected_hits(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  uint* dev_scifi_lf_collected_hits_atomics,
  uint* dev_scifi_lf_collected_hits_tracks)
{
  if (Configuration::verbosity_level >= logger::debug) {
    if (blockIdx.y == 0) {
      printf("\n\n------------ Quality filter X --------------\n");
    }
  }

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;

  __shared__ float chi2_ndofs[LookingForward::maximum_number_of_candidates_per_ut_track];

  for (uint i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto number_of_tracks = dev_scifi_lf_atomics[current_ut_track_index];

    if (Configuration::verbosity_level >= logger::debug) {
      printf("Number of tracks for UT track %i: %i\n", i, number_of_tracks);
    }

    // Due to chi2_ndofs
    __syncthreads();

    // first save indices and qualities of tracks
    for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
      const auto scifi_track_index =
        current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + j;
      const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

      const auto ndof = track.hitsNum - 3;
      chi2_ndofs[j] = ndof > 0 ? track.quality / ndof : 10000.f;
    }

    // Due to chi2_ndofs
    __syncthreads();

    // Sort track candidates by quality
    for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
      const auto chi2_ndof = chi2_ndofs[j];

      uint insert_position = 0;
      for (uint k = 0; k < number_of_tracks; ++k) {
        const float other_chi2_ndof = chi2_ndofs[k];
        if (chi2_ndof > other_chi2_ndof || (chi2_ndof == other_chi2_ndof && j < k)) {
          ++insert_position;
        }
      }

      if (insert_position < 10 && chi2_ndof < 3.f) {
        // We already have the insert position
        // However, we need to count how many tracks are active
        const auto insert_index = atomicAdd(dev_scifi_lf_collected_hits_atomics + current_ut_track_index, 1);
        dev_scifi_lf_collected_hits_tracks
          [current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + insert_index] = j;
      }
    }
  }
}
