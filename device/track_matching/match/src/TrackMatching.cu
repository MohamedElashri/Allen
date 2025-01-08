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
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(track_matching::track_matching_t);

namespace {
  // inspired from https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/PrAlgorithms/src/PrMatchNN.cpp
  __device__ track_matching::MatchingResult getChi2Match(
    const MiniState velo_state,
    const MiniState scifi_state,
    const std::array<float, 5>& z_magnet_parameters,
    float multiplication_factor_dX,
    float multiplication_factor_dY,
    float multiplication_factor_dty,
    float multiplication_factor_dtx)
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
    const std::array<float, 16>& momentum_parameters)
  {
    // Pick parametrisation from polarity condition
    // magSign is -1*dev_magnet_polarity so negative sign is MagUp
    const float* params = momentum_parameters.data() + (magSign < 0 ? 0 : 8);

    const auto dslope = txT - txV;
    const auto abs_p =
      params[0] + (params[1] + params[2] * (txT * txT) + params[3] * (txT * txT * txT * txT) + params[4] * (txT * txV) +
                   params[5] * (tyV * tyV) + params[6] * (tyV * tyV * tyV * tyV) + params[7] * (txV * txV)) /
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
  set_size<dev_matched_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * TrackMatchingConsts::max_num_tracks);
  set_size<dev_offsets_matched_tracks_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_reconstructed_matched_tracks_t>(arguments, 1);
}

void track_matching::track_matching_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto has_ut = (size<dev_ut_hits_t>(arguments) > 0) &&
                      (first<host_accumulated_number_of_ut_hits_t>(arguments) > 0) && (!m_force_skip_ut.value());

  const auto use_with_ut_neural_network = has_ut && !m_force_no_ut_nn.value();

  Allen::memset_async<dev_offsets_matched_tracks_t>(arguments, 0, context);

  if (use_with_ut_neural_network) {
    // Velo SciFi matching
    global_function(track_matching_veloSciFi<void>)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments,
      constants.dev_magnet_polarity.data(),
      nullptr,
      m_momentum_parameters,
      m_z_magnet_parameters,
      m_multiplication_factor_dX,
      m_multiplication_factor_dY,
      m_multiplication_factor_dty,
      m_multiplication_factor_dtx,
      m_ghost_killer_threshold,
      m_n_overflow_track_matching.data(context));
  }
  else {
    // Velo SciFi matching
    if (m_matching_no_ut_ghost_killer_version == 1) {
      global_function(track_matching_veloSciFi<Allen::NeuralNetwork::Model::MatchingGhostKiller>)(
        dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        constants.dev_magnet_polarity.data(),
        constants.dev_matching_ghost_killer,
        m_momentum_parameters,
        m_z_magnet_parameters,
        m_multiplication_factor_dX,
        m_multiplication_factor_dY,
        m_multiplication_factor_dty,
        m_multiplication_factor_dtx,
        m_ghost_killer_threshold,
        m_n_overflow_track_matching.data(context));
    }
    else if (m_matching_no_ut_ghost_killer_version == 2) {
      global_function(track_matching_veloSciFi<Allen::NeuralNetwork::Model::MatchingNoUTV2GhostKiller>)(
        dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        constants.dev_magnet_polarity.data(),
        constants.dev_matching_no_ut_v2_ghost_killer,
        m_momentum_parameters,
        m_z_magnet_parameters,
        m_multiplication_factor_dX,
        m_multiplication_factor_dY,
        m_multiplication_factor_dty,
        m_multiplication_factor_dtx,
        m_ghost_killer_threshold,
        m_n_overflow_track_matching.data(context));
    }
    else {
      throw std::invalid_argument("matching_no_ut_ghost_killer_version can only be [1, 2].");
    }
  }

  if (has_ut) {
    // Add UT hits
    global_function(track_matching_add_ut_hits)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments,
      constants.dev_magnet_polarity.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_sector_xs.data(),
      m_ut_x_loose_tolerance_parameters,
      m_ut_x_tight_tolerance_parameters,
      m_ut_y_tolerance_parameters,
      constants.dev_ut_per_layer_info,
      m_n_overflow_track_matching.data(context));

    // Filter bad ut segments (by requiring min number of ut hits or chi2)
    global_function(track_matching_filter_bad_ut_segment)(
      dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments, m_min_num_ut_hits);

    // Select only one best ut segement for each VeloSciFi matched result
    global_function(track_matching_select_best_ut_segment)(
      dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
  }

  if (use_with_ut_neural_network) {
    // Fit UT segment and evaluate ghost probability
    if (m_matching_with_ut_ghost_killer_version == 1) {
      global_function(track_matching_ghost_killing<Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller>)(
        dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        m_z_magnet_parameters,
        m_multiplication_factor_dX,
        m_multiplication_factor_dY,
        m_multiplication_factor_dty,
        m_multiplication_factor_dtx,
        m_ghost_killer_threshold,
        constants.dev_matching_with_ut_ghost_killer);
    }
    else if (m_matching_with_ut_ghost_killer_version == 2) {
      global_function(track_matching_ghost_killing<Allen::NeuralNetwork::Model::MatchingWithUTV2GhostKiller>)(
        dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        m_z_magnet_parameters,
        m_multiplication_factor_dX,
        m_multiplication_factor_dY,
        m_multiplication_factor_dty,
        m_multiplication_factor_dtx,
        m_ghost_killer_threshold,
        constants.dev_matching_with_ut_v2_ghost_killer);
    }
    else {
      throw std::invalid_argument("matching_no_ut_ghost_killer_version can only be [1, 2].");
    }
  }

  // Clone killing
  global_function(track_matching_clone_killing)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);

  PrefixSum::prefix_sum<dev_offsets_matched_tracks_t, host_number_of_reconstructed_matched_tracks_t>(
    *this, arguments, context);
}

