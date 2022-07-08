/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFTripletSeeding.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"
#include "WarpIntrinsicsTools.cuh"
#include "memory_optim.cuh"

INSTANTIATE_ALGORITHM(lf_triplet_seeding::lf_triplet_seeding_t)

void lf_triplet_seeding::lf_triplet_seeding_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  const bool with_ut = first<host_track_type_id_t>(arguments) == Allen::TypeIDs::VeloUTTracks;
  const auto n_seeds = with_ut ? LookingForward::InputUT::n_seeds : LookingForward::InputVelo::n_seeds;

  set_size<dev_scifi_lf_found_triplets_t>(
    arguments,
    first<host_number_of_reconstructed_input_tracks_t>(arguments) * property<maximum_number_of_triplets_per_warp_t>() *
      n_seeds);
  set_size<dev_scifi_lf_number_of_found_triplets_t>(
    arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments));
  set_size<dev_global_count_t>(arguments, 1);
  set_size<dev_global_xs_t>(arguments, first<host_scifi_hit_count_t>(arguments));
}

void lf_triplet_seeding::lf_triplet_seeding_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_lf_number_of_found_triplets_t>(arguments, 0, context);
  Allen::memset_async<dev_global_count_t>(arguments, 0, context);

  constexpr int number_of_threads_y = 4;

  global_function(lf_triplet_seeding)(
    dim3(size<dev_event_list_t>(arguments)),
    dim3(warp_size, number_of_threads_y),
    context,
    number_of_threads_y * sizeof(unsigned) + // shared_number_of_elements
      number_of_threads_y * property<maximum_number_of_triplets_per_warp_t>() * sizeof(short) // shared_store
    )(arguments, constants.dev_looking_forward_constants);
}

#if defined(TARGET_DEVICE_CUDA)
__device__ inline __half2 calc_z_mag_diff_cond(
  const __half2 x0,
  const __half2 x2,
  const __half2 zdiff_inverse_dz2,
  const __half2 x_at_z_magnet,
  const __half2 z_mag_difference)
{
  const auto track_x_at_z_magnet = x0 + zdiff_inverse_dz2 * (x0 - x2);
  return __hltu2(__habs2(x_at_z_magnet - track_x_at_z_magnet), z_mag_difference);
}

template<bool limit_per_thread>
__device__ inline void find_l0_l2_layers(
  const int l0_half_start,
  const int l2_half_start,
  const int l0_half_size,
  const int l2_half_size,
  const __half2 zdiff_inverse_dz2,
  const __half2 x_at_z_magnet,
  const __half2 z_mag_difference,
  const half_t* __restrict__ shared_xs,
  unsigned* __restrict__ shared_number_of_elements,
  short* __restrict__ shared_warp_store,
  const unsigned maximum_number_of_triplets_per_warp)
{
  [[maybe_unused]] unsigned found_triplets_thread = 0;
  const auto* __restrict__ shared_xs_half2 = reinterpret_cast<const __half2*>(shared_xs);
  for (unsigned index = threadIdx.x; index < l0_half_size * l2_half_size; index += blockDim.x) {
    const auto h0_rel = index % l0_half_size;
    const auto h2_rel = index / l0_half_size;

    const auto x0 = shared_xs_half2[l0_half_start + h0_rel];
    const auto x2 = shared_xs_half2[l2_half_start + h2_rel];

    // Calculate the four combinations
    const auto z_mag_diff_condition_0 =
      calc_z_mag_diff_cond(x0, x2, zdiff_inverse_dz2, x_at_z_magnet, z_mag_difference);
    const auto z_mag_diff_condition_u0 = *reinterpret_cast<const uint32_t*>(&z_mag_diff_condition_0);

    const auto z_mag_diff_condition_1 =
      calc_z_mag_diff_cond(__lowhigh2highlow(x0), x2, zdiff_inverse_dz2, x_at_z_magnet, z_mag_difference);
    const auto z_mag_diff_condition_u1 = *reinterpret_cast<const uint32_t*>(&z_mag_diff_condition_1);

    if (z_mag_diff_condition_u0 > 0 || z_mag_diff_condition_u1 > 0) {
      const std::array<bool, 4> found = {static_cast<bool>((z_mag_diff_condition_u0 >> 10) & 0x1),
                                         static_cast<bool>((z_mag_diff_condition_u1 >> 10) & 0x1),
                                         static_cast<bool>((z_mag_diff_condition_u1 >> 26) & 0x1),
                                         static_cast<bool>((z_mag_diff_condition_u0 >> 26) & 0x1)};
      const auto number_of_pairs = found[0] + found[1] + found[2] + found[3];

      if constexpr (limit_per_thread) {
        for (unsigned i = 0; i < found.size(); ++i) {
          if (found[i] && found_triplets_thread++ < maximum_number_of_triplets_per_warp / blockDim.x) {
            const auto shared_index = atomicAdd(shared_number_of_elements, 1);
            shared_warp_store[shared_index] = 4 * index + i;
          }
        }
      }
      else {
        const auto shared_index = atomicAdd(shared_number_of_elements, number_of_pairs);
        if (shared_index + number_of_pairs < maximum_number_of_triplets_per_warp) {
          int n_found = 0;
          for (unsigned i = 0; i < found.size(); ++i) {
            if (found[i]) {
              shared_warp_store[shared_index + n_found++] = 4 * index + i;
            }
          }
        }
      }
    }
  }
}

