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
#include "ParKalmanFilter.cuh"

INSTANTIATE_ALGORITHM(kalman_filter::kalman_filter_t)

namespace kalman_filter { // [nSets * nPars + 2]
  __constant__ float dev_UT_lay[1 * 4 + 2];
  __constant__ float dev_T_lay[4 * 12 + 2];
  __constant__ float dev_UTT_META[1 * 19 + 2];

  __constant__ float dev_V_pars[2 * 6 + 2];
  __constant__ float dev_VUT_pars[1 * 15 + 2];
  __constant__ float dev_UT_pars[6 * 18 + 2];
  __constant__ float dev_UTTF_pars[1 * 20 + 2];
  __constant__ float dev_T_pars[44 * 18 + 2];
  __constant__ float dev_TFT_pars[1 * 4 + 2];
} // namespace kalman_filter

void kalman_filter::kalman_filter_t::update(const Constants& constants) const
{
  Allen::memcpyToSymbol(dev_UT_lay, constants.host_UT_Layers, (1 * 4 + 2) * sizeof(float));
  Allen::memcpyToSymbol(dev_T_lay, constants.host_T_Layers, (4 * 12 + 2) * sizeof(float));
  if (constants.host_magnet_polarity.empty()) {
    throw std::runtime_error("host_magnet_polarity is empty");
  }
  const float magSign = constants.host_magnet_polarity[0];
  if (magSign == 0.0f) {
    throw std::runtime_error("host_magnet_polarity is zero");
  }
  if (magSign > 0.f) {
    Allen::memcpyToSymbol(dev_V_pars, constants.host_VP_pars_MU, (2 * 6 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_VUT_pars, constants.host_VPUT_pars_MU, (1 * 15 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UT_pars, constants.host_UT_pars_MU, (6 * 18 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UTTF_pars, constants.host_UTTF_pars_MU, (1 * 20 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_T_pars, constants.host_T_pars_MU, (44 * 18 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_TFT_pars, constants.host_TFT_pars_MU, (1 * 4 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UTT_META, constants.host_UTT_META_MU, (1 * 19 + 2) * sizeof(float));
  }
  else {
    Allen::memcpyToSymbol(dev_V_pars, constants.host_VP_pars_MD, (2 * 6 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_VUT_pars, constants.host_VPUT_pars_MD, (1 * 15 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UT_pars, constants.host_UT_pars_MD, (6 * 18 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UTTF_pars, constants.host_UTTF_pars_MD, (1 * 20 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_T_pars, constants.host_T_pars_MD, (44 * 18 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_TFT_pars, constants.host_TFT_pars_MD, (1 * 4 + 2) * sizeof(float));
    Allen::memcpyToSymbol(dev_UTT_META, constants.host_UTT_META_MD, (1 * 19 + 2) * sizeof(float));
  }
}

void kalman_filter::kalman_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_scifi_tracks = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  set_size<dev_kf_tracks_t>(arguments, n_scifi_tracks);
  set_size<dev_kalman_pv_ip_t>(arguments, Associate::Consolidated::table_size(n_scifi_tracks));
  set_size<dev_kalman_fit_results_t>(arguments, n_scifi_tracks * Velo::Consolidated::States::size);
  set_size<dev_kalman_states_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_kalman_pv_tables_t>(arguments, first<host_number_of_events_t>(arguments));
}

void kalman_filter::kalman_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
#ifndef TARGET_DEVICE_CPU
  dim3 block_dim = m_block_dim;
  int _gridDim = (first<host_number_of_reconstructed_scifi_tracks_t>(arguments) + (block_dim.x) - 1) / (block_dim.x);
#else
  // CPU implementation
  int _gridDim = size<dev_event_list_t>(arguments);
#endif
  global_function(kalman_filter)(dim3(_gridDim), m_block_dim, context)(
    arguments, constants.dev_magnet_polarity.data(), constants.dev_kalman_params);

  global_function(kalman_pv_ip)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
}

namespace ParKalmanFilter {
  //----------------------------------------------------------------------
  // Create the output track.
  __device__ void MakeTrack(
    const KalmanFloat& init_qop,
    const Vector5& x,
    const SymMatrix5x5& C,
    const trackInfo& tI,
    FittedTrack& track,
    const unsigned& velo_hits,
    unsigned& ut_hits,
    unsigned& scifi_hits)
  {
    track.chi2 = tI.m_chi2V + tI.m_chi2T + tI.m_chi2UT;
    track.chi2V = tI.m_chi2V;
    track.chi2T = tI.m_chi2T;
    track.chi2UT = tI.m_chi2UT;
    track.ndof = scifi_hits + ut_hits + 2 * velo_hits - 5;
    track.ndofV = 2 * velo_hits - 5;
    track.ndofT = scifi_hits - 5;
    track.state = x;
    track.cov = C;
    track.z = tI.m_Lastz;
    track.first_qop = init_qop;
    track.best_qop = tI.m_BestMomEst;
    track.nhits = velo_hits + ut_hits + scifi_hits;
    track.nhitsV = velo_hits;
    track.nhitsUT = ut_hits;
    track.nhitsT = scifi_hits;
  }

  //----------------------------------------------------------------------
  // Run the Kalman filter.
  __device__ void fit(
    const Allen::Views::Velo::Consolidated::Track& velo_track,
    const Allen::Views::UT::Consolidated::Track& ut_track,
    const Allen::Views::SciFi::Consolidated::Track& scifi_track,
    const KalmanFloat init_qop,
    const KalmanParametrizations* kalman_params,
    FittedTrack& track,
    const float* dev_UT_lay,
    const float* dev_T_lay,
    const float* dev_V_pars,
    const float* dev_VUT_pars,
    const float* dev_UT_pars,
    const float* dev_UTTF_pars,
    const float* dev_T_pars,
    const float* dev_TFT_pars,
    const float* dev_UTT_META)
  {
    // Fit information.
    trackInfo tI;
    tI.m_BestMomEst = init_qop;

    // Get Velo Hits
    const unsigned n_velo_hits = velo_track.number_of_hits();
    // get length of the Velo loop
#ifdef TARGET_DEVICE_CUDA // IF CUDA: Use the max in the WARP
    const unsigned int FULL_MASK = 0xffffffff;
    unsigned max_velo_WARP = n_velo_hits;
    for (int mask = warpSize / 2; mask > 0; mask /= 2) {
      max_velo_WARP = max(__shfl_xor_sync(FULL_MASK, max_velo_WARP, mask), max_velo_WARP);
    }
#else // If not CUDA: Just the number of velo hits in each thread
    unsigned max_velo_WARP = n_velo_hits;
#endif
    // Get UT Hits
    const unsigned n_ut_hits = ut_track.number_of_ut_hits();
    unsigned n_ut_layers = 0;

    // Get SciFi Hits
    const unsigned n_scifi_hits = scifi_track.number_of_scifi_hits();
    unsigned n_scifi_layers = 0;

    // Run the fit.
    tI.m_Lastz = -1;
    Vector5 x;
    SymMatrix5x5 C;
    x[4] = init_qop;

    // Initilise the Velo state using the first and last Velo hit
    CreateVeloSeedState(velo_track, n_velo_hits, x, C, tI);
    // sets the state at the position of the first (in z last in index) hit.
    // initialises a very large covariance matrix
    tI.m_chi2V = 0;
    tI.m_chi2T = 0;
    tI.m_chi2UT = 0;

    //------------------------------ Start forward fit.
    // Velo loop.
    // Update on the first hit
    UpdateStateV(velo_track, 1, n_velo_hits - 1, x, C, tI);
    // have to iterate down from `n_velo_hits - 1` to `0`
    for (unsigned i_hit = 1; i_hit < max_velo_WARP; i_hit++) {
      if (n_velo_hits - 1 < i_hit) {
        break;
      }
      PredictStateV(velo_track, dev_V_pars, n_velo_hits - 1 - i_hit, x, C, tI);
      UpdateStateV(velo_track, 1, n_velo_hits - 1 - i_hit, x, C, tI);
    }
    __syncthreads();

    KalmanFloat endVeloZ = tI.m_Lastz; // z position if the last Velo hit

    // make a hit map: encode fro each UT layer [0-3], which index in the ut_track
    // correpsonds to that layer
    // [n , n+4) bits have the index of the hit in the nth layer
    unsigned layer;
    unsigned hit_map0 = 0xffff; // [1111 1111 1111 1111]
    unsigned hit_counter = 0;
    for (hit_counter = 0; hit_counter < n_ut_hits; hit_counter++) {
      layer = ut_track.hit(hit_counter).plane_code();
      // check that there is not already a hit in that layer
      // if there already is one the second hit in that layer will be discarded.
      bool no_hit_in_layer = ((hit_map0 >> (layer * 4)) & 0xf) == 0xf;
      hit_map0 -= no_hit_in_layer * (0xf << (layer * 4)); // clear the place holder
      hit_map0 += no_hit_in_layer * (hit_counter << (layer * 4));
      n_ut_layers += no_hit_in_layer;
    }
    // Velo -> UT.
    hit_counter = (hit_map0 & 0xf); // Checks for hit in first layer
    PredictStateVUT(ut_track, dev_UT_lay, dev_VUT_pars, x, C, tI, hit_counter);
    // m_RefStateForwardV was saved at the last Velo hit.
    __syncthreads();

    //  and update the first ut layer if there is a hit.
    if (hit_counter != 0xf) {
      UpdateStateUT(ut_track, x, C, tI, hit_counter);
    }

    // iterater over the remaining UT layers
    __syncthreads();
    for (layer = 1; layer < 4; layer++) {
      hit_counter = ((hit_map0 >> (layer * 4)) & 0xf);
      PredictStateUT(ut_track, dev_UT_lay, dev_UT_pars, x, C, tI, layer, hit_counter);
      if (hit_counter != 0xf) {
        UpdateStateUT(ut_track, x, C, tI, hit_counter);
      }
    }
    __syncthreads();
    layer = 3; // needed because `PredictStateUTT` calls `ExtrapolateInUT` again
    PredictStateUTT(dev_UT_pars, dev_TFT_pars, dev_UTTF_pars, dev_UTT_META, dev_T_lay, kalman_params, x, C, tI, layer);

    __syncthreads();

    // make T hitmaps: See UT above but now with two seperate maps for the first and last 6 T layers
    hit_map0 = 0xffffff;          // [1111 1111 1111 1111 1111 1111]
    unsigned hit_map1 = 0xffffff; // [1111 1111 1111 1111 1111 1111]
    for (hit_counter = 0; hit_counter < n_scifi_hits; hit_counter++) {
      layer = scifi_track.hit(hit_counter).planeCode() / 2;
      // check that there is not already a hit in that layer
      unsigned& hit_map = (layer < 6) ? hit_map0 : hit_map1;
      layer = layer % 6; // positon relative to front of map (0,6).
      bool no_hit_in_layer = ((hit_map >> (layer * 4)) & 0xf) == 0xf;
      hit_map -= no_hit_in_layer * (0xf << (layer * 4)); // clear the place holder
      hit_map += no_hit_in_layer * (hit_counter << (layer * 4));
      n_scifi_layers += no_hit_in_layer;
    }

    // Predict State UTT already does all the necessary extrapolation to the first layer of FT
    // Update in first T layer if there is a hit.
    // TODO: this could probably use and extrapolation considering the hit in FT.
    // ----- would possibly make the TFT step redundant and improve on it.
    hit_counter = (hit_map0 & 0xf);
    layer = 0;
    if (hit_counter != 0xf) {
      UpdateStateT(scifi_track, dev_T_lay, x, C, tI, hit_counter, layer);
    }
    for (layer = 1; layer < 6; layer++) {
      hit_counter = ((hit_map0 >> (4 * layer)) & 0xf);
      PredictStateT(scifi_track, dev_T_lay, dev_T_pars, x, C, tI, layer, hit_counter);
      if (hit_counter != 0xf) {
        UpdateStateT(scifi_track, dev_T_lay, x, C, tI, hit_counter, layer);
      }
    }
    for (layer = 6; layer < 12; layer++) {
      hit_counter = ((hit_map1 >> (4 * (layer - 6))) & 0xf);
      PredictStateT(scifi_track, dev_T_lay, dev_T_pars, x, C, tI, layer, hit_counter);
      if (hit_counter != 0xf) {
        UpdateStateT(scifi_track, dev_T_lay, x, C, tI, hit_counter, layer);
      }
    }
    __syncthreads();
    //------------------------------ End forward fit.

    // Set state and covariance for VELO-only backward fit
    tI.m_BestMomEst = x[4];
    x[0] = tI.m_RefStateForwardV[0];
    x[1] = tI.m_RefStateForwardV[1];
    x[2] = tI.m_RefStateForwardV[2];
    x[3] = tI.m_RefStateForwardV[3];

    C = similarity_5_5(inverse(tI.m_RefPropForwardTotal), C);

    const unsigned n_velo_hits2 = velo_track.number_of_hits();
    tI.m_Lastz = endVeloZ;

    //------------------------------ Start backward fit.
#ifdef TARGET_DEVICE_CUDA // see VELO forward fit
    const unsigned int FULL_MASK2 = 0xffffffff;
    unsigned max_velo_WARP2 = n_velo_hits2;
    for (int mask = warpSize / 2; mask > 0; mask /= 2) {
      max_velo_WARP2 = max(__shfl_xor_sync(FULL_MASK2, max_velo_WARP2, mask), max_velo_WARP2);
    }
#else
    unsigned max_velo_WARP2 = n_velo_hits2;
#endif
    // Velo loop.
    // Update again on the hit in the last layer
    UpdateStateV(velo_track, -1, 0, x, C, tI);
    for (unsigned i_hit = 1; i_hit < max_velo_WARP2; i_hit++) { // Velo hits are sorted from large z to small z
      if (i_hit > n_velo_hits2 - 1) {
        break;
      }
      PredictStateV(velo_track, dev_V_pars, i_hit, x, C, tI);
      UpdateStateV(velo_track, -1, i_hit, x, C, tI);
    }
    __syncthreads();
    //------------------------------ End backward fit.
    // Straight line extrapolation to the closest point to the beamline.
    // NOTE: Don't do this for now. The track is extrapolated again
    // when calculating IP info anyway.
    // ExtrapolateToVertex(xBest, C, lastz);

    MakeTrack(init_qop, x, C, tI, track, n_velo_hits2, n_ut_layers, n_scifi_layers);
  }
} // End namespace ParKalmanFilter.

__host__ __device__ void
set_result(const unsigned track_number, const ParKalmanFilter::FittedTrack& track, Velo::Consolidated::States& states)
{
  states.x(track_number) = track.state[0];
  states.y(track_number) = track.state[1];
  states.tx(track_number) = track.state[2];
  states.ty(track_number) = track.state[3];
  states.qop(track_number) = track.state[4];
  states.z(track_number) = track.z;

  states.c00(track_number) = track.cov(0, 0);
  // states.c10(track_number) = track.cov(1, 0);
  states.c11(track_number) = track.cov(1, 1);
  states.c20(track_number) = track.cov(2, 0);
  // states.c21(track_number) = track.cov(2, 1);
  states.c22(track_number) = track.cov(2, 2);
  states.c31(track_number) = track.cov(3, 1);
  states.c33(track_number) = track.cov(3, 3);
  states.chi2(track_number) = track.chi2;
  states.ndof(track_number) = track.ndof;
  return;
}
//----------------------------------------------------------------------
// Kalman filter kernel.
__global__ void kalman_filter::kalman_filter(
  kalman_filter::Parameters parameters,
  const float* dev_magnet_polarity,
  const ParKalmanFilter::KalmanParametrizationsStruct* dev_kalman_params)
{
  const auto magSign = dev_magnet_polarity[0];
  const ParKalmanFilter::KalmanParametrizations* kalman_params;
  if (magSign > 0.f) {
    kalman_params = &(dev_kalman_params->par_up);
  }
  else {
    kalman_params = &(dev_kalman_params->par_down);
  }
  // For GPU device: Fill all block to the max regardless of event association.
#ifndef TARGET_DEVICE_CPU // IF GPU: Find the event number matching the position in the grid
  const unsigned track_id = blockIdx.x * blockDim.x + threadIdx.x; // global now, reduce later
  unsigned event_number = UINT_MAX;
  unsigned n_tracks = 0;
  unsigned final_track_id = UINT_MAX;
  // TODO: This implementation does not assume anything about the ordering of events, check which assumptions could be
  // made.
  for (unsigned event_id = 0; event_id < parameters.dev_number_of_events[0]; ++event_id) {
    unsigned current_event_number = parameters.dev_event_list[event_id];
    unsigned n_long_tracks = parameters.dev_long_tracks_view->container(current_event_number).size();
    int condition = (track_id >= n_tracks && track_id < n_tracks + n_long_tracks);
    final_track_id = condition * (track_id - n_tracks) + (1 - condition) * final_track_id;
    event_number = condition * current_event_number + (1 - condition) * event_number;
    n_tracks += n_long_tracks;
  }

  if (event_number == UINT_MAX) {
    return;
  }
  if (final_track_id == UINT_MAX) {
    return;
  }
#else
  // CPU implementation as many blocks as events
  unsigned event_number = parameters.dev_event_list[blockIdx.x];
#endif

  const unsigned total_number_of_tracks = parameters.dev_long_tracks_view->number_of_contained_objects();
  Velo::Consolidated::States kalman_states {parameters.dev_kalman_fit_results, total_number_of_tracks};

  // Get associated UT and VELO tracks.
  const auto event_long_tracks = parameters.dev_long_tracks_view->container(event_number);
  const unsigned n_long_tracks = event_long_tracks.size();

#ifndef TARGET_DEVICE_CPU // IF GPU: don't start more threads than there are tracks
  if (final_track_id < n_long_tracks) {
#else
  // CPU implementation
  for (unsigned final_track_id = threadIdx.x; final_track_id < n_long_tracks; final_track_id += blockDim.x) {
#endif
    // Prepare fit input.
    const auto long_track = event_long_tracks.track(final_track_id);
    // subdetector tracks which will give us access to the hits.
    const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
    const auto ut_track_ptr = long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::ut>();
    const auto ut_track = ut_track_ptr != nullptr ? *ut_track_ptr : Allen::Views::UT::Consolidated::Track();
    const auto scifi_track = long_track.track_segment<Allen::Views::Physics::Track::segment::scifi>();
    const KalmanFloat init_qop = (KalmanFloat) long_track.qop(); // Tracking estimate of qop
    ParKalmanFilter::FittedTrack kalman_track;
    fit(
      velo_track,
      ut_track,
      scifi_track,
      init_qop,
      kalman_params,
      kalman_track,
      dev_UT_lay,
      dev_T_lay,
      dev_V_pars,
      dev_VUT_pars,
      dev_UT_pars,
      dev_UTTF_pars,
      dev_T_pars,
      dev_TFT_pars,
      dev_UTT_META);
    set_result(event_long_tracks.offset() + final_track_id, kalman_track, kalman_states);
    parameters.dev_kf_tracks[event_long_tracks.offset() + final_track_id] = kalman_track;
  }
}