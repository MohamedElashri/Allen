#include "LFQualityFilterX.cuh"

__global__ void lf_quality_filter_x(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  uint* dev_scifi_lf_x_filtered_atomics,
  const float* dev_scifi_lf_parametrization,
  float* dev_scifi_lf_parametrization_x_filter)
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
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  __shared__ float chi2_ndofs[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ bool six_hit_track[LookingForward::maximum_number_of_candidates_per_ut_track];

  for (uint i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto number_of_tracks = dev_scifi_lf_atomics[current_ut_track_index];

    // Due to chi2_ndofs
    __syncthreads();

    // first save indices and qualities of tracks
    for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
      const auto scifi_track_index =
        current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + j;
      const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

      const auto ndof = track.hitsNum - 3;
      chi2_ndofs[j] = ndof > 0 ? track.quality / ndof : 10000.f;
      six_hit_track[j] = track.hitsNum == 6;
    }

    __syncthreads();

    // first save indices and qualities of tracks
    for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
      if (six_hit_track[j]) {
        const auto scifi_track_index =
          current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + j;
        const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

        for (uint k = j + 1; k < number_of_tracks; ++k) {
          if (six_hit_track[k]) {
            const auto other_scifi_track_index =
              current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + k;
            const SciFi::TrackHits& other_track = dev_scifi_lf_tracks[other_scifi_track_index];

            const bool same_track = track.hits[0] == other_track.hits[3] &&
              track.hits[1] == other_track.hits[4] &&
              track.hits[2] == other_track.hits[5] &&
              track.hits[3] == other_track.hits[0] &&
              track.hits[4] == other_track.hits[1] &&
              track.hits[5] == other_track.hits[2];

            if (same_track) {
              chi2_ndofs[j] = 10000.f;
            }
          }
        }
      }
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

      if (insert_position < LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter && chi2_ndof < 2.f) {
        // Save best track candidates
        const auto insert_index = atomicAdd(dev_scifi_lf_x_filtered_atomics + event_number, 1);

        const auto scifi_track_index =
          current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + j;
        const auto scifi_track_index_new =
          ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
          insert_index;
        const SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];

        if (Configuration::verbosity_level >= logger::debug) {
          if (blockIdx.x == 0) {
            track.print(event_number);
          }
        }
        
        // Save track and xAtRef
        dev_scifi_lf_x_filtered_tracks[scifi_track_index_new] = track;

        // Save track parameters to new container as well
        const auto a1 = dev_scifi_lf_parametrization[scifi_track_index];
        const auto b1 = dev_scifi_lf_parametrization
          [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
        const auto c1 = dev_scifi_lf_parametrization
          [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
           scifi_track_index];
        const auto d_ratio = dev_scifi_lf_parametrization
          [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
           scifi_track_index];

        dev_scifi_lf_parametrization_x_filter[scifi_track_index_new] = a1;
        dev_scifi_lf_parametrization_x_filter
          [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
           scifi_track_index_new] = b1;
        dev_scifi_lf_parametrization_x_filter
          [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
           scifi_track_index_new] = c1;
        dev_scifi_lf_parametrization_x_filter
          [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
           scifi_track_index_new] = d_ratio;
      }
    }
  }
}
