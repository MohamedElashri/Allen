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
#include "TrackMatching.cuh"
#include "TrackMatchingHelpers.cuh"
#include "TrackMatchingAddUTHitsTools.cuh"

INSTANTIATE_ALGORITHM(track_matching::track_matching_t);

namespace {
  // inspired from https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/PrAlgorithms/src/PrMatchNN.cpp
  __device__ track_matching::MatchingResult
  getChi2Match(track_matching::Parameters parameters, const MiniState velo_state, const MiniState scifi_state)
  {
    const float xpos_velo = velo_state.x(), ypos_velo = velo_state.y(), zpos_velo = velo_state.z(),
                tx_velo = velo_state.tx(), ty_velo = velo_state.ty();
    const float xpos_scifi = scifi_state.x(), ypos_scifi = scifi_state.y(), zpos_scifi = scifi_state.z(),
                tx_scifi = scifi_state.tx(), ty_scifi = scifi_state.ty();

    const float dSlopeX = tx_velo - tx_scifi;
    if (std::abs(dSlopeX) > 1.5f)
      return {
        9999., 9999., 9999., 9999., 9999., 9999.}; // matching the UT/SciFi slopes in X (bending -> large tolerance)

    const float dSlopeY = ty_velo - ty_scifi;
    if (std::abs(dSlopeY) > 0.02f)
      return {9999.f, 9999.f, 9999.f, 9999.f, 9999.f, 9999.f}; // matching the UT/SciFi slopes in Y (no bending)

    const auto& z_magnet_parameters = parameters.z_magnet_parameters.get();
    const float zForX = z_magnet_parameters[0] + z_magnet_parameters[1] * std::abs(dSlopeX) +
                        z_magnet_parameters[2] * dSlopeX * dSlopeX + z_magnet_parameters[3] * std::abs(xpos_scifi) +
                        z_magnet_parameters[4] * tx_velo * tx_velo;
    const float dxTol2 = TrackMatchingConsts::dxTol * TrackMatchingConsts::dxTol;
    const float dxTolSlope2 = TrackMatchingConsts::dxTolSlope * TrackMatchingConsts::dxTolSlope;
    const float xV = xpos_velo + (zForX - zpos_velo) * tx_velo;
    // -- This is the function that calculates the 'bending' in y-direction
    // -- The parametrisation can be derived with the MatchFitParams package
    const float yV = ypos_velo + (TrackMatchingConsts::zMatchY - zpos_velo) * ty_velo;
    //+ ty_velo * ( dev_magnet_parametrization->bendYParams[0] * dSlopeX * dSlopeX
    //       + dev_magnet_parametrization->bendYParams[1] * dSlopeY * dSlopeY );

    const float xS = xpos_scifi + (zForX - zpos_scifi) * tx_scifi;
    const float yS = ypos_scifi + (TrackMatchingConsts::zMatchY - zpos_scifi) * ty_scifi;

    const float distX = xS - xV;
    if (std::abs(distX) > 20.f) return {9999.f, 9999.f, 9999.f, 9999.f, 9999.f, 9999.f}; // to scan
    const float distY = yS - yV;
    if (std::abs(distY) > 150.f) return {9999.f, 9999.f, 9999.f, 9999.f, 9999.f, 9999.f}; // to scan

    const float tx2_velo = tx_velo * tx_velo;
    const float ty2_velo = ty_velo * ty_velo;
    const float teta2 = tx2_velo + ty2_velo;
    const float tolX = dxTol2 + dSlopeX * dSlopeX * dxTolSlope2;
    const float tolY = TrackMatchingConsts::dyTol * TrackMatchingConsts::dyTol +
                       teta2 * TrackMatchingConsts::dyTolSlope * TrackMatchingConsts::dyTolSlope;
    const float multiplication_factor_dX = parameters.multiplication_factor_dX;
    const float multiplication_factor_dY = parameters.multiplication_factor_dY;
    const float multiplication_factor_dty = parameters.multiplication_factor_dty;
    const float multiplication_factor_dtx = parameters.multiplication_factor_dtx;

    float chi2 =
      (tolX != 0.f and tolY != 0.f ?
         multiplication_factor_dX * distX * distX / tolX + multiplication_factor_dY * distY * distY / tolY :
         9999.f);
    // float chi2 = ( tolX != 0 and tolY != 0 ? distX * distX / tolX : 9999. );

    chi2 += multiplication_factor_dty * dSlopeY * dSlopeY;
    chi2 += multiplication_factor_dtx * dSlopeX * dSlopeX;

    return {dSlopeX, dSlopeY, distX, distY, zForX, chi2};
  }
  // Parametrization from SciFiTrackForwarding.cpp , found to work better than FastMomentumEstimate.cpp
  // https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/SciFiTrackForwarding/src/SciFiTrackForwarding.cpp#L321
  //
  // @jzhuo (24/05/2024): update the same parametrization format with Sim10aU1 MinBias simulation (MD+MU),
  //                      the term related to txT^4 and tyV^4 are deprecated because it increase the
  //                      mean square error.
  __device__ float computeQoverP(
    const float txV,
    const float tyV,
    const float txT,
    const float magSign,
    const track_matching::Parameters::momentum_parameters_t::t& momentum_parameters)
  {
    const auto dslope = txT - txV;
    const auto abs_p = momentum_parameters[0] +
                       (momentum_parameters[1] + momentum_parameters[2] * (txT * txT) +
                        momentum_parameters[3] * (txT * txT * txT * txT) + momentum_parameters[4] * (txT * txV) +
                        momentum_parameters[5] * (tyV * tyV) + momentum_parameters[6] * (tyV * tyV * tyV * tyV) +
                        momentum_parameters[7] * (txV * txV)) /
                         fabsf(dslope);

    const auto charge = ((dslope > 0) ? 1.f : -1.f) * magSign;
    return charge / abs_p;
  }
} // namespace