__device__ void find_triplets_no_ut(
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const float x_at_z_magnet,
  const half_t* shared_xs,
  short* shared_warp_store,
  unsigned* shared_number_of_elements,
  SciFi::lf_triplet::t* scifi_lf_found_triplets,
  unsigned* scifi_lf_number_of_found_triplets,
  const unsigned triplet_seed,
  const unsigned left_right_side,
  const unsigned maximum_number_of_triplets_per_warp,
  const float chi2_max_triplet_single,
  const float z_mag_difference)
{
  __syncwarp();

  const auto l0_half_size = (l0_size + 2) / 2;
  const auto inverse_dz2 = 1.f / (z0 - z2);

  find_l0_l2_layers<false>(
    l0_start / 2,
    l2_start / 2,
    l0_half_size,
    (l2_size + 2) / 2,
    __float2half2_rn((LookingForward::z_magnet - z0) * inverse_dz2),
    __float2half2_rn(x_at_z_magnet),
    __float2half2_rn(z_mag_difference),
    shared_xs,
    shared_number_of_elements,
    shared_warp_store,
    maximum_number_of_triplets_per_warp);

  // Due to shared_warp_store
  __syncwarp();

  // If we found too many tracks the result would be non-deterministic.
  // In that very unlikely case, take the hit and make the result deterministic.
  if (shared_number_of_elements[0] > maximum_number_of_triplets_per_warp) {
    if (threadIdx.x == 0) {
      shared_number_of_elements[0] = 0;
    }
    __syncwarp();
    find_l0_l2_layers<true>(
      l0_start / 2,
      l2_start / 2,
      l0_half_size,
      (l2_size + 2) / 2,
      __float2half2_rn((LookingForward::z_magnet - z0) * inverse_dz2),
      __float2half2_rn(x_at_z_magnet),
      __float2half2_rn(z_mag_difference),
      shared_xs,
      shared_number_of_elements,
      shared_warp_store,
      maximum_number_of_triplets_per_warp);
    __syncwarp();
  }

  const unsigned number_of_elements_warp = shared_number_of_elements[0];
  const auto constant_expected_x1 =
    (triplet_seed == 0 ? LookingForward::sagitta_alignment_x1_triplet0 : LookingForward::sagitta_alignment_x1_triplet1);

  // Match {l0, l2} pairs with l1 hits
  for (unsigned index = threadIdx.x; index < number_of_elements_warp; index += blockDim.x) {
    const auto element_index = shared_warp_store[index];

    const auto group = element_index / 4;
    const auto index_within_group = element_index % 4;

    const auto h0_rel = 2 * (group % l0_half_size) + (index_within_group & 0x1) - (l0_start & 0x1);
    const auto h2_rel = 2 * (group / l0_half_size) + index_within_group / 2 - (l2_start & 0x1);

    if (h0_rel < 0 || h2_rel < 0 || h0_rel >= l0_size || h2_rel >= l2_size) {
      continue;
    }

    const auto x0 = (float) shared_xs[l0_start + h0_rel];
    const auto x2 = (float) shared_xs[l2_start + h2_rel];

    // Extrapolation
    const float slope_t1_t3 = (x0 - x2) * inverse_dz2;
    const half_t expected_x1 = z1 * slope_t1_t3 + (x0 - slope_t1_t3 * z0) * constant_expected_x1;

    // Linear search of candidate
    const auto candidate_index =
      linear_search(shared_xs + l1_start, l1_size, expected_x1, h0_rel < l1_size ? h0_rel : l1_size - 1);

    half_t best_chi2 = chi2_max_triplet_single;
    int best_h1_rel = -1;

    // It is now either candidate_index - 1 or candidate_index
    for (int h1_rel = candidate_index - 1; h1_rel < candidate_index + 1; ++h1_rel) {
      if (h1_rel >= 0 && h1_rel < l1_size) {
        const auto x1 = shared_xs[l1_start + h1_rel];
        const auto chi2 = (x1 - expected_x1) * (x1 - expected_x1);

        if (chi2 < best_chi2) {
          best_chi2 = chi2;
          best_h1_rel = h1_rel;
        }
      }
    }

    if (best_h1_rel != -1) {
      const auto address = atomicAdd(scifi_lf_number_of_found_triplets, 1);
      const auto ichi2 = reinterpret_cast<uint16_t*>(&best_chi2);
      scifi_lf_found_triplets[address] = SciFi::lf_triplet {static_cast<unsigned>(h0_rel),
                                                            static_cast<unsigned>(best_h1_rel),
                                                            static_cast<unsigned>(h2_rel),
                                                            triplet_seed,
                                                            left_right_side,
                                                            ichi2[0]};
    }
  }

  __syncwarp();
}
#endif

