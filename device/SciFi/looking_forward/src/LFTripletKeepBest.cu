/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFCreateTracks.cuh"

__global__ void lf_create_tracks::lf_triplet_keep_best(
  lf_create_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  // Keep best for each h1 hit
  __shared__ int best_triplets[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ int found_triplets
    [2 * LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread];

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT consolidated tracks
  UT::Consolidated::ConstTracks ut_tracks {
    parameters.dev_atomics_ut, parameters.dev_ut_track_hit_number, event_number, number_of_events};

  const auto ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();

  for (unsigned i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;

    if (parameters.dev_scifi_lf_process_track[current_ut_track_index]) {

      // Initialize shared memory buffers
      __syncthreads();

      // Populate parameters.dev_scifi_lf_total_number_of_found_triplets and found_triplets
      for (unsigned j = threadIdx.x; j < 2 * LookingForward::triplet_seeding_block_dim_x; j += blockDim.x) {
        const auto triplet_seed = j / LookingForward::triplet_seeding_block_dim_x;
        const auto triplet_index = j % LookingForward::triplet_seeding_block_dim_x;

        const auto number_of_found_triplets =
          parameters.dev_scifi_lf_number_of_found_triplets
            [(current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
               LookingForward::triplet_seeding_block_dim_x +
             triplet_index];
        const auto scifi_lf_found_triplets = parameters.dev_scifi_lf_found_triplets +
                                             (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                                               LookingForward::triplet_seeding_block_dim_x *
                                               LookingForward::maximum_number_of_triplets_per_thread;

        if (number_of_found_triplets > 0) {
          const auto insert_index = atomicAdd(
            parameters.dev_scifi_lf_total_number_of_found_triplets + current_ut_track_index, number_of_found_triplets);
          for (int k = 0; k < number_of_found_triplets; ++k) {
            const auto found_triplet =
              scifi_lf_found_triplets[triplet_index * LookingForward::maximum_number_of_triplets_per_thread + k];
            found_triplets[insert_index + k] = found_triplet;
          }
        }
      }

      // Initialize best_triplets to -1
      for (unsigned j = threadIdx.x; j < LookingForward::maximum_number_of_candidates_per_ut_track; j += blockDim.x) {
        best_triplets[j] = -1;
      }

      __syncthreads();

      const auto number_of_tracks = parameters.dev_scifi_lf_total_number_of_found_triplets[current_ut_track_index];

      // Now, we have the best candidates populated in best_chi2 and best_h0h2
      // Sort the candidates (insertion sort) into best_triplets

      // Note: if the number of tracks is less than LookingForward::maximum_number_of_candidates_per_ut_track
      //       then just store them all in best_triplets
      if (number_of_tracks < LookingForward::maximum_number_of_candidates_per_ut_track) {
        for (unsigned j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          best_triplets[j] = found_triplets[j];
        }
      }
      else {
        for (unsigned j = threadIdx.x; j < number_of_tracks; j += blockDim.x) {
          const auto chi2 = found_triplets[j];

          int insert_position = 0;
          for (unsigned k = 0; k < number_of_tracks; ++k) {
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
          const int current_insert_index = atomicAdd(parameters.dev_scifi_lf_atomics + event_number, 1);
          const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
          const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
          const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

          // Offsets to h0, h1 and h2
          const int* initial_windows = parameters.dev_scifi_lf_initial_windows + current_ut_track_index;

          const int l0_start =
            initial_windows[layer_0 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
          const int l1_start =
            initial_windows[layer_1 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
          const int l2_start =
            initial_windows[layer_2 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];

          const auto h0 = l0_start + h0_rel;
          const auto h1 = l1_start + h1_rel;
          const auto h2 = l2_start + h2_rel;

          parameters.dev_scifi_lf_tracks
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
