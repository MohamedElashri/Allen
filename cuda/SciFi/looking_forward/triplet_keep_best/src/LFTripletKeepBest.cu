#include "LFTripletKeepBest.cuh"

__global__ void lf_triplet_keep_best(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const int* dev_initial_windows,
  const bool* dev_scifi_lf_process_track,
  const int* dev_scifi_lf_found_triplets,
  const int8_t* dev_scifi_lf_number_of_found_triplets,
  uint* dev_scifi_lf_total_number_of_found_triplets)
{
  // Keep best for each h1 hit
  __shared__ int best_triplets[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ int found_triplets[2 * LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};

  for (uint i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;

    if (dev_scifi_lf_process_track[current_ut_track_index]) {

      // Initialize shared memory buffers
      __syncthreads();

      // Populate dev_scifi_lf_total_number_of_found_triplets and found_triplets
      for (uint j = threadIdx.x; j < 2 * LookingForward::triplet_seeding_block_dim_x; j += blockDim.x) {
        const auto triplet_seed = j / LookingForward::triplet_seeding_block_dim_x;
        const auto triplet_index = j % LookingForward::triplet_seeding_block_dim_x;

        const auto number_of_found_triplets = dev_scifi_lf_number_of_found_triplets
          [(current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
             LookingForward::triplet_seeding_block_dim_x +
           triplet_index];
        const auto scifi_lf_found_triplets =
          dev_scifi_lf_found_triplets + (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                                  LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread;

        if (number_of_found_triplets > 0) {
          const auto insert_index =
            atomicAdd(dev_scifi_lf_total_number_of_found_triplets + current_ut_track_index, number_of_found_triplets);
          for (int k = 0; k < number_of_found_triplets; ++k) {
            const auto found_triplet = scifi_lf_found_triplets[triplet_index * LookingForward::maximum_number_of_triplets_per_thread + k];
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

      // Now, we have the best candidates populated in best_chi2 and best_h0h2
      // Sort the candidates (insertion sort) into best_triplets

      // Note: if the number of tracks is less than LookingForward::maximum_number_of_candidates_per_ut_track
      //       then just store them all in best_triplets
      if (number_of_tracks < LookingForward::maximum_number_of_candidates_per_ut_track) {
        for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          best_triplets[j] = found_triplets[j];
        }
      }
      else {
        for (uint j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          const auto chi2 = found_triplets[j];

          int insert_position = 0;
          for (uint k = 0; k < number_of_tracks; ++k) {
            const auto other_chi2 = found_triplets[k];
            insert_position += chi2 > other_chi2 || (chi2 == other_chi2 && j < k);
          }

          if (insert_position < LookingForward::maximum_number_of_candidates_per_ut_track) {
            best_triplets[insert_position] = chi2;
          }
        }
      }

      __syncthreads();

      // Save best triplet candidates as TrackHits candidates for further extrapolation
      for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
        const auto k = best_triplets[j];
        if (k != -1) {
          const auto triplet_seed = (k >> 15) & 0x01;
          const auto h0_rel = (k >> 10) & 0x1F;
          const auto h1_rel = (k >> 5) & 0x1F;
          const auto h2_rel = k & 0x1F;

          // Create triplet candidate with all information we have
          const int current_insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
          const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
          const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
          const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

          // Offsets to h0, h1 and h2
          const int* initial_windows = dev_initial_windows + current_ut_track_index;

          const int l0_start = initial_windows[layer_0 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
          const int l1_start = initial_windows[layer_1 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
          const int l2_start = initial_windows[layer_2 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];

          const auto h0 = l0_start + h0_rel;
          const auto h1 = l1_start + h1_rel;
          const auto h2 = l2_start + h2_rel;

          dev_scifi_tracks
            [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track +
             current_insert_index] = SciFi::TrackHits {static_cast<uint16_t>(h0),
                                                       static_cast<uint16_t>(h1),
                                                       static_cast<uint16_t>(h2),
                                                       static_cast<uint16_t>(layer_0),
                                                       static_cast<uint16_t>(layer_1),
                                                       static_cast<uint16_t>(layer_2),
                                                       0.f,
                                                       0.f,
                                                       static_cast<uint16_t>(i)};
        }
      }
    }
  }
}