template<bool with_ut, bool limit_per_thread>
__device__ inline void find_l0_l2_layers(
  const int l0_start,
  const int l2_start,
  const int l0_size,
  const int l2_size,
  [[maybe_unused]] const float z0,
  [[maybe_unused]] const float velo_tx,
  [[maybe_unused]] const float input_track_tx,
  [[maybe_unused]] const float qop,
  [[maybe_unused]] const float opening_x_at_z_magnet_diff,
  const float inverse_dz2,
  const float x_at_z_magnet,
  const float z_mag_difference,
  const half_t* __restrict__ shared_xs,
  unsigned* __restrict__ shared_number_of_elements,
  short* __restrict__ shared_warp_store,
  const unsigned maximum_number_of_triplets_per_warp)
{
  // Determine layer 0 / layer 2 hit combinations that pass the cut
  [[maybe_unused]] unsigned found_triplets_thread = 0;
  for (int index = threadIdx.x; index < l0_size * l2_size; index += blockDim.x) {
    const auto h0_rel = index % l0_size;
    const auto h2_rel = index / l0_size;
    const auto x0 = (float) shared_xs[l0_start + h0_rel];
    const auto x2 = (float) shared_xs[l2_start + h2_rel];

    // Extrapolation
    const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
    // Use a simple correction once T1-T2 hits are known to align expected position according to Sagitta-Quality
    // Same approach used in Seeding. Might be improved exploiting other dependencies (here only the line propagation
    // at 0)

    // Compute as well the x(z-magnet) from Velo-UT (or Velo) and SciFi doublet( T1 +T3 ) to check if
    // charge assumption is correct. The best Chi2 triplet is based on expected_x1. The more precise we can go on
    // this, the bigger the gain. Currently at low momentum spreads up to 5 mm in x-true - expected_t1 (after
    // correection) We might could benefit with some more math of a q/p (updated) dependence and tx-SciFi dependence

    const bool process_element = [&]() {
      if constexpr (with_ut) {
        const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
        const auto x_at_z_magnet_diff = fabsf(
          track_x_at_z_magnet - x_at_z_magnet -
          (LookingForward::x_at_z_p0 + LookingForward::x_at_z_p1 * slope_t1_t3 +
           LookingForward::x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
           LookingForward::x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));
        const auto equal_signs_in_slopes = signbit(slope_t1_t3 - velo_tx) == signbit(input_track_tx - velo_tx);
        const auto do_slope_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);
        const bool process_element_ut =
          x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_slope_sign_check || equal_signs_in_slopes);
        return process_element_ut;
      }
      else {
        const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
        const auto z_mag_diff_condition = fabsf(x_at_z_magnet - track_x_at_z_magnet) < z_mag_difference;
        return z_mag_diff_condition;
      }
    }();

    if (process_element) {
      if constexpr (limit_per_thread) {
        if (found_triplets_thread++ < maximum_number_of_triplets_per_warp / blockDim.x) {
          const auto shared_index = atomicAdd(shared_number_of_elements, 1);
          shared_warp_store[shared_index] = index;
        }
      }
      else {
        const auto shared_index = atomicAdd(shared_number_of_elements, 1);
        if (shared_index < maximum_number_of_triplets_per_warp) {
          shared_warp_store[shared_index] = index;
        }
      }
    }
  }
}