template<typename GhostKiller_t>
__global__ void track_matching::track_matching_veloSciFi(
  track_matching::Parameters parameters,
  const float* dev_magnet_polarity,
  const GhostKiller_t* dev_matching_ghost_killer,
  const std::array<float, 16> momentum_parameters,
  const std::array<float, 5> z_magnet_parameters,
  const float multiplication_factor_dX,
  const float multiplication_factor_dY,
  const float multiplication_factor_dty,
  const float multiplication_factor_dtx,
  const float ghost_killer_threshold,
  [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_track_matching)
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

  auto& n_matched = parameters.dev_offsets_matched_tracks[event_number];

  SciFi::MatchedTrack* matched_tracks_event =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  for (unsigned i = threadIdx.x; i < number_of_scifi_seeds; i += blockDim.x) {
    const auto scifi_state = scifi_states[i];

    // Loop over filtered velo tracks
    for (unsigned ivelo = 0; ivelo < ut_number_of_selected_tracks; ivelo++) {

      const auto velo_track_index = ut_selected_velo_tracks[ivelo];
      const auto endvelo_state = velo_states.state(velo_track_index);
      auto matchingInfo = getChi2Match(
        endvelo_state,
        scifi_state,
        z_magnet_parameters,
        multiplication_factor_dX,
        multiplication_factor_dY,
        multiplication_factor_dty,
        multiplication_factor_dtx);
      if (matchingInfo.chi2 > TrackMatchingConsts::maxChi2) continue;

      const auto velo_eta = asinhf(1.f / hypotf(endvelo_state.tx(), endvelo_state.ty()));

      float ghost_killer_score = 0.f;
      if constexpr (!std::is_same_v<GhostKiller_t, void>) {
        if constexpr (std::is_same_v<GhostKiller_t, Allen::NeuralNetwork::Model::MatchingGhostKiller>) {
          float ghost_killer_inputs[Allen::NeuralNetwork::Model::MatchingGhostKiller::nInput] = {
            matchingInfo.zForX,
            matchingInfo.distX,
            matchingInfo.distY,
            matchingInfo.dSlopeX,
            matchingInfo.dSlopeY,
            logf(matchingInfo.chi2),
            velo_eta};
          ghost_killer_score = Allen::NeuralNetwork::evaluate(dev_matching_ghost_killer, ghost_killer_inputs);
        }
        else {
          const auto number_of_scifi_hits = float(scifi_seeds.track(i).number_of_scifi_hits());
          float ghost_killer_inputs[Allen::NeuralNetwork::Model::MatchingNoUTV2GhostKiller::nInput] = {
            matchingInfo.zForX,
            matchingInfo.distX,
            matchingInfo.distY,
            matchingInfo.dSlopeX,
            matchingInfo.dSlopeY,
            matchingInfo.chi2,
            velo_eta,
            number_of_scifi_hits};
          ghost_killer_score = Allen::NeuralNetwork::evaluate(dev_matching_ghost_killer, ghost_killer_inputs);
        }

        if (ghost_killer_score > ghost_killer_threshold) continue;
      }

      // Save the result
      auto idx = atomicAdd(&n_matched, 1);
      if (idx >= TrackMatchingConsts::max_num_tracks) break;

      auto& matched_track = matched_tracks_event[idx];

      const auto magSign = -dev_magnet_polarity[0];
      const auto qop =
        computeQoverP(endvelo_state.tx(), endvelo_state.ty(), scifi_state.tx(), magSign, momentum_parameters);

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

  __syncthreads();
  if (threadIdx.x == 0 && n_matched > TrackMatchingConsts::max_num_tracks) {
    // If there are more than the maximum number of tracks, don't save any
    // reconstructed tracks to avoid non-deterministic behavior.
    // TODO: Add counter here?
    n_matched = 0;
    dev_n_overflow_track_matching.increment();
  }
}

__global__ void track_matching::track_matching_add_ut_hits(
  track_matching::Parameters parameters,
  const float* dev_magnet_polarity,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const float* dev_unique_sector_xs,
  const std::array<float, 4 * 3> ut_x_loose_tolerance_parameters,
  const std::array<float, 4 * 3> ut_x_tight_tolerance_parameters,
  const float ut_y_tolerance_parameters,
  const UT::Constants::PerLayerInfo* dev_mean_layer_info,
  [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_track_matching)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load long track candidates
  auto& n_matched_tracks_event = parameters.dev_offsets_matched_tracks[event_number];
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

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  using UT::Constants::n_layers;

  // Allocate the memory
  __shared__ typename UTHitsCache::ElementType shared_memory_hit_caching[UTHitsCache::NumElements];

  // Hit Cache
  UTHitsCache hit_cache {shared_memory_hit_caching};
  UT::SectorHelper sector_cache;

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
    hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_mean_layer_info, layer);
    sector_cache.cache_layer(ut_hit_offsets, dev_unique_sector_xs, dev_unique_x_sector_layer_offsets, layer);

    const auto const_n_matched_tracks_event = n_matched_tracks_event;
    __syncthreads();

    // Cache/Alias certain values
    const auto dxdy = dev_mean_layer_info->mean_dxDy[layer];
    const auto layer_z = dev_mean_layer_info->mean_z[layer];

    // Add hits to each candidates
    for (unsigned candidate_idx = threadIdx.x; candidate_idx < const_n_matched_tracks_event;
         candidate_idx += blockDim.x) {

      // Alias
      auto& matched_track = matched_tracks_event[candidate_idx];

      // Early stop: if layer==3 but not hit was found before (We need at least 2 hits to make UT segment)
      const auto first_hit = std::isnan(matched_track.gamma);
      if (first_hit && layer == 3) continue;

      // Get state
      const auto endvelo_state = velo_states.state(matched_track.velo_track_index);

      // Load extrapolation
      auto trajectory = first_hit ? track_matching::tools::VeloToUTExtrapolator(
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
      const auto xTol = trajectory.get_tolerance(
        first_hit ? ut_x_loose_tolerance_parameters.data() + 4 * (layer) :
                    ut_x_tight_tolerance_parameters.data() + 4 * (layer - 1));
      const auto yTol = ut_y_tolerance_parameters;

      // Get expected x and open the search window
      const auto expected_layer_y = trajectory.yAtZ(layer_z);
      const auto expected_layer_x = trajectory.xAtZ(layer_z) - dxdy * expected_layer_y;
      const auto hit_range = sector_cache.get_hit_range(expected_layer_x - xTol, expected_layer_x + xTol);

      // Find best hit
      if (first_hit) // In case of first hit, each hit is a independent candidate
      {
        using track_matching::tools::MultiCandidateManager;
        MultiCandidateManager<ushort, 8, true> best_hits;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const auto hit = hit_cache.hit(hit_idx);
          const float expected_hit_y = trajectory.yAtZ(hit.zAtYEq0());
          if (hit.isNotYCompatible(expected_hit_y, yTol)) continue;
          const float xdist = trajectory.xAtZ(hit.zAtYEq0()) - hit.xAt(expected_hit_y);
          if (fabsf(xdist) > xTol) continue;
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
            const auto hit = hit_cache.hit(best_hit_idx);
            const float expected_hit_y = trajectory.yAtZ(hit.zAtYEq0());
            matched_track.gamma = trajectory.get_new_gamma(hit.zAtYEq0(), hit.xAt(expected_hit_y));
          }
          else {
            // Rest of hits have to create new candidates
            const auto new_candidate_idx = atomicAdd(&n_matched_tracks_event, 1u);
            if (new_candidate_idx >= TrackMatchingConsts::max_num_tracks) break;
            const auto best_hit_idx = best_hits.get(best_hits_idx);

            // Clone candidate
            matched_tracks_event[new_candidate_idx] = matched_track;

            // Modify the ut hit
            matched_tracks_event[new_candidate_idx].ut_hits[layer] = hit_cache.HitOffset() + best_hit_idx;

            // Modify the gamma
            const auto hit = hit_cache.hit(best_hit_idx);
            const float expected_hit_y = trajectory.yAtZ(hit.zAtYEq0());
            matched_tracks_event[new_candidate_idx].gamma =
              trajectory.get_new_gamma(hit.zAtYEq0(), hit.xAt(expected_hit_y));
          }
        }
      }
      else {
        using track_matching::tools::BestCandidateManager;
        BestCandidateManager<ushort, true> best_hit;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const auto hit = hit_cache.hit(hit_idx);
          const float expected_hit_y = trajectory.yAtZ(hit.zAtYEq0());
          if (hit.isNotYCompatible(expected_hit_y, yTol)) continue;
          const float xdist = trajectory.xAtZ(hit.zAtYEq0()) - hit.xAt(expected_hit_y);
          if (fabsf(xdist) > xTol) continue;
          best_hit.add(hit_idx, xdist);
        };
        if (!best_hit.exist()) continue;

        // update gamma
        const auto hit = hit_cache.hit(best_hit.best());
        const float expected_hit_y = trajectory.yAtZ(hit.zAtYEq0());
        matched_track.gamma =
          (matched_track.gamma + trajectory.get_new_gamma(hit.zAtYEq0(), hit.xAt(expected_hit_y))) / 2;

        // Add best hit
        matched_track.ut_hits[layer] = hit_cache.HitOffset() + best_hit.best();
        matched_track.ut_score += best_hit.score() * best_hit.score();
        matched_track.number_of_hits_ut++;
      }
    }
    __syncthreads();
    if (threadIdx.x == 0) {
      if (n_matched_tracks_event > TrackMatchingConsts::max_num_tracks) {
        n_matched_tracks_event = 0;
        dev_n_overflow_track_matching.increment();
      }
    }
    __syncthreads();
  }
}