void track_matching::track_matching_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto has_ut = (size<dev_ut_hits_t>(arguments) > 0) &&
                      (first<host_accumulated_number_of_ut_hits_t>(arguments) > 0) && (!property<force_skip_ut_t>());
  set_size<dev_matched_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * TrackMatchingConsts::max_num_tracks);
  set_size<dev_atomics_matched_tracks_t>(arguments, first<host_number_of_events_t>(arguments));

  // working memory (Hit caching in case of shared doesn't fit)
  if (has_ut) {
    using track_matching::tools::UTHitCache;
    set_size<dev_hit_caching_memory_t>(
      arguments,
      (first<host_accumulated_number_of_ut_hits_t>(arguments) + UT::Constants::n_layers) *
        UTHitCache::RowSize); // Extra hits for alignement in each layer
    set_size<dev_hit_caching_counter_t>(arguments, 1);
  }
  else {
    set_size<dev_hit_caching_memory_t>(arguments, 0);
    set_size<dev_hit_caching_counter_t>(arguments, 0);
  }
}

void track_matching::track_matching_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto has_ut = (size<dev_ut_hits_t>(arguments) > 0) &&
                      (first<host_accumulated_number_of_ut_hits_t>(arguments) > 0) && (!property<force_skip_ut_t>());

  Allen::memset_async<dev_atomics_matched_tracks_t>(arguments, 0, context);

  if (has_ut) {
    Allen::memset_async<dev_hit_caching_counter_t>(arguments, 0, context);

    // Velo SciFi matching
    global_function(track_matching_veloSciFi<true>)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
      arguments, constants.dev_magnet_polarity.data(), constants.dev_matching_ghost_killer);

    // Add UT hits
    global_function(track_matching_add_ut_hits)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
      arguments,
      constants.dev_magnet_polarity.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_sector_xs.data(),
      constants.dev_ut_dxDy.data(),
      constants.dev_mean_ut_layer_zs.data());

    // Apply ghost killer filter
    global_function(track_matching_filter_tracks)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
      arguments, constants.dev_matching_with_ut_ghost_killer);

    // Clone killing
    global_function(track_matching_clone_killing<true>)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
  }
  else {
    // Velo SciFi matching
    global_function(track_matching_veloSciFi<false>)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
      arguments, constants.dev_magnet_polarity.data(), constants.dev_matching_ghost_killer);
    // Clone killing
    global_function(track_matching_clone_killing<false>)(
      dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
  }
}