template<bool with_ut>
__device__ void find_triplets(
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const float qop,
  const float input_track_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  const half_t* shared_xs,
  short* shared_warp_store,
  unsigned* shared_number_of_elements,
  SciFi::lf_triplet::t* scifi_lf_found_triplets,
  unsigned* scifi_lf_number_of_found_triplets,
  const unsigned triplet_seed,
  const unsigned left_right_side,
  const unsigned maximum_number_of_triplets_per_warp,
  const float chi2_max_triplet_single,
  const float z_mag_difference)
{
  __syncwarp();

  const auto inverse_dz2 = 1.f / (z0 - z2);
  const auto constant_expected_x1 =
    (triplet_seed == 0 ? LookingForward::sagitta_alignment_x1_triplet0 : LookingForward::sagitta_alignment_x1_triplet1);

  [[maybe_unused]] const auto opening_x_at_z_magnet_diff = [&]() {
    if constexpr (with_ut) {
      const auto qop_range = fabsf(qop) > LookingForward::linear_range_qop_end ?
                               1.f :
                               fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
      const auto opening_x_at_z_magnet_diff_value =
        LookingForward::x_at_magnet_range_0 +
        qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);
      return opening_x_at_z_magnet_diff_value;
    }
    else {
      // no info about momentum
      return 0;
    }
  }();

  find_l0_l2_layers<with_ut, false>(
    l0_start,
    l2_start,
    l0_size,
    l2_size,
    z0,
    velo_tx,
    input_track_tx,
    qop,
    opening_x_at_z_magnet_diff,
    inverse_dz2,
    x_at_z_magnet,
    z_mag_difference,
    shared_xs,
    shared_number_of_elements,
    shared_warp_store,
    maximum_number_of_triplets_per_warp);

  // Due to shared_warp_store
  __syncwarp();

  // If we found too many tracks the result would be non-deterministic.
  // In that very unlikely case, take the hit and make the result deterministic.
  if (shared_number_of_elements[0] > maximum_number_of_triplets_per_warp) {
    if (threadIdx.x == 0) {
      shared_number_of_elements[0] = 0;
    }
    __syncwarp();
    find_l0_l2_layers<with_ut, true>(
      l0_start,
      l2_start,
      l0_size,
      l2_size,
      z0,
      velo_tx,
      input_track_tx,
      qop,
      opening_x_at_z_magnet_diff,
      inverse_dz2,
      x_at_z_magnet,
      z_mag_difference,
      shared_xs,
      shared_number_of_elements,
      shared_warp_store,
      maximum_number_of_triplets_per_warp);
    __syncwarp();
  }

  const unsigned number_of_elements_warp = shared_number_of_elements[0];

  // Match {l0, l2} pairs with l1 hits
  for (unsigned index = threadIdx.x; index < number_of_elements_warp; index += blockDim.x) {
    const auto element_index = shared_warp_store[index];

    const auto h0_rel = element_index % l0_size;
    const auto h2_rel = element_index / l0_size;
    const auto x0 = (float) shared_xs[l0_start + h0_rel];
    const auto x2 = (float) shared_xs[l2_start + h2_rel];

    // Extrapolation
    const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
    const half_t expected_x1 = z1 * slope_t1_t3 + (x0 - slope_t1_t3 * z0) * constant_expected_x1;

    // Linear search of candidate
    const auto candidate_index =
      linear_search(shared_xs + l1_start, l1_size, expected_x1, h0_rel < l1_size ? h0_rel : l1_size - 1);

    half_t best_chi2 = chi2_max_triplet_single;
    int best_h1_rel = -1;

    // It is now either candidate_index - 1 or candidate_index
    for (int h1_rel = candidate_index - 1; h1_rel < candidate_index + 1; ++h1_rel) {
      if (h1_rel >= 0 && h1_rel < l1_size) {
        const auto x1 = shared_xs[l1_start + h1_rel];
        const auto chi2 = (x1 - expected_x1) * (x1 - expected_x1);

        if (chi2 < best_chi2) {
          best_chi2 = chi2;
          best_h1_rel = h1_rel;
        }
      }
    }

    if (best_h1_rel != -1) {
      const auto address = atomicAdd(scifi_lf_number_of_found_triplets, 1);
      const auto ichi2 = reinterpret_cast<uint16_t*>(&best_chi2);
      scifi_lf_found_triplets[address] = SciFi::lf_triplet {static_cast<unsigned>(h0_rel),
                                                            static_cast<unsigned>(best_h1_rel),
                                                            static_cast<unsigned>(h2_rel),
                                                            triplet_seed,
                                                            left_right_side,
                                                            ichi2[0]};
    }
  }

  __syncwarp();
}

