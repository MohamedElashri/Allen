#include "LFTripletKeepBest.cuh"

__global__ void lf_triplet_keep_best(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const SciFi::CombinedValue* dev_scifi_lf_triplet_best,
  const int* dev_initial_windows)
{
  // Keep best for each h1 hit
  __shared__ float best_chi2[LookingForward::n_triplet_seeds * LookingForward::maximum_number_of_triplets_per_seed];
  __shared__ int16_t best_triplets[LookingForward::maximum_number_of_candidates_per_ut_track];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo datatypes
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, dev_atomics_velo[2 * number_of_events]};
  const uint velo_tracks_offset_event = dev_atomics_velo[number_of_events + event_number];

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto velo_track_index = dev_ut_track_velo_indices[current_ut_track_index];
    const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
    const auto velo_tx = velo_states.tx[velo_states_index];

    // Initialize shared memory buffers
    __syncthreads();

    // Initialize the best_ shared memory buffers
    for (uint8_t triplet_seed = 0; triplet_seed < LookingForward::n_triplet_seeds; ++triplet_seed) {
      for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_triplets_per_seed; j += blockDim.x) {
        best_chi2[triplet_seed * LookingForward::maximum_number_of_triplets_per_seed + j] =
          dev_scifi_lf_triplet_best
            [(current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
               LookingForward::maximum_number_of_triplets_per_seed +
             j]
              .chi2;
      }
    }

    // Initialize best_triplets to -1
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
      best_triplets[j] = -1;
    }

    __syncthreads();

    // Now, we have the best candidates populated in best_chi2 and best_h0h2
    // Sort the candidates (insertion sort) into best_triplets
    for (uint16_t j = threadIdx.x;
         j < LookingForward::n_triplet_seeds * LookingForward::maximum_number_of_triplets_per_seed;
         j += blockDim.x) {
      const float chi2 = best_chi2[j];
      if (chi2 < LookingForward::chi2_max_triplet_single) {
        int16_t insert_position = 0;

        for (uint16_t k = 0; k < LookingForward::n_triplet_seeds * LookingForward::maximum_number_of_triplets_per_seed;
             ++k) {
          const float other_chi2 = best_chi2[k];
          if (chi2 > other_chi2 || (chi2 == other_chi2 && j < k)) {
            ++insert_position;
          }
        }

        if (insert_position < LookingForward::maximum_number_of_candidates_per_ut_track) {
          best_triplets[insert_position] = j;
        }
      }
    }

    __syncthreads();

    if (Configuration::verbosity_level >= logger::debug) {
      // if (event_number == 0 && i == 0) {
      printf("Best triplets: ");
      for (uint j = 0; j < LookingForward::maximum_number_of_candidates_per_ut_track; ++j) {
        printf(" %i,", best_triplets[j]);
      }
      printf("\n");
      // }
    }

    // Save best triplet candidates as TrackHits candidates for further extrapolation
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
      const auto k = best_triplets[j];
      if (k != -1) {

        const auto triplet_seed = k / (LookingForward::maximum_number_of_triplets_per_seed);

        const auto triplet_element = k % (LookingForward::maximum_number_of_triplets_per_seed);

        const auto combined_element = dev_scifi_lf_triplet_best
          [(current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
             LookingForward::maximum_number_of_triplets_per_seed +
           triplet_element];

        // Create triplet candidate with all information we have
        const int current_insert_index = atomicAdd(dev_atomics_scifi + current_ut_track_index, 1);
        assert(current_insert_index < LookingForward::maximum_number_of_candidates_per_ut_track);

        // Get correct windows
        const int* initial_windows = dev_initial_windows + current_ut_track_index;

        const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
        const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];
        const auto layer_1 = dev_looking_forward_constants->reverse_layers[scifi_hits.planeCode(event_offset + combined_element.h1) / 2];

        const float x0 = scifi_hits.x0[event_offset + combined_element.h0];
        const float x2 = scifi_hits.x0[event_offset + combined_element.h2];
        const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
        const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

        const auto slope_t1_t3 = (x0 - x2) / (z0 - z2);
        const auto delta_slope = fabsf(velo_tx - slope_t1_t3);
        const auto eq = LookingForward::qop_p0 + LookingForward::qop_p1 * delta_slope -
                        LookingForward::qop_p2 * delta_slope * delta_slope;
        const auto updated_qop = eq / (1.f + 5.08211e+02f * eq);

        dev_scifi_tracks
          [current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + current_insert_index] =
            SciFi::TrackHits {combined_element.h0,
                              combined_element.h1,
                              combined_element.h2,
                              (uint16_t) layer_0,
                              (uint16_t) layer_1,
                              (uint16_t) layer_2,
                              0.f,
                              updated_qop,
                              i};
      }
    }
  }
}
