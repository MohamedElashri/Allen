#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

void lf_triplet_seeding::lf_triplet_seeding_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_lf_found_triplets_t>(
    arguments,
    first<host_number_of_reconstructed_ut_tracks_t>(arguments) * LookingForward::n_triplet_seeds *
      LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread);
  set_size<dev_scifi_lf_number_of_found_triplets_t>(
    arguments,
    first<host_number_of_reconstructed_ut_tracks_t>(arguments) * LookingForward::n_triplet_seeds *
      LookingForward::triplet_seeding_block_dim_x);
}

void lf_triplet_seeding::lf_triplet_seeding_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_scifi_lf_number_of_found_triplets_t>(arguments, 0, cuda_stream);

  global_function(lf_triplet_seeding)(
    dim3(first<host_number_of_selected_events_t>(arguments)),
    dim3(LookingForward::triplet_seeding_block_dim_x, 2),
    cuda_stream)(arguments, constants.dev_looking_forward_constants);
}

__global__ void lf_triplet_seeding::lf_triplet_seeding(
  lf_triplet_seeding::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  __shared__ float shared_precalc_expected_x1[2 * LookingForward::max_number_of_hits_in_window];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo consolidated types
  Velo::Consolidated::ConstStates velo_states {
    parameters.dev_velo_states, parameters.dev_atomics_velo[number_of_events]};
  const uint velo_tracks_offset_event = parameters.dev_atomics_velo[event_number];

  // UT consolidated tracks
  UT::Consolidated::ConstExtendedTracks ut_tracks {
    parameters.dev_atomics_ut,
    parameters.dev_ut_track_hit_number,
    parameters.dev_ut_qop,
    parameters.dev_ut_track_velo_indices,
    event_number,
    number_of_events};

  const auto ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint ut_track_number = blockIdx.y; ut_track_number < ut_event_number_of_tracks; ut_track_number += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + ut_track_number;

    if (parameters.dev_scifi_lf_process_track[current_ut_track_index]) {
      const auto velo_track_index = ut_tracks.velo_track(ut_track_number);
      const auto qop = ut_tracks.qop(ut_track_number);
      const int* initial_windows = parameters.dev_scifi_lf_initial_windows + current_ut_track_index;

      const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
      const auto x_at_z_magnet =
        velo_states.x(velo_states_index) +
        (LookingForward::z_magnet - velo_states.z(velo_states_index)) * velo_states.tx(velo_states_index);

      for (uint triplet_seed = threadIdx.y; triplet_seed < LookingForward::n_triplet_seeds;
           triplet_seed += blockDim.y) {
        const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
        const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
        const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

        const int l0_size = initial_windows
          [(layer_0 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];
        const int l1_size = initial_windows
          [(layer_1 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];
        const int l2_size = initial_windows
          [(layer_2 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];

        if (l0_size > 0 && l1_size > 0 && l2_size > 0) {
          const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
          const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];
          const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

          lf_triplet_seeding_impl(
            scifi_hits.x0_p(event_offset),
            layer_0,
            layer_1,
            layer_2,
            l0_size,
            l1_size,
            l2_size,
            z0,
            z1,
            z2,
            initial_windows,
            ut_total_number_of_tracks,
            qop,
            (parameters.dev_ut_states + current_ut_track_index)->tx,
            velo_states.tx(velo_states_index),
            x_at_z_magnet,
            shared_precalc_expected_x1 + triplet_seed * LookingForward::max_number_of_hits_in_window,
            parameters.dev_scifi_lf_found_triplets +
              (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread,
            parameters.dev_scifi_lf_number_of_found_triplets +
              (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                LookingForward::triplet_seeding_block_dim_x,
            triplet_seed);
        }
      }
    }
  }
}

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint layer_0,
  const uint layer_1,
  const uint layer_2,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const int* initial_windows,
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  int* scifi_lf_found_triplets,
  int8_t* scifi_lf_number_of_found_triplets,
  const uint triplet_seed)
{
  const int l0_start =
    initial_windows[layer_0 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
  const int l1_start =
    initial_windows[layer_1 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
  const int l2_start =
    initial_windows[layer_2 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];

  const auto inverse_dz2 = 1.f / (z0 - z2);
  const auto constant_expected_x1 =
    (triplet_seed == 0 ? LookingForward::sagitta_alignment_x1_triplet0 : LookingForward::sagitta_alignment_x1_triplet1);

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_slope_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  // Due to shared_x1
  __syncthreads();

  for (int i = threadIdx.x; i < l1_size; i += blockDim.x) {
    shared_x1[i] = scifi_hits_x0[l1_start + i];
  }

  // Due to shared_x1
  __syncthreads();

  for (uint tid_x = threadIdx.x; tid_x < LookingForward::triplet_seeding_block_dim_x; tid_x += blockDim.x) {
    uint16_t number_of_found_triplets = 0;

    // Treat central window iteration
    for (int i = tid_x; i < l0_size * l2_size; i += LookingForward::triplet_seeding_block_dim_x) {
      const auto h0_rel = i % l0_size;
      const auto h2_rel = i / l0_size;

      const auto x0 = scifi_hits_x0[l0_start + h0_rel];
      const auto x2 = scifi_hits_x0[l2_start + h2_rel];

      // Extrapolation
      const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
      // Use a simple correction once T1-T2 hits are known to align expected position according to Sagitta-Quality
      // Same approach used in Seeding. Might be improved exploiting other dependencies (here only the line propagation
      // at 0)

      const auto expected_x1 = z1 * slope_t1_t3 + (x0 - slope_t1_t3 * z0) * constant_expected_x1;

      // Compute as well the x(z-magnet) from Velo-UT (or Velo) and SciFi doublet( T1 +T3 ) to check if
      // charge assumption is correct. The best Chi2 triplet is based on expected_x1. The more precise we can go on
      // this, the bigger the gain. Currently at low momentum spreads up to 5 mm in x-true - expected_t1 (after
      // correection) We might could benefit with some more math of a q/p (updated) dependence and tx-SciFi dependence

      const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
      const auto x_at_z_magnet_diff = fabsf(
        track_x_at_z_magnet - x_at_z_magnet -
        (LookingForward::x_at_z_p0 + LookingForward::x_at_z_p1 * slope_t1_t3 +
         LookingForward::x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
         LookingForward::x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - velo_tx) == signbit(ut_tx - velo_tx);
      const bool process_element =
        x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_slope_sign_check || equal_signs_in_slopes);

      if (process_element && number_of_found_triplets < LookingForward::maximum_number_of_triplets_per_thread) {
        // Binary search of candidate
        const auto candidate_index = binary_search_leftmost(shared_x1, l1_size, expected_x1);

        float best_chi2 = LookingForward::chi2_max_triplet_single;
        int best_h1_rel = -1;

        // It is now either candidate_index - 1 or candidate_index
        for (int h1_rel = candidate_index - 1; h1_rel < candidate_index + 1; ++h1_rel) {
          if (h1_rel >= 0 && h1_rel < l1_size) {
            const auto x1 = shared_x1[h1_rel];
            const auto chi2 = (x1 - expected_x1) * (x1 - expected_x1);

            if (chi2 < best_chi2) {
              best_chi2 = chi2;
              best_h1_rel = h1_rel;
            }
          }
        }

        if (best_h1_rel != -1) {
          // Store chi2, h0, h1 and h2 encoded in a 32-bit type
          // Bits (LSB):
          //  0-4: h2_rel
          //  5-9: h1_rel
          //  10-14: h0_rel
          //  15: triplet seed
          //  16-31: most significant bits of chi2
          int* best_chi2_int = reinterpret_cast<int*>(&best_chi2);
          int h0_h1_h2_rel = (triplet_seed << 15) | (h0_rel << 10) | (best_h1_rel << 5) | h2_rel;

          scifi_lf_found_triplets
            [tid_x * LookingForward::maximum_number_of_triplets_per_thread + number_of_found_triplets++] =
              (best_chi2_int[0] & 0xFFFF0000) + h0_h1_h2_rel;
        }
      }
    }

    // Store number of found triplets by this thread
    if (number_of_found_triplets > 0) {
      scifi_lf_number_of_found_triplets[tid_x] = number_of_found_triplets;
    }
  }
}