template<bool has_ut>
__global__ void track_matching::track_matching_veloSciFi(
  track_matching::Parameters parameters,
  const float* dev_magnet_polarity,
  const Allen::NeuralNetwork::Model::MatchingGhostKiller* dev_matching_ghost_killer)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Velo views
  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  const unsigned event_velo_seeds_offset = velo_tracks.offset();

  // filtered velo tracks
  const auto ut_number_of_selected_tracks = parameters.dev_ut_number_of_selected_velo_tracks[event_number];
  const auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_velo_seeds_offset;

  // SciFi seed views
  const auto scifi_seeds = parameters.dev_scifi_tracks_view[event_number];

  const unsigned event_scifi_seeds_offset = scifi_seeds.offset();
  const auto number_of_scifi_seeds = scifi_seeds.size();
  const auto scifi_states = parameters.dev_seeding_states + event_scifi_seeds_offset;

  auto& n_matched = parameters.dev_atomics_matched_tracks[event_number];

  SciFi::MatchedTrack* matched_tracks_event =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  for (unsigned i = threadIdx.x; i < number_of_scifi_seeds; i += blockDim.x) {
    const auto scifi_state = scifi_states[i];

    // Loop over filtered velo tracks
    for (unsigned ivelo = 0; ivelo < ut_number_of_selected_tracks; ivelo++) {

      const auto velo_track_index = ut_selected_velo_tracks[ivelo];
      const auto endvelo_state = velo_states.state(velo_track_index);
      auto matchingInfo = getChi2Match(parameters, endvelo_state, scifi_state);
      if (matchingInfo.chi2 > TrackMatchingConsts::maxChi2) continue;

      const auto velo_eta = asinhf(1.f / hypotf(endvelo_state.tx(), endvelo_state.ty()));

      float ghost_killer_score = 0.f;
      if constexpr (!has_ut) {
        float ghost_killer_inputs[Allen::NeuralNetwork::Model::MatchingGhostKiller::nInput] = {matchingInfo.zForX,
                                                                                               matchingInfo.distX,
                                                                                               matchingInfo.distY,
                                                                                               matchingInfo.dSlopeX,
                                                                                               matchingInfo.dSlopeY,
                                                                                               logf(matchingInfo.chi2),
                                                                                               velo_eta};
        ghost_killer_score = Allen::NeuralNetwork::evaluate(dev_matching_ghost_killer, ghost_killer_inputs);

        if (ghost_killer_score > parameters.ghost_killer_threshold.get()) continue;
      }

      // Save the result
      auto idx = atomicAdd(&n_matched, 1);
      auto& matched_track = matched_tracks_event[idx];

      const auto magSign = -dev_magnet_polarity[0];
      const auto qop = computeQoverP(
        endvelo_state.tx(), endvelo_state.ty(), scifi_state.tx(), magSign, parameters.momentum_parameters.get());

      matched_track.velo_track_index = velo_track_index;
      matched_track.scifi_track_index = i;

      matched_track.ut_hits[0] = SciFi::MatchedTrack::InvalidHit;
      matched_track.ut_hits[1] = SciFi::MatchedTrack::InvalidHit;
      matched_track.ut_hits[2] = SciFi::MatchedTrack::InvalidHit;
      matched_track.ut_hits[3] = SciFi::MatchedTrack::InvalidHit;

      matched_track.number_of_hits_ut = 0;
      matched_track.qop = qop;
      matched_track.gamma = std::numeric_limits<float>::quiet_NaN();
      matched_track.ut_score = 0;
      matched_track.score = ghost_killer_score;
    }
  }
}

__global__ void track_matching::track_matching_add_ut_hits(
  track_matching::Parameters parameters,
  const float* dev_magnet_polarity,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const float* dev_unique_sector_xs,
  const float* dev_ut_dxDy,
  const float* dev_mean_layer_z)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load long track candidates
  auto& n_matched_tracks_event = parameters.dev_atomics_matched_tracks[event_number];
  auto matched_tracks_event = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  // Load UT information
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Velo views
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  // Global memory for hit caching
  const auto global_memory_hit_caching = parameters.dev_hit_caching_memory;
  const auto global_memory_hit_caching_counter = parameters.dev_hit_caching_counter;

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  using track_matching::tools::UTHitCache;
  using track_matching::tools::UTSectorHelper;
  using UT::Constants::n_layers;

  // Allocate the memory
  __shared__ char shared_memory_hit_caching[UTHitCache::TotalMemorySize];

  // Hit Cache
  UTHitCache hit_cache {shared_memory_hit_caching, global_memory_hit_caching, global_memory_hit_caching_counter};
  UTSectorHelper sector_cache;

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t
  //
  ///////////////////////////////////////////////////////

