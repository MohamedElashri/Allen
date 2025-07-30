/***************************************************************************** \
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "FillMaterialInteractionCandidates.cuh"

INSTANTIATE_ALGORITHM(FillMaterialInteractionCandidates::fill_materialinteraction_candidates_t)

void FillMaterialInteractionCandidates::fill_materialinteraction_candidates_t::set_arguments_size(
  ArgumentReferences<FillMaterialInteractionCandidates::Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_interaction_seeds_t>(arguments, first<host_number_of_total_interaction_seeds_t>(arguments));
}

void FillMaterialInteractionCandidates::fill_materialinteraction_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_interaction_seeds_t>(arguments, 0, context);

  global_function(fill_materialinteraction_candidates)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_max_doca_for_close_track_pairs);
}

__global__ void FillMaterialInteractionCandidates::fill_materialinteraction_candidates(
  FillMaterialInteractionCandidates::Parameters parameters,
  const float max_doca_for_close_track_pairs)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_tracks = parameters.dev_velo_track_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  const auto event_number_of_filtered_tracks = parameters.dev_number_of_filtered_tracks[event_number];
  const auto event_velo_filtered_idx = parameters.dev_filtered_velo_track_idx + velo_tracks.offset();

  const auto event_seed_offset = parameters.dev_interaction_seeds_offsets[event_number];
  auto event_interaction_seeds = parameters.dev_interaction_seeds + event_seed_offset;
  __shared__ unsigned shared_number_of_seeds;

  if (threadIdx.x == 0) {
    shared_number_of_seeds = 0;
  }
  __syncthreads();

  float3 seed_AB;
  float3 seed_BC;
  float3 seed_AC;

  for (unsigned idx = threadIdx.x; idx < event_number_of_filtered_tracks; idx += blockDim.x) {
    auto trackA = velo_tracks.track(event_velo_filtered_idx[idx]);
    auto stateA = trackA.state(velo_states);

    for (unsigned jdx = threadIdx.y + idx + 1; jdx < event_number_of_filtered_tracks; jdx += blockDim.y) {
      auto trackB = velo_tracks.track(event_velo_filtered_idx[jdx]);
      auto stateB = trackB.state(velo_states);

      auto tracks_doca_AB = Allen::Views::Physics::state_doca(stateA, stateB);
      auto poca_bool_AB = Allen::Views::Physics::state_poca(stateA, stateB, seed_AB.x, seed_AB.y, seed_AB.z);
      if (tracks_doca_AB < 0.f || tracks_doca_AB > max_doca_for_close_track_pairs || !poca_bool_AB) continue;

      for (unsigned kdx = threadIdx.z + jdx + 1; kdx < event_number_of_filtered_tracks; kdx += blockDim.z) {
        auto trackC = velo_tracks.track(event_velo_filtered_idx[kdx]);
        auto stateC = trackC.state(velo_states);
        auto tracks_doca_BC = Allen::Views::Physics::state_doca(stateB, stateC);
        auto poca_bool_BC = Allen::Views::Physics::state_poca(stateB, stateC, seed_BC.x, seed_BC.y, seed_BC.z);

        if (tracks_doca_BC < 0.f || tracks_doca_BC > max_doca_for_close_track_pairs || !poca_bool_BC) continue;

        auto tracks_doca_AC = Allen::Views::Physics::state_doca(stateA, stateC);
        auto poca_bool_AC = Allen::Views::Physics::state_poca(stateA, stateC, seed_AC.x, seed_AC.y, seed_AC.z);

        if (tracks_doca_AC > 0.f && tracks_doca_AC < max_doca_for_close_track_pairs && poca_bool_AC) {
          float3 seed {(seed_AB.x + seed_BC.x + seed_AC.x) / 3,
                       (seed_AB.y + seed_BC.y + seed_AC.y) / 3,
                       (seed_AB.z + seed_BC.z + seed_AC.z) / 3};
          auto insert_index = atomicAdd(&shared_number_of_seeds, 1);
          event_interaction_seeds[insert_index] = seed;
        }
      }
    }
  }

  __syncthreads();
}
