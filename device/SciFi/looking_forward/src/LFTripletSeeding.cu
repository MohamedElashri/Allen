/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
  const Constants&) const
{
  const bool with_ut = first<host_track_type_id_t>(arguments) == Allen::TypeIDs::VeloUTTracks;
  const auto n_seeds = with_ut ? LookingForward::InputUT::n_seeds : LookingForward::InputVelo::n_seeds;

  set_size<dev_scifi_lf_found_triplets_t>(
    arguments,
    first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_maximum_number_of_triplets_per_warp * n_seeds);
  set_size<dev_scifi_lf_number_of_found_triplets_t>(
    arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments));
  set_size<dev_global_count_t>(arguments, 1);
  set_size<dev_global_xs_t>(arguments, first<host_scifi_hit_count_t>(arguments));
}

namespace geom {
  __constant__ extern float dev_average_z_x_layers[LookingForward::number_of_x_layers];
} // namespace geom

void lf_triplet_seeding::lf_triplet_seeding_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_lf_number_of_found_triplets_t>(arguments, 0, context);
  Allen::memset_async<dev_global_count_t>(arguments, 0, context);

  constexpr int number_of_threads_y = 4;

  global_function(lf_triplet_seeding)(
    dim3(size<dev_event_list_t>(arguments)), dim3(warp_size, number_of_threads_y), context)(
    arguments,
    constants.dev_looking_forward_constants,
    m_maximum_number_of_triplets_per_warp,
    m_chi2_max_triplet_single,
    m_z_mag_difference,
    m_n_overflow_maximum_number_of_triplets_per_warp.data(context));
}

template<typename T>
__device__ unsigned int binary_search_leftmost_unrolled(const T* array, const unsigned array_size, const T& needle)
{
  unsigned int low = 0;
  unsigned int size = array_size;

  // Unroll 9 time to cover arrays of size max 512
#if defined(__clang__) or defined(__NVCC__)
#pragma unroll
#elif defined(__GNUC__)
#pragma GCC unroll 9
#endif
  for (unsigned int step = 0; step < 9; step++) {
    unsigned int half = size / 2;
    low += (array[low + half] < needle) * (size - half);
    size = half;
  } // while (size > 0);

  return low;
}