#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
  for (unsigned layer = 0; layer < UT::Constants::n_layers; layer++) {
    // Cache hits and sectors
    hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_mean_layer_z[layer], layer);
    sector_cache.cache_layer(ut_hit_offsets, dev_unique_sector_xs, dev_unique_x_sector_layer_offsets, layer);

    const auto const_n_matched_tracks_event = n_matched_tracks_event;
    __syncthreads();

    // Cache/Alias certain values
    const auto dxdy = dev_ut_dxDy[layer];

    // Add hits to each candidates
    for (unsigned candidate_idx = threadIdx.x; candidate_idx < const_n_matched_tracks_event;
         candidate_idx += blockDim.x) {

      // Alias
      auto& matched_track = matched_tracks_event[candidate_idx];

      // Get state
      const auto endvelo_state = velo_states.state(matched_track.velo_track_index);

      // Load extrapolation
      auto trajectory = std::isnan(matched_track.gamma) ? track_matching::tools::VeloToUTExtrapolator(
                                                            endvelo_state.x(),
                                                            endvelo_state.y(),
                                                            endvelo_state.tx(),
                                                            endvelo_state.ty(),
                                                            matched_track.qop * dev_magnet_polarity[0]) :
                                                          track_matching::tools::VeloToUTExtrapolator(
                                                            endvelo_state.x(),
                                                            endvelo_state.y(),
                                                            endvelo_state.tx(),
                                                            endvelo_state.ty(),
                                                            matched_track.qop,
                                                            matched_track.gamma);

      // Get tolerances
      const auto xTol = trajectory.xTol(
        layer,
        parameters.loose_ut_hit_tolerance_scaling_factor.get(),
        parameters.tight_ut_hit_tolerance_scaling_factor.get());
      const auto yTol = trajectory.yTol(layer, parameters.y_ut_hit_tolerance_scaling_factor.get());

      // Get expected x and open the search window
      const auto expected_layer_y = trajectory.yAtZ(dev_mean_layer_z[layer]);
      const auto expected_layer_x = trajectory.xAtZ(dev_mean_layer_z[layer]) - dxdy * expected_layer_y;
      const auto hit_range = sector_cache.get_hit_range(expected_layer_x - xTol, expected_layer_x + xTol);

      // Find best hit
      if (trajectory.is_first_hit()) // In case of first hit, each hit is a independent candidate
      {

        using track_matching::tools::MultiCandidateManager;
        MultiCandidateManager<ushort, 8, true> best_hits;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const float hit_z = hit_cache.zAtYEq0(hit_idx);

          const float expected_hit_y = trajectory.yAtZ(hit_z);
          if (hit_cache.isNotYCompatible(hit_idx, expected_hit_y, yTol)) continue;

          const float expected_hit_x = trajectory.xAtZ(hit_z);
          const float hit_x = hit_cache.xAtYEq0(hit_idx) + expected_hit_y * dxdy;

          const float xdist = expected_hit_x - hit_x;
          if (fabsf(xdist) > xTol) continue;

          // Store
          best_hits.add(hit_idx, xdist);
        };
        if (!best_hits.exist()) continue;

        //
        // Add all hits as candidates
        //
        for (unsigned best_hits_idx = 0; best_hits_idx < best_hits.size(); best_hits_idx++) {
          if (best_hits_idx == 0) {
            // First hit will override to the current candidate
            const auto best_hit_idx = best_hits.get(best_hits_idx);
            matched_track.ut_hits[layer] = hit_cache.HitOffset() + best_hit_idx;
            matched_track.number_of_hits_ut++;
            // update gamma
            const auto hit_z = hit_cache.zAtYEq0(best_hit_idx);
            const auto hit_x0 = hit_cache.xAtYEq0(best_hit_idx);
            const auto expected_hit_y = trajectory.yAtZ(hit_z);
            const auto hit_x = hit_x0 + expected_hit_y * dxdy;
            matched_track.gamma = trajectory.get_new_gamma(hit_z, hit_x);
          }
          else {
            // Rest of hits have to create new candidates
            if (n_matched_tracks_event >= TrackMatchingConsts::max_num_tracks) continue;
            const auto new_candidate_idx = atomicAdd(&n_matched_tracks_event, 1u);
            const auto best_hit_idx = best_hits.get(best_hits_idx);

            // Clone candidate
            matched_tracks_event[new_candidate_idx] = matched_track;

            // Modify the ut hit
            matched_tracks_event[new_candidate_idx].ut_hits[layer] = hit_cache.HitOffset() + best_hit_idx;

            // Modify the gamma
            const auto hit_z = hit_cache.zAtYEq0(best_hit_idx);
            const auto hit_x0 = hit_cache.xAtYEq0(best_hit_idx);
            const auto expected_hit_y = trajectory.yAtZ(hit_z);
            const auto hit_x = hit_x0 + expected_hit_y * dxdy;
            matched_tracks_event[new_candidate_idx].gamma = trajectory.get_new_gamma(hit_z, hit_x);
          }
        }
      }
      else {
        using track_matching::tools::BestCandidateManager;
        BestCandidateManager<ushort, true> best_hit;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const float hit_z = hit_cache.zAtYEq0(hit_idx);

          const float expected_hit_y = trajectory.yAtZ(hit_z);
          if (hit_cache.isNotYCompatible(hit_idx, expected_hit_y, yTol)) continue;

          const float expected_hit_x = trajectory.xAtZ(hit_z);
          const float hit_x = hit_cache.xAtYEq0(hit_idx) + expected_hit_y * dxdy;

          const float xdist = expected_hit_x - hit_x;
          if (fabsf(xdist) > xTol) continue;

          // Store
          best_hit.add(hit_idx, xdist);
        };
        if (!best_hit.exist()) continue;

        // Add best hit
        matched_track.ut_hits[layer] = hit_cache.HitOffset() + best_hit.best();
        matched_track.ut_score += best_hit.score() * best_hit.score();
        matched_track.number_of_hits_ut++;
      }
    }
    __syncthreads();
  }
}

