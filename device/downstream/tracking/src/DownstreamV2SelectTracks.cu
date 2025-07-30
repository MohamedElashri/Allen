/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// This
#include "DownstreamV2SelectTracks.cuh"

// UT
#include "UTEventModel.cuh"

// Helpers
#include "DownstreamV2Constants.cuh"

// Primitives
#include "PrefixSum.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_select_tracks::downstream_v2_select_tracks_t);

namespace {
  constexpr unsigned MaxBufferSize = 2048;

  __device__ __host__ inline unsigned get_idx(unsigned key)
  {
    unsigned int out;
    if (key < MaxBufferSize) {
      out = key;
    }
    else {
      // MurmurHash3
      key ^= key >> 16;
      key *= 0x85ebca6b;
      key ^= key >> 13;
      key *= 0xc2b2ae35;
      key ^= key >> 16;
      out = (42 ^ key) % MaxBufferSize;
    }
    return out;
  }
} // namespace

void downstream_v2_select_tracks::downstream_v2_select_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_tracks = first<host_number_of_fitted_downstream_compact_tracks_t>(arguments);

  // Set sizes
  set_size<dev_downstream_compact_track_selections_t>(arguments, number_of_tracks);

  set_size<host_number_of_selected_downstream_compact_tracks_t>(arguments, 1);
  set_size<dev_selected_downstream_compact_track_offsets_t>(arguments, number_of_events + 1);
  set_size<dev_selected_downstream_compact_tracks_t>(arguments, number_of_tracks);
}

void downstream_v2_select_tracks::downstream_v2_select_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  // Perform clone killing
  Allen::memset_async<dev_selected_downstream_compact_track_offsets_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_compact_track_selections_t>(arguments, 0, context);

  global_function(downstream_v2_clone_killing)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_num_independent_hits, m_clone_killing);

  PrefixSum::
    prefix_sum<dev_selected_downstream_compact_track_offsets_t, host_number_of_selected_downstream_compact_tracks_t>(
      *this, arguments, context);
}

__global__ void downstream_v2_select_tracks::downstream_v2_clone_killing(
  Parameters parameters,
  unsigned num_independent_hits,
  bool clone_killing)
{

  // Allocate shared memory
  __shared__ int best_scores[MaxBufferSize];

  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // UT hits
  UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};

  // Offsets
  const auto input_offset = parameters.dev_downstream_compact_track_offsets[event_number];
  const auto output_offset = parameters.dev_fitted_downstream_compact_track_offsets[event_number];
  const auto input_size = parameters.dev_fitted_downstream_compact_track_offsets[event_number + 1] - output_offset;
  const auto seed_offset = parameters.dev_offsets_seeding_tracks[event_number];
  const auto number_of_seeds = parameters.dev_offsets_seeding_tracks[event_number + 1] - seed_offset;

  // Input
  const auto inputs = parameters.dev_fitted_downstream_compact_tracks + input_offset;
  const auto scores = parameters.dev_fitted_downstream_compact_track_scores + input_offset;

  // Output
  auto output_mask = parameters.dev_downstream_compact_track_selections + output_offset;
  auto output_counter = parameters.dev_selected_downstream_compact_track_offsets + event_number;
  auto output_tracks = parameters.dev_selected_downstream_compact_tracks + output_offset;

  //
  // UT clone killing
  //
  for (unsigned layer = 0; layer < 4; layer++) {
    const auto layer_offset = ut_hit_offsets.layer_offset(layer) - ut_hit_offsets.event_offset();
    const auto layer_size = min(ut_hit_offsets.layer_number_of_hits(layer), MaxBufferSize);

    // Reset buffer
    for (unsigned i = threadIdx.x; i < layer_size; i += blockDim.x) {
      best_scores[i] = std::numeric_limits<int>::max();
    }
    __syncthreads();

    // Fill
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      const auto score = scores[i];
      const auto track = inputs[i];
      const auto hit_idx = track.ut_hits[layer] - layer_offset;
      atomicMin(best_scores + get_idx(hit_idx), __float_as_int(score));
    }
    __syncthreads();

    // Clone killing
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      const auto score = scores[i];
      const auto track = inputs[i];
      const auto hit_idx = track.ut_hits[layer] - layer_offset;
      const auto best_score = best_scores[get_idx(hit_idx)];

      if (best_score == __float_as_int(score)) {
        output_mask[i] += 1;
      }
    }
    __syncthreads();
  }
  // Final decision
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    output_mask[i] = (output_mask[i] >= num_independent_hits);
  }
  __syncthreads();

  //
  // SciFi clone killing
  //
  {
    const auto max_size = min(number_of_seeds, MaxBufferSize);

    // Reset buffer
    for (unsigned i = threadIdx.x; i < max_size; i += blockDim.x) {
      best_scores[i] = std::numeric_limits<int>::max();
    }
    __syncthreads();

    // Fill
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      if (!output_mask[i]) continue;
      const auto score = scores[i];
      const auto track = inputs[i];
      const auto scifi_idx = track.scifi_idx - seed_offset;
      atomicMin(best_scores + get_idx(scifi_idx), __float_as_int(score));
    }
    __syncthreads();

    // Clone killing
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      if (!output_mask[i]) continue;
      const auto score = scores[i];
      const auto track = inputs[i];
      const auto scifi_idx = track.scifi_idx - seed_offset;
      const auto best_score = __int_as_float(best_scores[get_idx(scifi_idx)]);
      output_mask[i] = (fabsf(score - best_score) / best_score < 0.01f);
    }
    __syncthreads();
  }

  //
  // Final selection
  //
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    if (!output_mask[i] && clone_killing) continue;
    const auto idx = atomicAdd(output_counter, 1u);
    output_tracks[idx] = inputs[i];
  }
}
