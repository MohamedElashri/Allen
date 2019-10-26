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
  const float* dev_scifi_lf_triplet_best,
  const int* dev_initial_windows,
  const bool* dev_scifi_lf_process_track,
  const int16_t* dev_scifi_lf_found_triplets,
  const int16_t* dev_scifi_lf_number_of_found_triplets,
  uint* dev_scifi_lf_total_number_of_found_triplets)
{
  // Keep best for each h1 hit
  __shared__ int16_t best_triplets[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ int16_t found_triplets[LookingForward::maximum_number_of_triplets_per_seed / 2];

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

  for (uint i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;

    if (dev_scifi_lf_process_track[current_ut_track_index]) {
      const auto velo_track_index = dev_ut_track_velo_indices[current_ut_track_index];
      const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
      const auto velo_tx = velo_states.tx[velo_states_index];

      const auto best_chi2 = dev_scifi_lf_triplet_best + current_ut_track_index * LookingForward::n_triplet_seeds *
                                                           LookingForward::maximum_number_of_triplets_per_seed;

      // Initialize shared memory buffers
      __syncthreads();

      // Populate dev_scifi_lf_total_number_of_found_triplets and found_triplets
      for (uint j = threadIdx.x; j < 2 * LookingForward::extreme_layers_window_size; j += blockDim.x) {
        const auto triplet_seed = j / LookingForward::extreme_layers_window_size;
        const auto triplet_index = j % LookingForward::extreme_layers_window_size;

        const auto number_of_found_triplets = dev_scifi_lf_number_of_found_triplets
          [(current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
             LookingForward::extreme_layers_window_size +
           triplet_index];
        const auto scifi_lf_found_triplets =
          dev_scifi_lf_found_triplets + (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                                          LookingForward::maximum_number_of_triplets_per_seed;

        if (number_of_found_triplets > 0) {
          const auto insert_index =
            atomicAdd(dev_scifi_lf_total_number_of_found_triplets + current_ut_track_index, number_of_found_triplets);
          for (uint k = 0; k < number_of_found_triplets; ++k) {
            const auto found_triplet = scifi_lf_found_triplets
              [triplet_index *
                 (LookingForward::maximum_number_of_triplets_per_seed / LookingForward::extreme_layers_window_size) +
               k];
            found_triplets[insert_index + k] = found_triplet;
          }
        }
      }

      // Initialize best_triplets to -1
      for (uint j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
        best_triplets[j] = -1;
      }

      __syncthreads();

      const auto number_of_tracks = dev_scifi_lf_total_number_of_found_triplets[current_ut_track_index];

      // if (Configuration::verbosity_level >= logger::info) {
      //   printf("Number of tracks: %i\n", number_of_tracks);

      //   // uint population = 0;
      //   printf("Best chi2s:");
      //   for (uint j = 0; j < number_of_tracks; ++j) {
      //     const auto chi2_index = found_triplets[j];
      //     const auto chi2 = best_chi2[chi2_index];
      //     printf(" %f (%i),", best_chi2[chi2_index], chi2_index);
      //   }
      //   printf("\n");
      // }

      // Now, we have the best candidates populated in best_chi2 and best_h0h2
      // Sort the candidates (insertion sort) into best_triplets

      // Note: if the number of tracks is less than LookingForward::maximum_number_of_candidates_per_ut_track
      //       then just store them all in best_triplets
      if (number_of_tracks < LookingForward::maximum_number_of_candidates_per_ut_track) {
        for (int j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          const auto chi2_index = found_triplets[j];
          best_triplets[j] = static_cast<int16_t>(chi2_index);
        }
      }
      else {
        for (int j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          const auto chi2_index = found_triplets[j];
          const auto chi2 = best_chi2[chi2_index];

          int insert_position = 0;
          for (int k = 0; k < number_of_tracks; ++k) {
            const auto other_chi2_index = found_triplets[k];
            const auto other_chi2 = best_chi2[other_chi2_index];
            insert_position += chi2 > other_chi2 || (chi2 == other_chi2 && chi2_index < other_chi2_index);
          }

          if (insert_position < LookingForward::maximum_number_of_candidates_per_ut_track) {
            best_triplets[insert_position] = static_cast<int16_t>(chi2_index);
          }
        }
      }

      // if (Configuration::verbosity_level >= logger::info) {
      //   // uint population = 0;
      //   printf("Best triplets:");
      //   for (uint j = 0; j < LookingForward::maximum_number_of_candidates_per_ut_track; ++j) {
      //     const auto k = best_triplets[j];
      //     if (k != -1) {
      //       printf(" %f,", best_chi2[k]);
      //     }
      //   }
      //   printf("\n");
      // }

      __syncthreads();

      // if (Configuration::verbosity_level >= logger::debug) {
      //   printf("Best triplets: ");
      //   for (uint j = 0; j < LookingForward::maximum_number_of_candidates_per_ut_track; ++j) {
      //     printf(" %i,", best_triplets[j]);
      //   }
      //   printf("\n");
      // }

      // Save best triplet candidates as TrackHits candidates for further extrapolation
      for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
        const auto k = best_triplets[j];
        if (k != -1) {
          const auto triplet_seed = k / (LookingForward::maximum_number_of_triplets_per_seed);
          const auto triplet_element = k % (LookingForward::maximum_number_of_triplets_per_seed);

          const float chi2 = best_chi2[k];
          const int* chi2_intp = reinterpret_cast<const int*>(&chi2);
          const auto h1_rel = chi2_intp[0] & 0x1F;

          const auto h0_rel = triplet_element / LookingForward::extreme_layers_window_size;
          const auto h2_rel = triplet_element % LookingForward::extreme_layers_window_size;

          // Create triplet candidate with all information we have
          const int current_insert_index = atomicAdd(dev_atomics_scifi + current_ut_track_index, 1);
          assert(current_insert_index < LookingForward::maximum_number_of_candidates_per_ut_track);

          const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
          const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
          const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

          // Offsets to h0, h1 and h2
          const int* initial_windows = dev_initial_windows + current_ut_track_index;

          const int l0_start = initial_windows[(layer_0 * 8) * ut_total_number_of_tracks];
          const int l1_start = initial_windows[(layer_1 * 8) * ut_total_number_of_tracks];
          const int l2_start = initial_windows[(layer_2 * 8) * ut_total_number_of_tracks];

          const auto h0 = l0_start + h0_rel;
          const auto h1 = l1_start + h1_rel;
          const auto h2 = l2_start + h2_rel;

          const float x0 = scifi_hits.x0[event_offset + h0];
          const float x2 = scifi_hits.x0[event_offset + h2];
          const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
          const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

          const auto slope_t1_t3 = (x0 - x2) / (z0 - z2);
          const auto delta_slope = fabsf(velo_tx - slope_t1_t3);
          const auto eq = LookingForward::qop_p0 + LookingForward::qop_p1 * delta_slope -
                          LookingForward::qop_p2 * delta_slope * delta_slope;
          const auto updated_qop = eq / (1.f + 5.08211e+02f * eq);

          dev_scifi_tracks
            [current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track +
             current_insert_index] = SciFi::TrackHits {static_cast<uint16_t>(h0),
                                                       static_cast<uint16_t>(h1),
                                                       static_cast<uint16_t>(h2),
                                                       static_cast<uint16_t>(layer_0),
                                                       static_cast<uint16_t>(layer_1),
                                                       static_cast<uint16_t>(layer_2),
                                                       0.f,
                                                       updated_qop,
                                                       i};
        }
      }
    }
  }
}
