#include "DeterministicPostscaler.cuh"

__device__ uint32_t postscaler::mix(uint32_t state)
{
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

__device__ uint32_t postscaler::mix32(uint32_t state, uint32_t extra) { return postscaler::mix(state + extra); }

__device__ uint32_t postscaler::mix64(uint32_t state, uint32_t extra_hi, uint32_t extra_lo)
{
  state = mix32(state, extra_lo);
  return postscaler::mix32(state, extra_hi);
}

__device__ void DeterministicPostscaler::operator()(
  const int n_candidates,
  bool* results,
  const uint32_t run_number,
  const uint32_t evt_number_hi,
  const uint32_t evt_number_lo,
  const uint32_t gps_time_hi,
  const uint32_t gps_time_lo)
{
  if (accept_threshold == std::numeric_limits<uint32_t>::max()) return;

  auto x = postscaler::mix64(
    postscaler::mix32(postscaler::mix64(initial_value, gps_time_hi, gps_time_lo), run_number),
    evt_number_hi,
    evt_number_lo);

  if (x >= accept_threshold) {
    for (auto i_cand = 0; i_cand < n_candidates; ++i_cand) {
      results[i_cand] = 0;
    }
  }
}
