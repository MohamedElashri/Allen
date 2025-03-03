/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "CompassUTSelectTracks.cuh"
#include "VeloDefinitions.cuh"
#include "PrefixSum.cuh"
#include "UTEventModel.cuh"

INSTANTIATE_ALGORITHM(compass_ut_select_tracks::compass_ut_select_tracks_t)

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

void compass_ut_select_tracks::compass_ut_select_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_candidates = first<host_number_of_ut_track_output_tracks_t>(arguments);

  set_size<dev_ut_track_selected_offset_t>(arguments, number_of_events + 1);
  set_size<dev_ut_track_selected_tracks_t>(arguments, number_of_candidates);
  set_size<host_number_of_ut_track_selected_tracks_t>(arguments, 1);
  set_size<dev_ut_track_selection_t>(arguments, number_of_candidates);
}

void compass_ut_select_tracks::compass_ut_select_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_track_selected_offset_t>(arguments, 0, context);
  Allen::memset_async<dev_ut_track_selection_t>(arguments, 0, context);

  global_function(compass_ut_kill_clone_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_min_independent_hits, m_vp_clone_killing_threshold);
  PrefixSum::prefix_sum<dev_ut_track_selected_offset_t, host_number_of_ut_track_selected_tracks_t>(
    *this, arguments, context);
}

__global__ void compass_ut_select_tracks::compass_ut_kill_clone_tracks(
  Parameters parameters,
  int min_independent_hits,
  float vp_clone_killing_threshold)
{
  // General
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // UT offset
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};

  // Input
  const auto input_offset = parameters.dev_ut_track_consolidate_candidate_offset[event_number];
  const auto output_offset = parameters.dev_ut_track_output_offset[event_number];
  const auto input_size = parameters.dev_ut_track_output_offset[event_number + 1] - output_offset;

  // Output
  auto best_size = parameters.dev_ut_track_selected_offset + event_number;
  auto best_candidates = parameters.dev_ut_track_selected_tracks + output_offset;
  auto selection = parameters.dev_ut_track_selection + output_offset;

  // Shared memory
  __shared__ int best_scores[MaxBufferSize];

  //
  // UT clone killing
  //
  for (unsigned layer = 0; layer < 4; layer++) {
    const auto hit_layer_offset = ut_hit_offsets.layer_offset(layer) - ut_hit_offsets.event_offset();

    // Reset buffer
    for (unsigned i = threadIdx.x; i < MaxBufferSize; i += blockDim.x) {
      best_scores[i] = __float_as_int(std::numeric_limits<float>::infinity());
    }
    __syncthreads();

    // Fill best scores
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      const auto candidate = parameters.dev_ut_track_output_tracks[input_offset + i];
      const auto hit = candidate.ut_hits[layer];
      if (hit >= 0) {
        atomicMin(best_scores + get_idx(hit - hit_layer_offset), __float_as_int(candidate.score));
      }
    }
    __syncthreads();

    // Choose the best candidate
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      const auto candidate = parameters.dev_ut_track_output_tracks[input_offset + i];
      const auto hit = candidate.ut_hits[layer];
      const auto best_score = best_scores[get_idx(hit - hit_layer_offset)];
      if (__float_as_int(candidate.score) == best_score) {
        selection[i] += 1;
      }
    }
    __syncthreads();
  }

  // Consolidate the selection
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    selection[i] = (selection[i] >= min_independent_hits);
  }
  __syncthreads();

  //
  // VELO clone killing
  //

  // Reset buffer
  for (unsigned i = threadIdx.x; i < MaxBufferSize; i += blockDim.x) {
    best_scores[i] = __float_as_int(std::numeric_limits<float>::infinity());
  }
  __syncthreads();

  // Fill best scores
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    if (selection[i] == 0) continue;
    const auto candidate = parameters.dev_ut_track_output_tracks[input_offset + i];
    atomicMin(best_scores + get_idx(candidate.velo_index), __float_as_int(candidate.score));
  }
  __syncthreads();

  // Choose the best candidate
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    if (selection[i] == 0) continue;
    const auto candidate = parameters.dev_ut_track_output_tracks[input_offset + i];
    const auto best_score = __int_as_float(best_scores[get_idx(candidate.velo_index)]);
    const auto diff = fabsf((best_score - candidate.score)) / best_score;
    if (diff <= vp_clone_killing_threshold) {
      const auto idx = atomicAdd(best_size, 1u);
      best_candidates[idx] = candidate;
    }
  }
}