template<bool with_ut, typename T>
__device__ void triplet_seeding(
  lf_triplet_seeding::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const T* tracks)
{
  const unsigned n_seeds = with_ut ? LookingForward::InputUT::n_seeds : LookingForward::InputVelo::n_seeds;

  const unsigned maximum_number_of_triplets_per_warp = parameters.maximum_number_of_triplets_per_warp;

  DYNAMIC_SHARED_MEMORY_BUFFER(unsigned, shared_memory, parameters.config)
  unsigned* shared_number_of_elements = shared_memory;
  short* shared_store = reinterpret_cast<short*>(shared_number_of_elements + blockDim.y);

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const unsigned number_of_elements_initial_window = with_ut ?
                                                       LookingForward::InputUT::number_of_elements_initial_window :
                                                       LookingForward::InputVelo::number_of_elements_initial_window;

  const auto velo_states_view = parameters.dev_velo_states_view[event_number];
  const auto input_tracks_view = tracks->container(event_number);

  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  // SciFi hits
  const unsigned total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};
  const auto event_offset = scifi_hit_count.event_offset();

  // Create shared side xs, only with the hits of three layers of the side to look into
  constexpr unsigned shared_xs_size = 2000;
  __shared__ half_t shared_xs[shared_xs_size];
  unsigned shared_xs_offsets[LookingForward::number_of_x_layers + 1];
  unsigned zone_offsets[LookingForward::number_of_x_layers];

  for (unsigned y_side = blockIdx.y; y_side < 2; y_side += gridDim.y) {
    const auto i_zone_starting_point = y_side == 1 ? LookingForward::number_of_x_layers : 0;

    __syncthreads();

    shared_xs_offsets[0] = 0;
    for (int i = 0; i < LookingForward::number_of_x_layers; ++i) {
      const auto i_zone = i_zone_starting_point + i;

      shared_xs_offsets[i + 1] =
        shared_xs_offsets[i] + scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->xZones[i_zone]);

      zone_offsets[i] = scifi_hit_count.zone_offset(dev_looking_forward_constants->xZones[i_zone]);
    }

    // Padded size to maintain alignment to 4 (__half2)
    const auto padded_size = shared_xs_offsets[LookingForward::number_of_x_layers] +
                             (shared_xs_offsets[LookingForward::number_of_x_layers] % 4);
    shared_or_global(
      padded_size,
      shared_xs_size,
      shared_xs,
      parameters.dev_global_xs.get(),
      parameters.dev_global_count.get(),
      [&](half_t* __restrict__ xs) {
        for (int i = 0; i < LookingForward::number_of_x_layers; ++i) {
          for (unsigned i_hit = threadIdx.x * blockDim.y + threadIdx.y;
               i_hit < shared_xs_offsets[i + 1] - shared_xs_offsets[i];
               i_hit += blockDim.x * blockDim.y) {
            xs[shared_xs_offsets[i] + i_hit] = static_cast<half_t>(scifi_hits.x0(zone_offsets[i] + i_hit));
          }
        }

        __syncthreads();

        for (unsigned i_number_of_track = threadIdx.y;
             i_number_of_track < parameters.dev_scifi_lf_number_of_tracks[number_of_events * y_side + event_number];
             i_number_of_track += blockDim.y) {
          const auto track_index =
            parameters
              .dev_scifi_lf_tracks_indices[total_number_of_tracks * y_side + event_tracks_offset + i_number_of_track];
          const auto current_input_track_index = event_tracks_offset + track_index;
          const auto input_track = input_tracks_view.track(track_index);
          const auto* initial_windows = parameters.dev_scifi_lf_initial_windows + current_input_track_index;

          [[maybe_unused]] const auto qop = [&]() {
            if constexpr (with_ut) {
              return input_track.qop();
            }
            else {
              return 0;
            }
          }();

          // different ways to access velo track depend on the input track
          const auto velo_state = [&input_track, velo_states_view]() {
            if constexpr (with_ut) {
              const auto velo_track = input_track.velo_track();
              return velo_track.state(velo_states_view);
            }
            else {
              return input_track.state(velo_states_view);
            }
          }();

          const auto velo_tx = velo_state.tx();
          const auto x_at_z_magnet = velo_state.x() + (LookingForward::z_magnet - velo_state.z()) * velo_tx;

          for (unsigned i_seed = 0; i_seed < n_seeds; ++i_seed) {
            const unsigned left_right_side = i_seed / 2;
            const unsigned triplet_seed = i_seed % 2;

            const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
            const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
            const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

            const int l0_size = initial_windows
              [(layer_0 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];
            const int l1_size = initial_windows
              [(layer_1 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];
            const int l2_size = initial_windows
              [(layer_2 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];

            if (l0_size == 0 || l1_size == 0 || l2_size == 0) {
              continue;
            }

            const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
            const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];
            const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

            const int l0_start =
              shared_xs_offsets[triplet_seed] +
              initial_windows
                [(layer_0 * number_of_elements_initial_window + left_right_side * 2) * total_number_of_tracks] -
              (zone_offsets[triplet_seed] - event_offset);
            const int l1_start =
              shared_xs_offsets[2 + triplet_seed] +
              initial_windows
                [(layer_1 * number_of_elements_initial_window + left_right_side * 2) * total_number_of_tracks] -
              (zone_offsets[2 + triplet_seed] - event_offset);
            const int l2_start =
              shared_xs_offsets[4 + triplet_seed] +
              initial_windows
                [(layer_2 * number_of_elements_initial_window + left_right_side * 2) * total_number_of_tracks] -
              (zone_offsets[4 + triplet_seed] - event_offset);

            if (threadIdx.x == 0) {
              shared_number_of_elements[threadIdx.y] = 0;
            }

#if defined(TARGET_DEVICE_CUDA)
            if constexpr (!with_ut) {
              find_triplets_no_ut(
                l0_start,
                l1_start,
                l2_start,
                l0_size,
                l1_size,
                l2_size,
                z0,
                z1,
                z2,
                x_at_z_magnet,
                xs,
                shared_store + threadIdx.y * maximum_number_of_triplets_per_warp,
                shared_number_of_elements + threadIdx.y,
                parameters.dev_scifi_lf_found_triplets +
                  current_input_track_index * parameters.maximum_number_of_triplets_per_warp * n_seeds,
                parameters.dev_scifi_lf_number_of_found_triplets + current_input_track_index,
                triplet_seed,
                left_right_side,
                maximum_number_of_triplets_per_warp,
                parameters.chi2_max_triplet_single.get(),
                parameters.z_mag_difference.get());
            }
            else {
#endif
              find_triplets<with_ut>(
                l0_start,
                l1_start,
                l2_start,
                l0_size,
                l1_size,
                l2_size,
                z0,
                z1,
                z2,
                qop,
                (parameters.dev_input_states + current_input_track_index)->tx,
                velo_state.tx(),
                x_at_z_magnet,
                xs,
                shared_store + threadIdx.y * maximum_number_of_triplets_per_warp,
                shared_number_of_elements + threadIdx.y,
                parameters.dev_scifi_lf_found_triplets +
                  current_input_track_index * parameters.maximum_number_of_triplets_per_warp * n_seeds,
                parameters.dev_scifi_lf_number_of_found_triplets + current_input_track_index,
                triplet_seed,
                left_right_side,
                maximum_number_of_triplets_per_warp,
                parameters.chi2_max_triplet_single.get(),
                parameters.z_mag_difference.get());
#if defined(TARGET_DEVICE_CUDA)
            }
#endif
          }
        }
      });
  }
}

__global__ void lf_triplet_seeding::lf_triplet_seeding(
  lf_triplet_seeding::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    triplet_seeding<true>(parameters, dev_looking_forward_constants, ut_tracks);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    triplet_seeding<false>(parameters, dev_looking_forward_constants, velo_tracks);
  }
}
