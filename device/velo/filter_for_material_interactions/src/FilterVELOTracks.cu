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
#include "FilterVELOTracks.cuh"

INSTANTIATE_ALGORITHM(FilterVELOTracks::filter_velo_tracks_t)

void FilterVELOTracks::filter_velo_tracks_t::set_arguments_size(
  ArgumentReferences<FilterVELOTracks::Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_filtered_velo_track_idx_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_number_of_filtered_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_number_of_seeds_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_interaction_seeds_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void FilterVELOTracks::filter_velo_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto dev_beamline = constants.dev_beamline.data();

  Allen::memset_async<dev_filtered_velo_track_idx_t>(arguments, 0, context);
  Allen::memset_async<dev_number_of_filtered_tracks_t>(arguments, 0, context);
  Allen::memset_async<dev_number_of_seeds_t>(arguments, 0, context);
  Allen::memset_async<dev_interaction_seeds_t>(arguments, 0, context);

  global_function(filter_velo_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, dev_beamline);
}

__global__ void FilterVELOTracks::filter_velo_tracks(FilterVELOTracks::Parameters parameters, float* dev_beamline)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_tracks = parameters.dev_velo_track_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  unsigned* event_velo_filtered_idx = parameters.dev_filtered_velo_track_idx + velo_tracks.offset();
  PatPV::XYZPoint* event_interaction_seeds = parameters.dev_interaction_seeds + velo_tracks.offset();

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

    const float beamspot_doca_r = std::sqrt(
      ((state.x() - dev_beamline[0]) * (state.x() - dev_beamline[0])) +
      ((state.y() - dev_beamline[1]) * (state.y() - dev_beamline[1])));

    if (beamspot_doca_r > parameters.beamdoca_r) {
      auto insert_index = atomicAdd(&shared_number_of_filtered_tracks, 1);
      event_velo_filtered_idx[insert_index] = i_track;
    }
  }

  __syncthreads();
  parameters.dev_number_of_filtered_tracks[event_number] = shared_number_of_filtered_tracks;
  if (shared_number_of_filtered_tracks < 3) return;

  PatPV::XYZPoint seed_AB;
  PatPV::XYZPoint seed_BC;
  PatPV::XYZPoint seed_AC;

  for (unsigned idx = threadIdx.x; idx < shared_number_of_filtered_tracks; idx += blockDim.x) {
    auto trackA = velo_tracks.track(event_velo_filtered_idx[idx]);
    auto stateA = trackA.state(velo_states);

    for (unsigned jdx = threadIdx.y + idx + 1; jdx < shared_number_of_filtered_tracks; jdx += blockDim.y) {
      auto trackB = velo_tracks.track(event_velo_filtered_idx[jdx]);
      auto stateB = trackB.state(velo_states);

      auto tracks_doca_AB = Allen::Views::Physics::state_doca(stateA, stateB);
      auto poca_bool_AB = Allen::Views::Physics::state_poca(stateA, stateB, seed_AB.x, seed_AB.y, seed_AB.z);
      if (tracks_doca_AB < 0.f || tracks_doca_AB > parameters.max_doca_for_close_track_pairs || !poca_bool_AB) continue;

      for (unsigned kdx = threadIdx.z + jdx + 1; kdx < shared_number_of_filtered_tracks; kdx += blockDim.z) {
        auto trackC = velo_tracks.track(event_velo_filtered_idx[kdx]);
        auto stateC = trackC.state(velo_states);
        auto tracks_doca_BC = Allen::Views::Physics::state_doca(stateB, stateC);
        auto poca_bool_BC = Allen::Views::Physics::state_poca(stateB, stateC, seed_BC.x, seed_BC.y, seed_BC.z);

        if (tracks_doca_BC < 0.f || tracks_doca_BC > parameters.max_doca_for_close_track_pairs || !poca_bool_BC)
          continue;

        auto tracks_doca_AC = Allen::Views::Physics::state_doca(stateA, stateC);
        auto poca_bool_AC = Allen::Views::Physics::state_poca(stateA, stateC, seed_AC.x, seed_AC.y, seed_AC.z);

        if (tracks_doca_AC > 0.f && tracks_doca_AC < parameters.max_doca_for_close_track_pairs && poca_bool_AC) {
          auto insert_index = atomicAdd(&shared_number_of_seeds, 1);
          PatPV::XYZPoint seed {(seed_AB.x + seed_BC.x + seed_AC.x) / 3,
                                (seed_AB.y + seed_BC.y + seed_AC.y) / 3,
                                (seed_AB.z + seed_BC.z + seed_AC.z) / 3};
          event_interaction_seeds[insert_index] = seed;
        }
      }
    }
  }

  __syncthreads();
  parameters.dev_number_of_seeds[event_number] = shared_number_of_seeds;
}