__global__ void track_matching::track_matching_filter_bad_ut_segment(
  Parameters parameters,
  const unsigned min_num_ut_hits)
{
  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load long track candidates
  auto num_tracks = parameters.dev_offsets_matched_tracks + event_number;
  auto matched_tracks_event = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  //
  // Shared memory initialization
  //
  const auto const_num_tracks = num_tracks[0];
  __syncthreads();
  __shared__ bool killed[TrackMatchingConsts::max_num_tracks];
  if (threadIdx.x == 0) {
    num_tracks[0] = 0; // Reset number of tracks
  }
  __syncthreads();

  //
  // Filter bad segments
  //
  for (unsigned i = threadIdx.x; i < const_num_tracks; i += blockDim.x) {

    // Fetch candidate info
    auto& matched_track = matched_tracks_event[i];

    killed[i] = (matched_track.number_of_hits_ut < min_num_ut_hits);
  }
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

__global__ void track_matching::track_matching_select_best_ut_segment(Parameters parameters)
{
  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load long track candidates
  auto num_tracks = parameters.dev_offsets_matched_tracks + event_number;
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

      if (
        (track_1.velo_track_index == track_2.velo_track_index) &&
        (track_1.scifi_track_index == track_2.scifi_track_index)) {
        if (track_1.number_of_hits_ut < track_2.number_of_hits_ut) {
          killed[n_track_1] = true;
        }
        else if (track_1.number_of_hits_ut > track_2.number_of_hits_ut) {
          killed[n_track_2] = true;
        }
        else if (track_1.ut_score <= track_2.ut_score) {
          killed[n_track_2] = true;
        }
        else if (track_1.ut_score > track_2.ut_score) {
          killed[n_track_1] = true;
        }
      };
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

template<typename GhostKiller_t>
__global__ void track_matching::track_matching_ghost_killing(
  track_matching::Parameters parameters,
  const std::array<float, 5> z_magnet_parameters,
  const float multiplication_factor_dX,
  const float multiplication_factor_dY,
  const float multiplication_factor_dty,
  const float multiplication_factor_dtx,
  const float ghost_killer_threshold,
  const GhostKiller_t* dev_matching_ghost_killer)
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
  auto num_tracks = parameters.dev_offsets_matched_tracks + event_number;
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
    const auto matchingInfo = getChi2Match(
      vp_state,
      ft_state,
      z_magnet_parameters,
      multiplication_factor_dX,
      multiplication_factor_dY,
      multiplication_factor_dty,
      multiplication_factor_dtx);
    const auto velo_eta = asinhf(1.f / hypotf(vp_state.tx(), vp_state.ty()));

    // Evaluate NN based ghost killer
    if constexpr (std::is_same_v<GhostKiller_t, Allen::NeuralNetwork::Model::MatchingWithUTGhostKiller>) {
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
    }
    else if constexpr (std::is_same_v<GhostKiller_t, Allen::NeuralNetwork::Model::MatchingWithUTV2GhostKiller>) {
      float ghost_killer_inputs[Allen::NeuralNetwork::Model::MatchingWithUTV2GhostKiller::nInput] = {
        matchingInfo.zForX,
        matchingInfo.distX,
        matchingInfo.distY,
        matchingInfo.dSlopeX,
        matchingInfo.dSlopeY,
        logf(matchingInfo.chi2),
        velo_eta,
        float(scifi_seeds.track(matched_track.scifi_track_index).number_of_scifi_hits()),
        logf(matched_track.ut_score / (matched_track.number_of_hits_ut - 1)),
        float(matched_track.number_of_hits_ut)};
      matched_track.score = Allen::NeuralNetwork::evaluate(dev_matching_ghost_killer, ghost_killer_inputs);
    }
    killed[i] = (matched_track.score > ghost_killer_threshold);
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

__global__ void track_matching::track_matching_clone_killing(track_matching::Parameters parameters)
{
  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Load long track candidates
  auto num_tracks = parameters.dev_offsets_matched_tracks + event_number;
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

      if ((shared_seeds >= 1) && (fabsf(track_1.score - track_2.score) > 0.05f)) {
        if (track_1.score <= track_2.score) {
          killed[n_track_2] = true;
        }
        else {
          killed[n_track_1] = true;
        };
      };
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