__global__ void track_matching::track_matching_filter_tracks(
  track_matching::Parameters parameters,
  const Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller* dev_matching_ghost_killer)
{
  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Velo info
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];

  // SciFi info
  const auto scifi_seeds = parameters.dev_scifi_tracks_view[event_number];
  const unsigned event_scifi_seeds_offset = scifi_seeds.offset();
  const auto scifi_states = parameters.dev_seeding_states + event_scifi_seeds_offset;

  // Load long track candidates
  auto num_tracks = parameters.dev_atomics_matched_tracks + event_number;
  auto matched_tracks_event = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  //
  // Shared memory initialization
  //
  const auto const_num_tracks = num_tracks[0];
  __shared__ bool killed[TrackMatchingConsts::max_num_tracks];
  for (unsigned i = threadIdx.x; i < TrackMatchingConsts::max_num_tracks; i += blockDim.x) {
    killed[i] = false;
  }
  __syncthreads();
  if (threadIdx.x == 0) {
    num_tracks[0] = 0; // Reset number of tracks
  }
  __syncthreads();

  //
  // Apply Ghost Killer to evaluate score
  //
  for (unsigned i = threadIdx.x; i < const_num_tracks; i += blockDim.x) {

    // Fetch candidate info
    auto& matched_track = matched_tracks_event[i];

    // Prepare the NN inputs
    const auto vp_state = velo_states.state(matched_track.velo_track_index);
    const auto ft_state = scifi_states[matched_track.scifi_track_index];
    const auto matchingInfo = getChi2Match(parameters, vp_state, ft_state);
    const auto velo_eta = asinhf(1.f / hypotf(vp_state.tx(), vp_state.ty()));

    // Evaluate NN based ghost killer
    float ghost_killer_inputs[Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller::nInput] = {
      matchingInfo.zForX,
      matchingInfo.distX,
      matchingInfo.distY,
      matchingInfo.dSlopeX,
      matchingInfo.dSlopeY,
      matchingInfo.chi2,
      velo_eta,
      matched_track.ut_score / (matched_track.number_of_hits_ut - 1),
      float(matched_track.number_of_hits_ut),
      float(velo_tracks.track(matched_track.velo_track_index).number_of_hits()),
      float(scifi_seeds.track(matched_track.scifi_track_index).number_of_scifi_hits())};
    matched_track.score = Allen::NeuralNetwork::evaluate(dev_matching_ghost_killer, ghost_killer_inputs);
    killed[i] = (matched_track.score > parameters.ghost_killer_threshold) || (matched_track.number_of_hits_ut <= 1);
  }
  __syncthreads();

  //
  // Collect good tracks
  //
  for (unsigned i = threadIdx.x; i < const_num_tracks; i += blockDim.x) {
    const auto track = matched_tracks_event[i];
    __syncthreads();
    if (killed[i] != true) {
      unsigned idx = atomicAdd(num_tracks, 1u);
      matched_tracks_event[idx] = track;
    }
    __syncthreads();
  };
}

