#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "TrackUtils.cuh"
#include "LookingForwardTools.cuh"

__global__ void lf_triplet_seeding(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const float* dev_ut_qop,
  const MiniState* dev_ut_states,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const uint* dev_scifi_lf_number_of_candidates,
  const short* dev_scifi_lf_candidates,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::TrackHits* dev_scifi_tracks,
  int* dev_atomics_scifi,
  const uint8_t relative_middle_layer)
{
  // Keep best for each h1 hit
  __shared__ float best_chi2[LookingForward::maximum_number_of_candidates];
  __shared__ int8_t best_h0_h2[2 * LookingForward::maximum_number_of_candidates];
  __shared__ int8_t best_triplets[LookingForward::maximum_number_of_triplets_per_ut_track];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  // const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  // ut_event_number_of_tracks
  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_track_index = ut_event_tracks_offset + i;
    const auto scifi_lf_candidates = dev_scifi_lf_candidates + current_track_index * LookingForward::number_of_x_layers *
                                                           LookingForward::maximum_number_of_candidates;

    // Initialize shared memory buffers
    __syncthreads();

    // Initialize the best_ shared memory buffers
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates; j += blockDim.x) {
      best_chi2[j] = dev_looking_forward_constants->chi2_mean_triplet[relative_middle_layer - 1] +
                     2.5f * dev_looking_forward_constants->chi2_stddev_triplet[relative_middle_layer - 1];

      // The "best_h2" part of best_h0_h2 is not initialized
      // This is on purpose, it doesn't need to be
      best_h0_h2[j] = -1;
    }
    __syncthreads();

    const auto qop = dev_ut_qop[current_track_index];

    const auto candidate_h0_offset = dev_scifi_lf_number_of_candidates
      [current_track_index * LookingForward::number_of_x_layers + relative_middle_layer - 1];
    const auto candidate_h1_offset = dev_scifi_lf_number_of_candidates
      [current_track_index * LookingForward::number_of_x_layers + relative_middle_layer];
    const auto candidate_h2_offset = dev_scifi_lf_number_of_candidates
      [current_track_index * LookingForward::number_of_x_layers + relative_middle_layer + 1];
    const uint8_t candidate_h0_size = candidate_h1_offset - candidate_h0_offset;
    const uint8_t candidate_h1_size = candidate_h2_offset - candidate_h1_offset;
    const uint8_t candidate_h2_size =
      dev_scifi_lf_number_of_candidates
        [current_track_index * LookingForward::number_of_x_layers + relative_middle_layer + 2] -
      candidate_h2_offset;

    const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer - 1];
    const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer];
    const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer + 1];

    lf_triplet_seeding_impl(
      scifi_hits.x0 + event_offset,
      candidate_h0_size,
      candidate_h1_size,
      candidate_h2_size,
      relative_middle_layer,
      dev_looking_forward_constants->chi2_mean_triplet[relative_middle_layer - 1] +
        2.5f * dev_looking_forward_constants->chi2_stddev_triplet[relative_middle_layer - 1],
      best_chi2,
      best_h0_h2,
      scifi_lf_candidates,
      z0,
      z1,
      z2,
      qop);

    // Initialize best_triplets to -1
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_triplets_per_ut_track; j += blockDim.x) {
      best_triplets[j] = -1;
    }

    __syncthreads();

    // Now, we have the best candidates populated in best_chi2 and best_h0_h2
    // Sort the candidates (insertion sort) into best_triplets
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_candidates; j += blockDim.x) {
      if (best_h0_h2[j] != -1) {
        const float chi2 = best_chi2[j];
        int16_t insert_position = 0;
        for (uint8_t k = 0; k < LookingForward::maximum_number_of_candidates; ++k) {
          const float other_chi2 = best_chi2[k];
          if (chi2 > other_chi2 || (chi2 == other_chi2 && j < k)) {
            ++insert_position;
          }
        }
        if (insert_position < LookingForward::maximum_number_of_triplets_per_ut_track) {
          best_triplets[insert_position] = j;
        }
      }
    }

    __syncthreads();

    // Insert the triplets in best_triplets at will
    for (uint16_t j = threadIdx.x; j < LookingForward::maximum_number_of_triplets_per_ut_track; j += blockDim.x) {
      const int8_t k = best_triplets[j];
      if (k != -1) {
        // Create triplet candidate with all information we have
        const int current_insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
        if (current_insert_index < SciFi::Constants::max_lf_tracks) {
          const uint16_t h0 = (uint16_t) scifi_lf_candidates[(relative_middle_layer - 1) * LookingForward::maximum_number_of_candidates + best_h0_h2[k]];
          const uint16_t h1 = (uint16_t) scifi_lf_candidates[relative_middle_layer * LookingForward::maximum_number_of_candidates + k];
          const uint16_t h2 = (uint16_t) scifi_lf_candidates[(relative_middle_layer + 1) * LookingForward::maximum_number_of_candidates +
             best_h0_h2[LookingForward::maximum_number_of_candidates_flagged + k]];

          const float x0 = scifi_hits.x0[event_offset + h0];
          const float x1 = scifi_hits.x0[event_offset + h1];

          dev_scifi_tracks[event_number * SciFi::Constants::max_lf_tracks + current_insert_index] =
            SciFi::TrackHits {h0,
                              h1,
                              h2,
                              best_h0_h2[k],
                              k,
                              best_h0_h2[LookingForward::maximum_number_of_candidates_flagged + k],
                              best_chi2[k],
                              LookingForward::qop_update(
                                dev_ut_states[current_track_index].tx,
                                x0,
                                z0,
                                x1,
                                z1,
                                dev_looking_forward_constants->ds_p_param_layer_inv[relative_middle_layer - 1]),
                              i};
        }
      }
    }
  }
}
