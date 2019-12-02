#include "PrefixSum.cuh"
#include "Invoke.cuh"

void copy_and_prefix_sum_single_block_velo_t::invoke() {
  invoke_helper(handler);
}

void copy_velo_track_hit_number_t::invoke() {
  invoke_helper(handler);
}

void copy_and_prefix_sum_single_block_ut_t::invoke() {
  invoke_helper(handler);
}

void copy_ut_track_hit_number_t::invoke() {
  invoke_helper(handler);
}

void copy_and_prefix_sum_single_block_scifi_t::invoke() {
  invoke_helper(handler);
}

void copy_scifi_track_hit_number_t::invoke() {
  invoke_helper(handler);
}

void copy_and_prefix_sum_single_block_sv_t::invoke() {
  invoke_helper(handler);
}

/**
 * @brief Up-Sweep
 */
__device__ void up_sweep_2048(uint* data_block)
{
  uint starting_elem = 1;
  for (uint i = 2; i <= 2048; i <<= 1) {
    for (uint j = 0; j < (2047 + blockDim.x) / i; ++j) {
      const uint element = starting_elem + (j * blockDim.x + threadIdx.x) * i;
      if (element < 2048) {
        data_block[element] += data_block[element - (i >> 1)];
      }
    }
    starting_elem += i;
    __syncthreads();
  }
}

/**
 * @brief Down-sweep
 */
__device__ void down_sweep_2048(uint* data_block)
{
  for (uint i = 2048; i >= 2; i >>= 1) {
    for (uint j = 0; j < (2047 + blockDim.x) / i; ++j) {
      const auto element = 2047 - (j * blockDim.x + threadIdx.x) * i;
      if (element < 2048) {
        const auto other_element = element - (i >> 1);
        const auto value = data_block[other_element];
        data_block[other_element] = data_block[element];
        data_block[element] += value;
      }
    }
    __syncthreads();
  }
}

__device__ void
prefix_sum_single_block_implementation(uint* dev_total_sum, uint* dev_array, const uint array_size, uint* data_block)
{
  // Prefix sum of elements in dev_array
  // Using Blelloch scan https://www.youtube.com/watch?v=mmYv3Haj6uc

  // Let's do it in blocks of 2048 (2^11)
  unsigned prev_last_elem = 0;
  for (uint block = 0; block < (array_size >> 11); ++block) {
    const uint first_elem = block << 11;

    // Load elements into shared memory, add prev_last_elem
    data_block[2 * threadIdx.x] = dev_array[first_elem + 2 * threadIdx.x];
    data_block[2 * threadIdx.x + 1] = dev_array[first_elem + 2 * threadIdx.x + 1];

    __syncthreads();

    up_sweep_2048((uint*) &data_block[0]);

    const uint new_last_elem = data_block[2047];

    __syncthreads();
    data_block[2047] = 0;
    __syncthreads();

    down_sweep_2048((uint*) &data_block[0]);

    // Store back elements
    dev_array[first_elem + 2 * threadIdx.x] = data_block[2 * threadIdx.x] + prev_last_elem;
    dev_array[first_elem + 2 * threadIdx.x + 1] = data_block[2 * threadIdx.x + 1] + prev_last_elem;
    prev_last_elem += new_last_elem;

    __syncthreads();
  }

  // Last iteration is special because
  // it may contain an unspecified number of elements
  const auto elements_remaining = array_size & 0x7FF; // % 2048
  if (elements_remaining > 0) {
    const auto first_elem = array_size - elements_remaining;

    // Initialize all elements to zero
    data_block[2 * threadIdx.x] = 0;
    data_block[2 * threadIdx.x + 1] = 0;

    // Load elements
    const auto elem_index = first_elem + 2 * threadIdx.x;
    if (elem_index < array_size) {
      data_block[2 * threadIdx.x] = dev_array[elem_index];
    }
    if ((elem_index + 1) < array_size) {
      data_block[2 * threadIdx.x + 1] = dev_array[elem_index + 1];
    }

    __syncthreads();

    up_sweep_2048((uint*) &data_block[0]);

    // Store sum of all elements
    if (threadIdx.x == 0) {
      dev_total_sum[0] = prev_last_elem + data_block[2047];
    }

    __syncthreads();
    data_block[2047] = 0;
    __syncthreads();

    down_sweep_2048((uint*) &data_block[0]);

    // Store back elements
    if (elem_index < array_size) {
      dev_array[elem_index] = data_block[2 * threadIdx.x] + prev_last_elem;
    }
    if ((elem_index + 1) < array_size) {
      dev_array[elem_index + 1] = data_block[2 * threadIdx.x + 1] + prev_last_elem;
    }
  }
  else {
    // Special case where number of elements is binary
    if (threadIdx.x == 0) {
      dev_total_sum[0] = prev_last_elem;
    }
  }
}