template<bool has_ut>
__global__ void track_matching::track_matching_clone_killing(track_matching::Parameters parameters)
{
  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load long track candidates
  auto num_tracks = parameters.dev_atomics_matched_tracks + event_number;
  auto matched_tracks_event = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  //
  // Shared memory initialization
  //
  const auto const_num_tracks = num_tracks[0];
  __shared__ bool killed[TrackMatchingConsts::max_num_tracks];
  for (unsigned i = threadIdx.x; i < TrackMatchingConsts::max_num_tracks; i += blockDim.x) {
    killed[i] = false;
  }
  __syncthreads();
  if (threadIdx.x == 0) {
    num_tracks[0] = 0; // Reset number of tracks
  }
  __syncthreads();

  //
  // Do clone killing
  //
  for (unsigned n_track_1 = threadIdx.x; n_track_1 < const_num_tracks; n_track_1 += blockDim.x) {
    auto& track_1 = matched_tracks_event[n_track_1];

    for (unsigned n_track_2 = n_track_1 + 1; n_track_2 < const_num_tracks; n_track_2 += 1) {

      auto& track_2 = matched_tracks_event[n_track_2];

      int shared_seeds = 0;
      if (track_1.velo_track_index == track_2.velo_track_index) {
        shared_seeds += 1;
      };
      if (track_1.scifi_track_index == track_2.scifi_track_index) {
        shared_seeds += 1;
      };

      if constexpr (has_ut) {
        unsigned shared_ut_hits = 0;
        if (track_1.ut_hits[0] != SciFi::MatchedTrack::InvalidHit && track_1.ut_hits[0] == track_2.ut_hits[0]) {
          shared_ut_hits++;
        }
        if (track_1.ut_hits[1] != SciFi::MatchedTrack::InvalidHit && track_1.ut_hits[1] == track_2.ut_hits[1]) {
          shared_ut_hits++;
        }
        if (track_1.ut_hits[2] != SciFi::MatchedTrack::InvalidHit && track_1.ut_hits[2] == track_2.ut_hits[2]) {
          shared_ut_hits++;
        }
        if (track_1.ut_hits[3] != SciFi::MatchedTrack::InvalidHit && track_1.ut_hits[3] == track_2.ut_hits[3]) {
          shared_ut_hits++;
        }

        if (
          // Same Velo and SciFi: must select one, otherwise clone rate is too high
          ((shared_seeds == 2)) ||
          // Same UT segment
          ((shared_ut_hits == min(track_1.number_of_hits_ut, track_2.number_of_hits_ut)) && (shared_ut_hits > 2) &&
           (fabsf(track_1.score - track_2.score) > 0.05f)) ||
          // Align with MatchingNoUT
          ((shared_seeds >= 1) && (fabsf(track_1.score - track_2.score) > 0.05f)) // Same condition like NoUT killing
        ) {

          if (track_1.number_of_hits_ut < track_2.number_of_hits_ut) {
            killed[n_track_1] = true;
          }
          else if (track_1.number_of_hits_ut > track_2.number_of_hits_ut) {
            killed[n_track_2] = true;
          }
          else if (track_1.score <= track_2.score) {
            killed[n_track_2] = true;
          }
          else if (track_1.score > track_2.score) {
            killed[n_track_1] = true;
          }
        }
      }
      else {
        if ((shared_seeds >= 1) && (fabsf(track_1.score - track_2.score) > 0.05f)) {
          if (track_1.score <= track_2.score) {
            killed[n_track_2] = true;
          }
          else {
            killed[n_track_1] = true;
          };
        };
      }
    };
  };
  __syncthreads();

  //
  // Collect good tracks
  //
  for (unsigned i = threadIdx.x; i < const_num_tracks; i += blockDim.x) {
    auto track = matched_tracks_event[i];
    __syncthreads();
    if (killed[i] != true) {
      unsigned idx = atomicAdd(num_tracks, 1u);
      matched_tracks_event[idx] = track;
    }
    __syncthreads();
  };
}
