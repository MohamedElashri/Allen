#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "TrackUtils.cuh"

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
  bool* dev_scifi_lf_candidates_flag,
  const uint8_t relative_middle_layer)
{
  // Keep best for each h1 hit
  __shared__ float best_chi2[64];
  __shared__ int8_t best_h0_h2[128];

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
  const SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
  // for (uint16_t i = 0; i < ut_event_number_of_tracks; ++i) {
    // printf("ut_event_number_of_tracks: %i\n", ut_event_number_of_tracks);
    // for (uint16_t i = 0; i < 10; ++i) {
    const auto current_track_index = ut_event_tracks_offset + i;
    const auto qop = dev_ut_qop[current_track_index];
    // const auto ut_state = dev_ut_states[current_track_index];
    // const float z_ref_track = SciFi::Tracking::zReference;
    // const float x_at_ref = xFromVelo(z_ref_track, ut_state);
    // const float z_mag = LookingForward::zMagnetParams_0 +
    //                LookingForward::zMagnetParams_2 * ut_state.tx * ut_state.tx +
    //                LookingForward::zMagnetParams_3 * ut_state.ty * ut_state.ty;

    // Initialize the best_ shared memory buffers
    __syncthreads();
    for (uint16_t j = threadIdx.x; j < 64; j += blockDim.x) {
      best_chi2[j] = dev_looking_forward_constants->chi2_mean_triplet[relative_middle_layer - 1] +
                     2.5f * dev_looking_forward_constants->chi2_stddev_triplet[relative_middle_layer - 1];

      // The "best_h2" part of best_h0_h2 is not initialized
      // This is on purpose, it doesn't need to be
      best_h0_h2[j] = -1;
    }
    __syncthreads();

    // const auto candidate_h1_index = candidate_h1_offset + j;
    // const auto h1_rel_index = dev_scifi_lf_candidates[candidate_h1_index];
    // const auto x1 = scifi_hits.x0[event_offset + h1_rel_index];

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

    lf_triplet_seeding_impl(
      scifi_hits,
      candidate_h0_size,
      candidate_h1_size,
      candidate_h2_size,
      relative_middle_layer,
      dev_scifi_lf_candidates +
        current_track_index * LookingForward::number_of_x_layers * LookingForward::maximum_number_of_candidates,
      dev_looking_forward_constants->chi2_mean_triplet[relative_middle_layer - 1] +
        2.5f * dev_looking_forward_constants->chi2_stddev_triplet[relative_middle_layer - 1],
      best_chi2,
      best_h0_h2,
      event_offset,
      dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer - 1],
      dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer],
      dev_looking_forward_constants->Zone_zPos_xlayers[relative_middle_layer + 1],
      qop);

    // Now, we have the best candidates populated in best_chi2 and best_h0_h2
    // For now, keep all of them
    for (uint16_t j = threadIdx.x; j < 64; j += blockDim.x) {
      if (best_h0_h2[j] != -1) {
        // Create triplet candidate with all information we have
        const int current_insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
        assert(current_insert_index < SciFi::Constants::max_tracks);

        if (current_insert_index < SciFi::Constants::max_tracks) {
          dev_scifi_tracks[event_number * SciFi::Constants::max_tracks + current_insert_index] = SciFi::TrackHits {
            (uint16_t) dev_scifi_lf_candidates
              [(relative_middle_layer - 1) * LookingForward::maximum_number_of_candidates + best_h0_h2[j]],
            (uint16_t)
              dev_scifi_lf_candidates[relative_middle_layer * LookingForward::maximum_number_of_candidates + j],
            (uint16_t) dev_scifi_lf_candidates
              [(relative_middle_layer + 1) * LookingForward::maximum_number_of_candidates + best_h0_h2[64 + j]],
            best_chi2[j],
            // TODO: Update qop
            qop,
            i};
        }
      }
    }
  }
}