__global__ void prefix_sum_single_block(uint* dev_total_sum, uint* dev_array, const uint array_size)
{
  __shared__ uint data_block[2048];

  prefix_sum_single_block_implementation(dev_total_sum, dev_array, array_size, data_block);
}

__global__ void copy_and_prefix_sum_single_block(
  uint* dev_total_sum,
  uint* dev_input_array,
  uint* dev_output_array,
  const uint array_size)
{
  __shared__ uint data_block[2048];

  // Copy the input array into the output array
  for (uint i = 0; i < (array_size + blockDim.x - 1) / blockDim.x; ++i) {
    const auto element = i * blockDim.x + threadIdx.x;
    if (element < array_size) {
      dev_output_array[element] = dev_input_array[element];
    }
  }

  __syncthreads();

  // Perform prefix_sum over output array
  prefix_sum_single_block_implementation(dev_total_sum, dev_output_array, array_size, data_block);
}

__global__ void copy_square_and_prefix_sum_single_block(
  uint* dev_total_sum,
  uint* dev_input_array,
  uint* dev_output_array,
  const uint array_size)
{
  __shared__ uint data_block[2048];

  // Copy N(N-1)/2 to the output location.
  for (uint i = 0; i < (array_size + blockDim.x - 1) / blockDim.x; ++i) {
    const auto element = i * blockDim.x + threadIdx.x;
    if (element < array_size) {
      dev_output_array[element] = (dev_input_array[element] * (dev_input_array[element] - 1)) >> 1;
    }
  }
  __syncthreads();

  // Perform the prefix sum over the output array.
  prefix_sum_single_block_implementation(dev_total_sum, dev_output_array, array_size, data_block);
}

/**
 * @brief Copies Velo track hit numbers on a consecutive container
 */
__global__ void copy_velo_track_hit_number(
  const Velo::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto* event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;
  const auto accumulated_tracks = dev_atomics_storage[number_of_events + event_number];
  const auto number_of_tracks = dev_atomics_storage[event_number];

  // Pointer to velo_track_hit_number of current event
  uint* velo_track_hit_number = dev_velo_track_hit_number + accumulated_tracks;

  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    velo_track_hit_number[element] = event_tracks[element].hitsNum;
  }
}

/**
 * @brief Copies UT track hit numbers on a consecutive container.
 */
__global__ void copy_ut_track_hit_number(
  const UT::TrackHits* dev_veloUT_tracks,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto* event_tracks = dev_veloUT_tracks + event_number * UT::Constants::max_num_tracks;
  const auto accumulated_tracks = dev_atomics_veloUT[number_of_events + event_number];
  const auto number_of_tracks = dev_atomics_veloUT[event_number];

  // Pointer to ut_track_hit_number of current event.
  uint* ut_track_hit_number = dev_ut_track_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    ut_track_hit_number[element] = event_tracks[element].hits_num;
  }
}

/**
 * @brief Copies SciFi track hit numbers to a consecutive container.
 */
__global__ void copy_scifi_track_hit_number(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];

  const auto* event_tracks =
    dev_scifi_tracks + ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;
  // const SciFi::TrackHits* event_tracks =
  //   dev_scifi_tracks + ut_event_tracks_offset *
  //   LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter;
  const auto accumulated_tracks = dev_n_scifi_tracks[number_of_events + event_number];
  const auto number_of_tracks = dev_n_scifi_tracks[event_number];

  // Pointer to scifi_track_hit_number of current event.
  uint* scifi_track_hit_number = dev_scifi_track_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    scifi_track_hit_number[element] = event_tracks[element].hitsNum;
  }
}
