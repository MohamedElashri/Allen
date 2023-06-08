/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "TrackMatchingVELOSciFi.cuh"
#include "TrackMatchingHelpers.cuh"

INSTANTIATE_ALGORITHM(track_matching_veloSciFi::track_matching_veloSciFi_t);

void track_matching_veloSciFi::track_matching_veloSciFi_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_matched_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * TrackMatchingConsts::max_num_tracks);
  set_size<dev_atomics_matched_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
}

void track_matching_veloSciFi::track_matching_veloSciFi_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_atomics_matched_tracks_t>(arguments, 0, context);

  global_function(track_matching_veloSciFi)(dim3(size<dev_event_list_t>(arguments)), dim3(128), context)(
    arguments, constants.dev_magnet_polarity.data(), constants.dev_magnet_parametrization);
}

// inspired from https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/PrAlgorithms/src/PrMatchNN.cpp
__device__ track_matching::MatchingResult getChi2Match(
  const MiniState velo_state,
  const MiniState scifi_state,
  const TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization)
{

  const float xpos_velo = velo_state.x, ypos_velo = velo_state.y, zpos_velo = velo_state.z, tx_velo = velo_state.tx,
              ty_velo = velo_state.ty;
  const float xpos_scifi = scifi_state.x, ypos_scifi = scifi_state.y, zpos_scifi = scifi_state.z,
              tx_scifi = scifi_state.tx, ty_scifi = scifi_state.ty;

  const float dSlopeX = tx_velo - tx_scifi;
  if (std::abs(dSlopeX) > 1.5f)
    return {9999., 9999., 9999., 9999., 9999., 9999.}; // matching the UT/SciFi slopes in X (bending -> large tolerance)

  const float dSlopeY = ty_velo - ty_scifi;
  if (std::abs(dSlopeY) > 0.02f)
    return {9999.f, 9999.f, 9999.f, 9999.f, 9999.f, 9999.f}; // matching the UT/SciFi slopes in Y (no bending)

  const float zForX = dev_magnet_parametrization->zMagnetParamsMatch[0] +
                      dev_magnet_parametrization->zMagnetParamsMatch[1] * std::abs(dSlopeX) +
                      dev_magnet_parametrization->zMagnetParamsMatch[2] * dSlopeX * dSlopeX +
                      dev_magnet_parametrization->zMagnetParamsMatch[3] * std::abs(xpos_scifi) +
                      dev_magnet_parametrization->zMagnetParamsMatch[4] * tx_velo * tx_velo;
  const float dxTol2 = TrackMatchingConsts::dxTol * TrackMatchingConsts::dxTol;
  const float dxTolSlope2 = TrackMatchingConsts::dxTolSlope * TrackMatchingConsts::dxTolSlope;
  const float xV = xpos_velo + (zForX - zpos_velo) * tx_velo;
  // -- This is the function that calculates the 'bending' in y-direction
  // -- The parametrisation can be derived with the MatchFitParams package
  const float yV = (ypos_velo + (TrackMatchingConsts::zMatchY - zpos_velo) * ty_velo) * 1.02f;
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
  const float fdX = 0.8f;
  const float fdY = 0.2f; // Reduced the importance of dY info until y issue is fixed
  const float fdty = 937.5f;
  const float fdtx = 2.f;

  float chi2 = (tolX != 0.f and tolY != 0.f ? fdX * distX * distX / tolX + fdY * distY * distY / tolY : 9999.f);
  // float chi2 = ( tolX != 0 and tolY != 0 ? distX * distX / tolX : 9999. );

  chi2 += fdty * dSlopeY * dSlopeY;
  chi2 += fdtx * dSlopeX * dSlopeX;

  return {dSlopeX, dSlopeY, distX, distY, zForX, chi2};
}
// Parametrization from SciFiTrackForwarding.cpp , found to work better than FastMomentumEstimate.cpp
// https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Pr/SciFiTrackForwarding/src/SciFiTrackForwarding.cpp#L321
//
__device__ float computeQoverP(
  const float txV,
  const float tyV,
  const float txT,
  const float magSign,
  const TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization)
{
  const float txT2 = txT * txT;
  const float tyV2 = tyV * tyV;
  const float coef =
    (dev_magnet_parametrization->momentumParams[0] +
     txT2 * (dev_magnet_parametrization->momentumParams[1] + dev_magnet_parametrization->momentumParams[2] * txT2) +
     dev_magnet_parametrization->momentumParams[3] * txT * txV +
     tyV2 * (dev_magnet_parametrization->momentumParams[4] + dev_magnet_parametrization->momentumParams[5] * tyV2) +
     dev_magnet_parametrization->momentumParams[6] * txV * txV);

  const float factor = std::copysign(magSign, txV - txT);
  const float cp = (magSign * coef) / (txT - txV) + factor * dev_magnet_parametrization->momentumParams[7];
  return 1.f / cp;
}