template<bool with_ut, typename T>
__device__ void triplet_seeding(
  lf_triplet_seeding::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const T* tracks,
  const unsigned maximum_number_of_triplets_per_warp,
  const float chi2_max_triplet_single,
  const float z_mag_difference_prop,
  Allen::Monitoring::Counter<>::DeviceType n_overflow_maximum_number_of_triplets_per_warp)
{
  const unsigned n_seeds = with_ut ? LookingForward::InputUT::n_seeds : LookingForward::InputVelo::n_seeds;

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
  const unsigned total_number_of_hits = parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_zones];
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
      parameters.dev_global_xs.data(),
      parameters.dev_global_count.data(),
      [&](half_t* __restrict__ shared_xs) {
        for (int i = 0; i < LookingForward::number_of_x_layers; ++i) {
          for (unsigned i_hit = threadIdx.y * blockDim.x + threadIdx.x;
               i_hit < shared_xs_offsets[i + 1] - shared_xs_offsets[i];
               i_hit += blockDim.x * blockDim.y) {
            shared_xs[shared_xs_offsets[i] + i_hit] = static_cast<half_t>(scifi_hits.x0(zone_offsets[i] + i_hit));
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

          SciFi::lf_triplet::t* scifi_lf_found_triplets =
            parameters.dev_scifi_lf_found_triplets +
            current_input_track_index * maximum_number_of_triplets_per_warp * n_seeds;
          unsigned* scifi_lf_number_of_found_triplets =
            parameters.dev_scifi_lf_number_of_found_triplets + current_input_track_index;

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

          const auto input_track_tx = (parameters.dev_input_states + current_input_track_index)->tx();
          const auto velo_tx = velo_state.tx();
          const auto x_at_z_magnet = velo_state.x() + (LookingForward::z_magnet - velo_state.z()) * velo_tx;

          float z_mag_difference;
          if constexpr (with_ut) {
            const auto qop_range = fabsf(qop) > LookingForward::linear_range_qop_end ?
                                     1.f :
                                     fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
            z_mag_difference = LookingForward::x_at_magnet_range_0 +
                               qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);
          }
          else {
            z_mag_difference = z_mag_difference_prop;
          }

          for (unsigned i_seed = 0; i_seed < n_seeds; ++i_seed) {
            const unsigned left_right_side = i_seed / 2;
            const unsigned triplet_seed = i_seed % 2;

            const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
            const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
            const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

            const unsigned l0_size = initial_windows
              [(layer_0 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];
            const unsigned l1_size = initial_windows
              [(layer_1 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];
            const unsigned l2_size = initial_windows
              [(layer_2 * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];

            if (l0_size == 0 || l1_size == 0 || l2_size == 0) {
              continue;
            }

            const auto z0 = geom::dev_average_z_x_layers[layer_0];
            const auto z1 = geom::dev_average_z_x_layers[layer_1];
            const auto z2 = geom::dev_average_z_x_layers[layer_2];

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

            const auto inverse_dz2 = 1.f / (z0 - z2);
            const auto constant_expected_x1 =
              (triplet_seed == 0 ? LookingForward::sagitta_alignment_x1_triplet0 :
                                   LookingForward::sagitta_alignment_x1_triplet1);

            const float min_xmag = x_at_z_magnet - z_mag_difference;
            const float max_xmag = x_at_z_magnet + z_mag_difference;
            const float dz_ratio = (z2 - z0) / (LookingForward::z_magnet - z0);

            for (unsigned h0_rel = threadIdx.x; h0_rel < l0_size; h0_rel += blockDim.x) {
              unsigned best_triplets[LookingForward::max_triplets_per_thread];
              for (int i = 0; i < LookingForward::max_triplets_per_thread; i++) {
                best_triplets[i] = 0xffffffff;
              }

              const float x0 = (float) shared_xs[l0_start + h0_rel];

              float min_x2 = x0 + (max_xmag - x0) * dz_ratio;
              float max_x2 = x0 + (min_xmag - x0) * dz_ratio;

              if constexpr (with_ut) {
                // Use a simple correction once T1-T2 hits are known to align expected position according to
                // Sagitta-Quality Same approach used in Seeding. Might be improved exploiting other dependencies (here
                // only the line propagation at 0)

                // Compute as well the x(z-magnet) from Velo-UT (or Velo) and SciFi doublet( T1 +T3 ) to check if
                // charge assumption is correct. The best Chi2 triplet is based on expected_x1. The more precise we can
                // go on this, the bigger the gain. Currently at low momentum spreads up to 5 mm in x-true - expected_t1
                // (after correction) We might could benefit with some more math of a q/p (updated) dependence and
                // tx-SciFi dependence
                float slope_t1_t3 = (x0 - min_x2) * inverse_dz2;
                min_x2 +=
                  dz_ratio *
                  (slope_t1_t3 * (slope_t1_t3 * (slope_t1_t3 * LookingForward::x_at_z_p3 + LookingForward::x_at_z_p2) +
                                  LookingForward::x_at_z_p1) +
                   LookingForward::x_at_z_p0);

                slope_t1_t3 = (x0 - max_x2) * inverse_dz2;
                max_x2 +=
                  dz_ratio *
                  (slope_t1_t3 * (slope_t1_t3 * (slope_t1_t3 * LookingForward::x_at_z_p3 + LookingForward::x_at_z_p2) +
                                  LookingForward::x_at_z_p1) +
                   LookingForward::x_at_z_p0);

                // do slope sign check:
                if (fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold)) {
                  if (input_track_tx - velo_tx < 0) {
                    max_x2 = min(max_x2, x0 + velo_tx * dz_ratio);
                  }
                  else {
                    min_x2 = max(min_x2, x0 + velo_tx * dz_ratio);
                  }
                }
              }

              unsigned first_h2_rel = binary_search_leftmost_unrolled(shared_xs + l2_start, l2_size, (half_t) min_x2);

              for (unsigned h2_rel = first_h2_rel; h2_rel < l2_size; h2_rel++) {
                const float x2 = (float) shared_xs[l2_start + h2_rel];
                if (x2 > max_x2) break;

                // Match {l0, l2} pairs with l1 hits
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
                  if (h1_rel >= 0 && h1_rel < (int) l1_size) {
                    const auto x1 = shared_xs[l1_start + h1_rel];
                    const auto chi2 = (x1 - expected_x1) * (x1 - expected_x1);

                    if (chi2 < best_chi2) {
                      best_chi2 = chi2;
                      best_h1_rel = h1_rel;
                    }
                  }
                }

                if (best_h1_rel != -1) {
#if defined(TARGET_DEVICE_CPU) && !defined(CPU_USE_REAL_HALF)
                  // If we were compiling for CPU with CPU_USE_REAL_HALF turned off,
                  // best_chi2 would be a float. In that case, convert it to a half prior to
                  // saving the chi2, so that the 12 bits in lf_triplets representing the chi2
                  // are as representative as in other versions.
                  const uint16_t ichi2 = compress_float_to_16_bits(best_chi2);
#else
                  const auto ichi2 = reinterpret_cast<uint16_t*>(&best_chi2)[0];
#endif
                  unsigned triplet = SciFi::lf_triplet {static_cast<unsigned>(h0_rel),
                                                        static_cast<unsigned>(best_h1_rel),
                                                        static_cast<unsigned>(h2_rel),
                                                        triplet_seed,
                                                        left_right_side,
                                                        ichi2};
                  for (int i = 0; i < LookingForward::max_triplets_per_thread; i++) {
                    if (best_triplets[i] > triplet) {
                      auto t = triplet;
                      triplet = best_triplets[i];
                      best_triplets[i] = t;
                    }
                  }
                }
              }
              for (int i = 0; i < LookingForward::max_triplets_per_thread; i++) {
                if (best_triplets[i] != 0xffffffff) {
                  const auto address = atomicAdd(scifi_lf_number_of_found_triplets, 1);
                  if (address < maximum_number_of_triplets_per_warp) {
                    scifi_lf_found_triplets[address] = best_triplets[i];
                  }
                  else {
                    break;
                  }
                }
              }
            }
            __syncwarp();
          }
        }
        __syncthreads();

        const unsigned global_dim = blockDim.x * blockDim.y;
        const unsigned global_tid = threadIdx.x + threadIdx.y * blockDim.x;
        for (unsigned i_number_of_track = global_tid;
             i_number_of_track < parameters.dev_scifi_lf_number_of_tracks[number_of_events * y_side + event_number];
             i_number_of_track += global_dim) {
          const auto track_index =
            parameters
              .dev_scifi_lf_tracks_indices[total_number_of_tracks * y_side + event_tracks_offset + i_number_of_track];
          const auto current_input_track_index = event_tracks_offset + track_index;

          unsigned* scifi_lf_number_of_found_triplets =
            parameters.dev_scifi_lf_number_of_found_triplets + current_input_track_index;

          if (*scifi_lf_number_of_found_triplets > maximum_number_of_triplets_per_warp) {
            *scifi_lf_number_of_found_triplets = 0;
            n_overflow_maximum_number_of_triplets_per_warp.increment();
          }
        }
      });
  }
}

__global__ void lf_triplet_seeding::lf_triplet_seeding(
  lf_triplet_seeding::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const unsigned maximum_number_of_triplets_per_warp,
  const float chi2_max_triplet_single,
  const float z_mag_difference,
  Allen::Monitoring::Counter<>::DeviceType n_overflow_maximum_number_of_triplets_per_warp)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventVeloUTTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    triplet_seeding<true>(
      parameters,
      dev_looking_forward_constants,
      ut_tracks,
      maximum_number_of_triplets_per_warp,
      chi2_max_triplet_single,
      z_mag_difference,
      n_overflow_maximum_number_of_triplets_per_warp);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    triplet_seeding<false>(
      parameters,
      dev_looking_forward_constants,
      velo_tracks,
      maximum_number_of_triplets_per_warp,
      chi2_max_triplet_single,
      z_mag_difference,
      n_overflow_maximum_number_of_triplets_per_warp);
  }
}
