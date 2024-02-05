/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamCreateTracks.cuh"

/**
 * @file DownstreamCreateTracks.cu
 * @brief This file implements the second part of downstream track reconstruction, which creates the downstream tracks
 * from the previous algorithm. It includes the following steps:
 * - Loading the SciFi seeds from the previous algorithm.
 * - Finding the best downstream track candidate for each SciFi seed.
 * - Performing clone killing to remove clone tracks.
 * - Running a ghost killer to reduce the ghost rate.
 * - Outputting downstream tracks.
 */

INSTANTIATE_ALGORITHM(downstream_create_tracks::downstream_create_tracks_t);

void downstream_create_tracks::downstream_create_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // outputs
  using UT::DownstreamTracks;
  set_size<dev_downstream_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * DownstreamTracks::TotalMemorySize);
  set_size<dev_num_downstream_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
}

void downstream_create_tracks::downstream_create_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_num_downstream_tracks_t>(arguments, 0, context);

  // Create tracks
  global_function(downstream_create_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void downstream_create_tracks::downstream_create_tracks(downstream_create_tracks::Parameters parameters)
{
  ///////////////////////////////////////////////////////
  //
  // B a s i c   s e t u p
  //
  ///////////////////////////////////////////////////////

  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load scifi information
  using Downstream::DownstreamParameters::MaxNumDownstreamSciFi;
  const auto selected_scifi_offset = parameters.dev_selected_scifi_offsets + event_number * (MaxNumDownstreamSciFi + 1);
  const auto selected_scifi = parameters.dev_selected_scifi + event_number * (MaxNumDownstreamSciFi);
  const auto selected_scifi_qop = parameters.dev_selected_scifi_qop + event_number * (MaxNumDownstreamSciFi);
  const auto selected_scifi_chi2Y = parameters.dev_selected_scifi_chi2Y + event_number * (MaxNumDownstreamSciFi);
  const auto num_selected_scifi = parameters.dev_num_selected_scifi[event_number];

  // Load output table from Find Hits
  using Downstream::DownstreamStructs::FindHits_OutputTable_Const;
  const auto memory_find_hits_table =
    parameters.dev_find_hits_output_table + event_number * FindHits_OutputTable_Const::TotalMemorySize;
  FindHits_OutputTable_Const find_hits_table {memory_find_hits_table};

  // Prepare output
  using UT::DownstreamTracks;
  auto output_memory = parameters.dev_downstream_tracks + event_number * DownstreamTracks::TotalMemorySize;
  auto num_output_tracks = parameters.dev_num_downstream_tracks + event_number;
  DownstreamTracks output_tracks {output_memory};

  ///////////////////////////////////////////////////////
  //
  // S h a r e d    m e m o r y
  //
  ///////////////////////////////////////////////////////
  __shared__ unsigned shared_num_downstream_tracks;
  __shared__ unsigned shared_num_downstream_tracks_after_clone_killing;
  __shared__ ushort shared_scifi[UT::Constants::max_num_tracks];
  __shared__ ushort shared_hits[UT::Constants::max_num_tracks];
  __shared__ ushort shared_bests[UT::Constants::max_num_tracks];
  __shared__ float shared_scores[UT::Constants::max_num_tracks];
  __shared__ bool shared_killed[UT::Constants::max_num_tracks];

  ///////////////////////////////////////////////////////
  //
  // I n i t i a l i z a t i o n
  //
  ///////////////////////////////////////////////////////

  // Reset
  if (threadIdx.x == 0) {
    shared_num_downstream_tracks = 0;
    shared_num_downstream_tracks_after_clone_killing = 0;
  };
  __syncthreads();

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t s
  //
  ///////////////////////////////////////////////////////

  //
  // Find best candidates
  //
  for (unsigned short scifi_idx = threadIdx.x; scifi_idx < num_selected_scifi; scifi_idx += blockDim.x) {
    const auto row_begin = selected_scifi_offset[scifi_idx];
    const auto row_end = selected_scifi_offset[scifi_idx + 1];

    using Downstream::DownstreamHelpers::BestCandidateManager;
    BestCandidateManager<short> track_candidate_manager;
    for (unsigned short row = row_begin; row < row_end; row++) {
      track_candidate_manager.add(row, find_hits_table.score(row));
    }

    const auto best_score = track_candidate_manager.score();

    // Skip all invalid seeds
    if (best_score == Allen::numeric_limits<float>::infinity()) continue;

    // Store the output
    const auto best_candidate = track_candidate_manager.best();
    if (shared_num_downstream_tracks < UT::Constants::max_num_tracks) {
      const auto idx = atomicAdd(&shared_num_downstream_tracks, 1u);

      shared_bests[idx] = best_candidate;
      shared_scores[idx] = best_score;
      shared_scifi[idx] = scifi_idx;
      shared_killed[idx] = false;
    }
  }
  __syncthreads();

  //
  // Clone killing
  //
  for (unsigned short layer = 0; layer < UT::Constants::n_layers; layer += 3) {
    // Cache hits
    for (unsigned short candidate_idx = threadIdx.x; candidate_idx < shared_num_downstream_tracks;
         candidate_idx += blockDim.x) {
      shared_hits[candidate_idx] = find_hits_table.hit(shared_bests[candidate_idx], layer);
    }
    __syncthreads();

    // Kill clone
    for (unsigned short current_idx = threadIdx.x; current_idx < shared_num_downstream_tracks;
         current_idx += blockDim.x) {
      const auto current_hit = shared_hits[current_idx];
      const auto current_score = shared_scores[current_idx];

      if (current_hit == Allen::numeric_limits<ushort>::invalid()) continue;

      for (unsigned short rest_idx = current_idx + 1; rest_idx < shared_num_downstream_tracks; rest_idx++) {
        const auto rest_hit = shared_hits[rest_idx];
        const auto rest_score = shared_scores[rest_idx];

        // Find the clone
        if (current_hit != rest_hit) continue;

        // Find the idx for killed candidate
        const auto killed_idx = (current_score < rest_score) ? rest_idx : current_idx;

        // Kill it!
        if (!shared_killed[killed_idx]) shared_killed[killed_idx] = true;
      }
    }
    __syncthreads();
  }

  //
  // Build the track
  //
  for (unsigned short candidate_idx = threadIdx.x; candidate_idx < shared_num_downstream_tracks;
       candidate_idx += blockDim.x) {
    if (shared_killed[candidate_idx]) continue;

    // Apply beam pipe cuts
    const auto best_candidate = shared_bests[candidate_idx];
    using Downstream::DownstreamExtrapolation::ExtrapolateTrack;
    ExtrapolateTrack exTrack {find_hits_table.xMagnet(best_candidate),
                              find_hits_table.yMagnet(best_candidate),
                              find_hits_table.zMagnet(best_candidate),
                              find_hits_table.tx(best_candidate),
                              find_hits_table.ty(best_candidate),
                              find_hits_table.qop(best_candidate)};

    // Get extra information about good candidate
    const auto scifi_idx = shared_scifi[candidate_idx];
    const auto chi2 = shared_scores[candidate_idx];

    // Get SciFi information
    const auto scifi = selected_scifi[scifi_idx];
    const auto scifi_qop = selected_scifi_qop[scifi_idx];
    const auto scifi_chi2Y = selected_scifi_chi2Y[scifi_idx];

    // Prepare the input for ghost killer
    using UT::Constants::zMidUT;
    const auto xMidUT = exTrack.xAtZ(zMidUT);
    const auto yMidUT = exTrack.yAtZ(zMidUT);
    const auto qop = exTrack.qop();
    using Downstream::DownstreamGhostKiller::Model::num_input;
    float ghost_killer_input[num_input] = {
      xMidUT, yMidUT, exTrack.tx(), exTrack.ty(), chi2, qop, scifi_chi2Y, scifi_qop};

    // Run the ghost killer
    const auto ghost_killer_score = Downstream::DownstreamGhostKiller::evaluate(ghost_killer_input);
    if (ghost_killer_score > parameters.ghost_killer_threshold) continue;

    // Store the result
    if (shared_num_downstream_tracks_after_clone_killing < UT::Constants::max_num_tracks) {
      const auto idx = atomicAdd(&shared_num_downstream_tracks_after_clone_killing, 1u);

      // Add hits
      using UT::Constants::n_layers;
      output_tracks.n_hits(idx) = n_layers;

      Downstream::DownstreamHelpers::unwind<0, n_layers>(
        [&](int layer) { output_tracks.hits(idx, layer) = find_hits_table.hit(best_candidate, layer); });

      // Add state
      output_tracks.scifi(idx) = scifi;
      output_tracks.tx(idx) = exTrack.tx();
      output_tracks.ty(idx) = exTrack.ty();
      output_tracks.x(idx) = xMidUT;
      output_tracks.y(idx) = yMidUT;
      output_tracks.qop(idx) = exTrack.qop();
      output_tracks.chi2(idx) = chi2;
    }
  }
  __syncthreads();

  //
  // Finish the algorithm
  //
  if (threadIdx.x == 0) {
    num_output_tracks[0] = shared_num_downstream_tracks_after_clone_killing;
  }
  __syncthreads();
}
