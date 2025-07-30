/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CountMaterialInteractionCandidates.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(CountMaterialInteractionCandidates::count_materialinteraction_candidates_t)

void CountMaterialInteractionCandidates::count_materialinteraction_candidates_t::set_arguments_size(
  ArgumentReferences<CountMaterialInteractionCandidates::Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_filtered_velo_track_idx_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_number_of_filtered_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_interaction_seeds_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_total_interaction_seeds_t>(arguments, 1);
}

void CountMaterialInteractionCandidates::count_materialinteraction_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_filtered_velo_track_idx_t>(arguments, 0, context);
  Allen::memset_async<dev_number_of_filtered_tracks_t>(arguments, 0, context);
  Allen::memset_async<dev_interaction_seeds_offsets_t>(arguments, 0, context);

  global_function(count_materialinteraction_candidates)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_beamdoca_r, m_max_doca_for_close_track_pairs);

  PrefixSum::prefix_sum<dev_interaction_seeds_offsets_t, host_number_of_total_interaction_seeds_t>(
    *this, arguments, context);
}

void CountMaterialInteractionCandidates::count_materialinteraction_candidates_t::update(
  const Constants& constants) const
{
  updateCommon(constants);
}

__global__ void CountMaterialInteractionCandidates::count_materialinteraction_candidates(
  CountMaterialInteractionCandidates::Parameters parameters,
  const float beamdoca_r,
  const float max_doca_for_close_track_pairs)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_tracks = parameters.dev_velo_track_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  unsigned* event_velo_filtered_idx = parameters.dev_filtered_velo_track_idx + velo_tracks.offset();

  __shared__ unsigned shared_number_of_filtered_tracks;
  __shared__ unsigned shared_number_of_seeds;

  if (threadIdx.x == 0) {
    shared_number_of_filtered_tracks = 0;
    shared_number_of_seeds = 0;
  }
  __syncthreads();

  for (unsigned i_track = threadIdx.x; i_track < velo_tracks.size(); i_track += blockDim.x) {
    const auto track = velo_tracks.track(i_track);
    const auto state = track.state(velo_states);

    float tx_beam;
    float ty_beam;
    if (state.z() > BeamlinePVConstants::Common::SMOG2_pp_separation) {
      tx_beam = dev_beamline.tx.x;
      ty_beam = dev_beamline.tx.y;
    }
    else {
      tx_beam = dev_beamline.tx_SMOG.x;
      ty_beam = dev_beamline.tx_SMOG.y;
    }

    const float beamspot_doca_r = std::sqrt(
      ((state.x() - dev_beamline.pos.x - state.z() * tx_beam) *
       (state.x() - dev_beamline.pos.x - state.z() * tx_beam)) +
      ((state.y() - dev_beamline.pos.y - state.z() * ty_beam) *
       (state.y() - dev_beamline.pos.y - state.z() * ty_beam)));

    if (beamspot_doca_r > beamdoca_r) {
      auto insert_index = atomicAdd(&shared_number_of_filtered_tracks, 1);
      event_velo_filtered_idx[insert_index] = i_track;
    }
  }

  __syncthreads();
  parameters.dev_number_of_filtered_tracks[event_number] = shared_number_of_filtered_tracks;
  if (shared_number_of_filtered_tracks < 3) return;

  for (unsigned idx = threadIdx.x; idx < shared_number_of_filtered_tracks; idx += blockDim.x) {
    auto trackA = velo_tracks.track(event_velo_filtered_idx[idx]);
    auto stateA = trackA.state(velo_states);

    for (unsigned jdx = threadIdx.y + idx + 1; jdx < shared_number_of_filtered_tracks; jdx += blockDim.y) {
      auto trackB = velo_tracks.track(event_velo_filtered_idx[jdx]);
      auto stateB = trackB.state(velo_states);

      auto tracks_doca_AB = Allen::Views::Physics::state_doca(stateA, stateB);
      if (tracks_doca_AB < 0.f || tracks_doca_AB > max_doca_for_close_track_pairs) continue;

      for (unsigned kdx = threadIdx.z + jdx + 1; kdx < shared_number_of_filtered_tracks; kdx += blockDim.z) {
        auto trackC = velo_tracks.track(event_velo_filtered_idx[kdx]);
        auto stateC = trackC.state(velo_states);

        auto tracks_doca_BC = Allen::Views::Physics::state_doca(stateB, stateC);
        if (tracks_doca_BC < 0.f || tracks_doca_BC > max_doca_for_close_track_pairs) continue;

        auto tracks_doca_AC = Allen::Views::Physics::state_doca(stateA, stateC);
        if (tracks_doca_AC > 0.f && tracks_doca_AC < max_doca_for_close_track_pairs) {
          atomicAdd(&shared_number_of_seeds, 1);
        }
      }
    }
  }

  __syncthreads();
  parameters.dev_interaction_seeds_offsets[event_number] = shared_number_of_seeds;
}
