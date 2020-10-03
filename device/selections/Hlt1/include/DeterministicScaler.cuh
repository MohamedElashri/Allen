#pragma once

#include "CudaCommon.h"
#include <algorithm>
#include <cstdint>
#include <string>

namespace {
  // Mostly a copy of LHCbMath/DeterministicPrescalerGenerator.h
  __device__ inline uint32_t mix(uint32_t state)
  {
    // note: the constants below are _not_ arbitrary, but are picked
    //       carefully such that the bit shuffling has a large 'avalanche' effect...
    //       See https://web.archive.org/web/20130918055434/http://bretm.home.comcast.net/~bretm/hash/
    //
    // note: as a result, you might call this a quasi-random (not to be confused
    //       with psuedo-random!) number generator, in that it generates an output
    //       which satisfies a requirement on the uniformity of its output distribution.
    //       (and not on the predictability of the next number in the sequence,
    //       based on knowledge of the preceding numbers)
    //
    // note: another way to look at this is is as an (approximation of an) evaporating
    //       black hole: whatever you dump in to it, you get something uniformly
    //       distributed back ;-)
    //
    state += (state << 16);
    state ^= (state >> 13);
    state += (state << 4);
    state ^= (state >> 7);
    state += (state << 10);
    state ^= (state >> 5);
    state += (state << 8);
    state ^= (state >> 16);
    return state;
  }

  // mix some 'extra' entropy into 'state' and return result
  __device__ inline uint32_t mix32(uint32_t state, uint32_t extra) { return mix(state + extra); }

  // mix some 'extra' entropy into 'state' and return result
  __device__ inline uint32_t mix64(uint32_t state, uint32_t extra_hi, uint32_t extra_lo)
  {
    state = mix32(state, extra_lo);
    return mix32(state, extra_hi);
  }

  // mix some 'extra' entropy into 'state' and return result
  __host__ inline uint32_t mix4(uint32_t s, gsl::span<const char> a)
  {
    // FIXME: this _might_ do something different on big endian vs. small endian machines...
    return mix32(s, uint32_t(a[0]) | uint32_t(a[1]) << 8 | uint32_t(a[2]) << 16 | uint32_t(a[3]) << 24);
  }

  // mix some 'extra' entropy into 'state' and return result
  __host__ inline uint32_t mixString(uint32_t state, std::string_view extra)
  {
    // prefix extra with ' ' until the size is a multiple of 4.
    if (auto rem = extra.size() % 4; rem != 0) {
      // prefix name with ' ' until the size is a multiple of 4.
      std::array<char, 4> prefix = {' ', ' ', ' ', ' '};
      std::copy_n(extra.data(), rem, std::next(prefix.data(), (4 - rem)));
      state = mix4(state, prefix);
      extra.remove_prefix(rem);
    }
    for (; !extra.empty(); extra.remove_prefix(4))
      state = mix4(state, gsl::span<const char> {extra.substr(0, 4)});
    return state;
  }

  __device__ inline bool deterministic_scaler(
    const unsigned initial_value,
    const float scale_factor,
    const uint32_t run_number,
    const uint32_t evt_number_hi,
    const uint32_t evt_number_lo,
    const uint32_t gps_time_hi,
    const uint32_t gps_time_lo)
  {
    const auto accept_threshold =
      scale_factor >= 1.f ?
        std::numeric_limits<uint32_t>::max() :
        static_cast<uint32_t>(scale_factor * static_cast<float>(std::numeric_limits<uint32_t>::max()));
    if (accept_threshold == std::numeric_limits<uint32_t>::max()) return true;

    auto x = mix64(mix32(mix64(initial_value, gps_time_hi, gps_time_lo), run_number), evt_number_hi, evt_number_lo);
    return x < accept_threshold;
  }

  __device__ inline void deterministic_post_scaler(
    const unsigned initial_value,
    const float scale_factor,
    const int n_candidates,
    bool* results,
    const uint32_t run_number,
    const uint32_t evt_number_hi,
    const uint32_t evt_number_lo,
    const uint32_t gps_time_hi,
    const uint32_t gps_time_lo)
  {
    if (!deterministic_scaler(
          initial_value, scale_factor, run_number, evt_number_hi, evt_number_lo, gps_time_hi, gps_time_lo)) {
      for (auto i_cand = 0; i_cand < n_candidates; ++i_cand) {
        results[i_cand] = 0;
      }
    }
  }
} // namespace