__global__ void track_matching_veloSciFi::track_matching_veloSciFi(
  track_matching_veloSciFi::Parameters parameters,
  const float* dev_magnet_polarity,
  const TrackMatchingConsts::MagnetParametrization* dev_magnet_parametrization)
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

  unsigned* n_matched_tracks_event = parameters.dev_atomics_matched_tracks + event_number;

  SciFi::MatchedTrack* matched_tracks_event =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  __shared__ unsigned int n_matched;

  // Reset values
  if (threadIdx.x == 0) {
    *n_matched_tracks_event = 0;
    n_matched = 0;
  };
  __syncthreads();

  for (unsigned i = threadIdx.x; i < number_of_scifi_seeds; i += blockDim.x) {
    const auto scifi_state = scifi_states[i];
    auto& scifiseed = scifi_seeds.track(i);

    track_matching::Match BestMatch = {-9999, 1000.f};

    // Loop over filtered velo tracks
    for (unsigned ivelo = 0; ivelo < ut_number_of_selected_tracks; ivelo++) {

      const auto velo_track_index = ut_selected_velo_tracks[ivelo];
      const auto endvelo_state = velo_states.state(velo_track_index);
      auto matchingInfo = getChi2Match(endvelo_state, scifi_state, dev_magnet_parametrization);
      if (matchingInfo.chi2 < BestMatch.chi2) {
        BestMatch = {static_cast<int>(velo_track_index), matchingInfo.chi2};
      }
    }

    if ((BestMatch.chi2 > TrackMatchingConsts::maxChi2) || (n_matched >= TrackMatchingConsts::max_num_tracks)) continue;

    // Save the result
    auto idx = atomicAdd(&n_matched, 1);
    auto& matched_track = matched_tracks_event[idx];

    matched_track.velo_track_index = BestMatch.ivelo;
    matched_track.scifi_track_index = i;

    matched_track.number_of_hits_velo = velo_tracks.track(BestMatch.ivelo).number_of_hits();
    matched_track.number_of_hits_scifi = scifiseed.number_of_scifi_hits();
    matched_track.chi2_matching = BestMatch.chi2;

    const auto endvelo_state = velo_states.state(BestMatch.ivelo);

    const auto magSign = -dev_magnet_polarity[0];
    matched_track.qop =
      computeQoverP(endvelo_state.tx(), endvelo_state.ty(), scifi_state.tx, magSign, dev_magnet_parametrization);
  }
  __syncthreads();

  // clone killing
  __shared__ bool clone_label[TrackMatchingConsts::max_num_tracks];
  for (unsigned i = threadIdx.x; i < n_matched; i += blockDim.x) {
    clone_label[i] = false;
  }
  __syncthreads();

  for (unsigned n_track_1 = threadIdx.x; n_track_1 < n_matched; n_track_1 += blockDim.x) {
    if (clone_label[n_track_1] == true) continue;

    auto& track_1 = matched_tracks_event[n_track_1];

    for (unsigned n_track_2 = n_track_1 + 1; n_track_2 < n_matched; n_track_2 += 1) {
      auto& track_2 = matched_tracks_event[n_track_2];

      int shared_seeds = 0;
      if (track_1.velo_track_index == track_2.velo_track_index) {
        shared_seeds += 1;
      };

      if (shared_seeds >= 1) {
        // if ( fabs(track_1.chi2 - track_2.chi2) < 0.1 ) continue;

        if (track_1.chi2_matching <= track_2.chi2_matching) {
          clone_label[n_track_2] = true;
        }
        else {
          clone_label[n_track_1] = true;
          break;
        };
      };
    };
  };
  __syncthreads();

  for (unsigned i = threadIdx.x; i < n_matched; i += blockDim.x) {
    auto track = matched_tracks_event[i];
    __syncthreads();
    if (clone_label[i] != true) {
      unsigned idx = atomicAdd(n_matched_tracks_event, 1u);
      matched_tracks_event[idx] = track;
    }
    __syncthreads();
  };
}
