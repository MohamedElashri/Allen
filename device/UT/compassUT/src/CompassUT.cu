#include "CompassUT.cuh"
#include "CompassUTDeviceFunctions.cuh"
#include "BinarySearch.cuh"
#include "UTFastFitter.cuh"

void compass_ut::compass_ut_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_tracks_t>(
    arguments, first<host_number_of_selected_events_t>(arguments) * UT::Constants::max_num_tracks);
  set_size<dev_atomics_ut_t>(arguments, first<host_number_of_selected_events_t>(arguments) * UT::num_atomics);
}

void compass_ut::compass_ut_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_atomics_ut_t>(arguments, 0, cuda_stream);

  global_function(compass_ut)(
    dim3(first<host_number_of_selected_events_t>(arguments)), dim3(UT::Constants::num_thr_compassut), cuda_stream)(
    arguments,
    constants.dev_ut_magnet_tool,
    constants.dev_magnet_polarity.data(),
    constants.dev_ut_dxDy.data(),
    constants.dev_unique_x_sector_layer_offsets.data());
}

__global__ void compass_ut::compass_ut(
  compass_ut::Parameters parameters,
  UTMagnetTool* dev_ut_magnet_tool,
  const float* dev_magnet_polarity,
  const float* dev_ut_dxDy,
  const uint* dev_unique_x_sector_layer_offsets) // prefixsum to point to the x hit of the sector, per layer
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const uint number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const uint total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};
  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const short* windows_layers =
    parameters.dev_ut_windows_layers + event_tracks_offset * CompassUT::num_elems * UT::Constants::n_layers;

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};
  const auto event_hit_offset = ut_hit_offsets.event_offset();

  // parameters.dev_atomics_ut contains in an SoA:
  //   1. # of veloUT tracks
  //   2. # velo tracks in UT acceptance
  // This is to write the final track
  uint* n_veloUT_tracks_event = parameters.dev_atomics_ut + event_number;
  UT::TrackHits* veloUT_tracks_event = parameters.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;

  // store windows and num candidates in shared mem
  __shared__ short win_size_shared[UT::Constants::num_thr_compassut * UT::Constants::n_layers * CompassUT::num_elems];

  const float* bdl_table = &(dev_ut_magnet_tool->bdlTable[0]);

  const auto ut_number_of_selected_tracks = parameters.dev_ut_number_of_selected_velo_tracks[event_number];
  const auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;

  for (uint i = threadIdx.x; i < ut_number_of_selected_tracks; i += blockDim.x) {
    const auto current_velo_track = ut_selected_velo_tracks[i];
    compass_ut_tracking(
      windows_layers,
      number_of_tracks_event,
      current_velo_track,
      event_tracks_offset + current_velo_track,
      velo_states,
      ut_hits,
      ut_hit_offsets,
      bdl_table,
      dev_ut_dxDy,
      dev_magnet_polarity[0],
      win_size_shared,
      n_veloUT_tracks_event,
      veloUT_tracks_event,
      event_hit_offset,
      parameters.min_momentum_final,
      parameters.min_pt_final,
      parameters.max_considered_before_found,
      parameters.delta_tx_2,
      parameters.hit_tol_2,
      parameters.sigma_velo_slope);
  }
}

__device__ void compass_ut::compass_ut_tracking(
  const short* windows_layers,
  const uint number_of_tracks_event,
  const int i_track,
  const uint current_track_offset,
  Velo::Consolidated::ConstStates& velo_states,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const float* bdl_table,
  const float* dev_ut_dxDy,
  const float magnet_polarity,
  short* win_size_shared,
  uint* n_veloUT_tracks_event,
  UT::TrackHits* veloUT_tracks_event,
  const int event_hit_offset,
  const float min_momentum_final,
  const float min_pt_final,
  const uint max_considered_before_found,
  const float delta_tx_2,
  const float hit_tol_2,
  const float sigma_velo_slope)
{
  // select velo track to join with UT hits
  const MiniState velo_state = velo_states.getMiniState(current_track_offset);

  fill_shared_windows(windows_layers, number_of_tracks_event, i_track, win_size_shared);

  // Find compatible hits in the windows for this VELO track
  const auto best_hits_and_params = find_best_hits(
    win_size_shared,
    ut_hits,
    ut_hit_offsets,
    velo_state,
    dev_ut_dxDy,
    max_considered_before_found,
    delta_tx_2,
    hit_tol_2,
    sigma_velo_slope,
    1.f / sigma_velo_slope,
    event_hit_offset);

  const int best_hits[UT::Constants::n_layers] = {
    std::get<0>(best_hits_and_params),
    std::get<1>(best_hits_and_params),
    std::get<2>(best_hits_and_params),
    std::get<3>(best_hits_and_params)};
  const BestParams best_params = std::get<4>(best_hits_and_params);

  // write the final track
  if (best_params.n_hits >= 3) {
    save_track(
      i_track,
      bdl_table,
      velo_state,
      best_params,
      best_hits,
      ut_hits,
      dev_ut_dxDy,
      magnet_polarity,
      n_veloUT_tracks_event,
      veloUT_tracks_event,
      event_hit_offset,
      min_momentum_final,
      min_pt_final);
  }
}

//=============================================================================
// Fill windows and sizes for shared memory
// we store the initial hit of the window and the size of the window
// (3 windows per layer)
//=============================================================================
__device__ void compass_ut::fill_shared_windows(
  const short* windows_layers,
  const int number_of_tracks_event,
  const int i_track,
  short* win_size_shared)
{
  const auto track_pos = UT::Constants::n_layers * number_of_tracks_event;
  const auto track_pos_sh = UT::Constants::n_layers * UT::Constants::num_thr_compassut;

  for (uint layer = 0; layer < UT::Constants::n_layers; ++layer) {
    for (uint pos = 0; pos < CompassUT::num_elems; ++pos) {
      win_size_shared[pos * track_pos_sh + layer * UT::Constants::num_thr_compassut + threadIdx.x] =
        windows_layers[pos * track_pos + layer * number_of_tracks_event + i_track];
    }
  }
}

//=========================================================================
// These things are all hardcopied from the PrTableForFunction and PrUTMagnetTool
// If the granularity or whatever changes, this will give wrong results
//=========================================================================
__host__ __device__ int compass_ut::master_index(const int index1, const int index2, const int index3)
{
  return (index3 * 11 + index2) * 31 + index1;
}

//=========================================================================
// prepare the final track
//=========================================================================
__device__ void compass_ut::save_track(
  const int i_track,
  const float* bdl_table,
  const MiniState& velo_state,
  const BestParams& best_params,
  const int* best_hits,
  UT::ConstHits& ut_hits,
  const float* ut_dxDy,
  const float magSign,
  uint* n_veloUT_tracks,        // increment number of tracks
  UT::TrackHits* VeloUT_tracks, // write the track
  const int event_hit_offset,
  const float min_momentum_final,
  const float min_pt_final)
{
  //== Handle states. copy Velo one, add UT.
  const float zOrigin = (fabsf(velo_state.ty) > 0.001f) ? velo_state.z - velo_state.y / velo_state.ty :
                                                          velo_state.z - velo_state.x / velo_state.tx;

  // -- These are calculations, copied and simplified from PrTableForFunction
  const float var[3] = {velo_state.ty, zOrigin, velo_state.z};

  const int index1 = max(0, min(30, int((var[0] + 0.3f) / 0.6f * 30)));
  const int index2 = max(0, min(10, int((var[1] + 250) / 500 * 10)));
  const int index3 = max(0, min(10, int(var[2] / 800 * 10)));

  assert(master_index(index1, index2, index3) < UTMagnetTool::N_bdl_vals);
  float bdl = bdl_table[master_index(index1, index2, index3)];

  const int num_idx = 3;
  const float bdls[num_idx] = {
    bdl_table[master_index(index1 + 1, index2, index3)],
    bdl_table[master_index(index1, index2 + 1, index3)],
    bdl_table[master_index(index1, index2, index3 + 1)]};
  const float deltaBdl[num_idx] = {0.02f, 50.0f, 80.0f};
  const float boundaries[num_idx] = {
    -0.3f + float(index1) * deltaBdl[0], -250.0f + float(index2) * deltaBdl[1], 0.0f + float(index3) * deltaBdl[2]};

  // This is an interpolation, to get a bit more precision
  float addBdlVal = 0.0f;
  const float minValsBdl[num_idx] = {-0.3f, -250.0f, 0.0f};
  const float maxValsBdl[num_idx] = {0.3f, 250.0f, 800.0f};
  for (int i = 0; i < num_idx; ++i) {
    if (var[i] < minValsBdl[i] || var[i] > maxValsBdl[i]) continue;
    const float dTab_dVar = (bdls[i] - bdl) / deltaBdl[i];
    const float dVar = (var[i] - boundaries[i]);
    addBdlVal += dTab_dVar * dVar;
  }
  bdl += addBdlVal;

  float finalParams[4] = {
    best_params.x,
    best_params.tx,
    velo_state.y + velo_state.ty * (UT::Constants::zMidUT - velo_state.z),
    best_params.chi2UT};

  // const float qpxz2p = -1 * sqrtf(1.0f + velo_state.ty * velo_state.ty) / bdl * 3.3356f / Gaudi::Units::GeV;
  const float qpxz2p = -1.f / bdl * 3.3356f / Gaudi::Units::GeV;
  // const float qp = best_params.qp;
  const float qp = fastfitter(best_params, velo_state, best_hits, qpxz2p, ut_dxDy, ut_hits, finalParams);
  const float qop = (fabsf(bdl) < 1.e-8f) ? 0.0f : qp * qpxz2p;

  // -- Don't make tracks that have grossly too low momentum
  // -- Beware of the momentum resolution!
  const float p = 1.3f * fabsf(1.f / qop);
  const float pt = p * sqrtf(velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty);

  if (p < min_momentum_final || pt < min_pt_final) return;

  const float xUT = finalParams[0];
  const float txUT = finalParams[1];
  const float yUT = finalParams[2];

  // -- apply some fiducial cuts
  // -- they are optimised for high pT tracks (> 500 MeV)

  if (magSign * qop < 0.0f && xUT > -48.0f && xUT < 0.0f && fabsf(yUT) < 33.0f) return;
  if (magSign * qop > 0.0f && xUT < 48.0f && xUT > 0.0f && fabsf(yUT) < 33.0f) return;

  if (magSign * qop < 0.0f && txUT > 0.09f + 0.0003f * pt) return;
  if (magSign * qop > 0.0f && txUT < -0.09f - 0.0003f * pt) return;

  // -- evaluate the linear discriminant and reject ghosts
  // -- the values only make sense if the fastfitter is performed
  int nHits = 0;
  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    if (best_hits[i] != -1) {
      nHits++;
    }
  }
  const float evalParams[3] = {p, pt, finalParams[3]};
  const float discriminant = evaluateLinearDiscriminant(evalParams, nHits);
  if (discriminant < UT::Constants::LD3Hits) return;

  // the track will be added
  uint n_tracks = atomicAdd(n_veloUT_tracks, 1u);

  // // to do: maybe save y from fit
  UT::TrackHits track;
  track.velo_track_index = static_cast<uint16_t>(i_track);
  track.qop = qop;
  track.x = best_params.x;
  track.z = best_params.z;
  track.tx = best_params.tx;
  track.hits_num = 0;

  // Adding hits to track
  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    if (best_hits[i] != -1) {
      track.hits[i] = static_cast<int16_t>(best_hits[i] - event_hit_offset);
      ++track.hits_num;
    }
    else {
      track.hits[i] = static_cast<int16_t>(-1);
    }
  }

  assert(n_tracks < UT::Constants::max_num_tracks);
  VeloUT_tracks[n_tracks] = track;
}

//=========================================================================
// Get the best 3 or 4 hits, 1 per layer, for a given VELO track
// When iterating over a panel, 3 windows are given, we set the index
// to be only in the windows
//=========================================================================
__device__ std::tuple<int, int, int, int, BestParams> compass_ut::find_best_hits(
  const short* win_size_shared,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const uint parameter_max_considered_before_found,
  const float delta_tx_2,
  const float hit_tol_2,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope,
  const int event_hit_offset)
{
  uint number_of_candidates = 0;
  uint candidate_pairs[UT::Constants::max_value_considered_before_found];

  const uint max_considered_before_found =
    parameter_max_considered_before_found > UT::Constants::max_value_considered_before_found ?
      UT::Constants::max_value_considered_before_found :
      parameter_max_considered_before_found;

  const float yyProto = velo_state.y - velo_state.ty * velo_state.z;

  const TrackCandidates ranges(win_size_shared);

  int best_hits[UT::Constants::n_layers] = {-1, -1, -1, -1};

  int best_number_of_hits = 3;
  int best_fit = UT::Constants::maxPseudoChi2;
  BestParams best_params;

  // Fill in candidate pairs
  // Get total number of hits for forward + backward in first layer (0 for fwd, 3 for bwd)
  for (int i = 0; number_of_candidates < max_considered_before_found && i < sum_layer_hits(ranges, 0, 3); ++i) {
    const int i_hit0 = calc_index(i, ranges, 0, 3, ut_hit_offsets);
    bool forward = false;

    // set range for next layer if forward or backward
    int layer_2;
    int dxdy_layer = -1;
    if (i < sum_layer_hits(ranges, 0)) {
      forward = true;
      layer_2 = 2;
      dxdy_layer = 0;
    }
    else {
      forward = false;
      layer_2 = 1;
      dxdy_layer = 3;
    }

    // Get info to calculate slope
    const auto zhitLayer0 = ut_hits.zAtYEq0(i_hit0);
    const float yy0 = yyProto + (velo_state.ty * zhitLayer0);
    const auto xhitLayer0 = ut_hits.xAt(i_hit0, yy0, ut_dxDy[dxdy_layer]);

    // 2nd layer
    const int total_hits_2layers_2 = sum_layer_hits(ranges, layer_2);
    for (int j = 0; number_of_candidates < max_considered_before_found && j < total_hits_2layers_2; ++j) {
      int i_hit2 = calc_index(j, ranges, layer_2, ut_hit_offsets);

      // Get info to calculate slope
      const int dxdy_layer_2 = forward ? 2 : 1;
      const auto zhitLayer2 = ut_hits.zAtYEq0(i_hit2);
      const float yy2 = yyProto + (velo_state.ty * zhitLayer2);
      const auto xhitLayer2 = ut_hits.xAt(i_hit2, yy2, ut_dxDy[dxdy_layer_2]);

      // if slope is out of delta range, don't look for triplet/quadruplet
      const auto tx = (xhitLayer2 - xhitLayer0) / (zhitLayer2 - zhitLayer0);
      if (fabsf(tx - velo_state.tx) <= delta_tx_2) {
        candidate_pairs[number_of_candidates++] =
          (forward << 31) | ((i_hit0 - event_hit_offset) << 16) | (i_hit2 - event_hit_offset);
      }
    }
  }

  // Iterate over candidate pairs
  for (uint i = 0; i < number_of_candidates; ++i) {
    const auto pair = candidate_pairs[i];
    const bool forward = pair >> 31;
    const int i_hit0 = event_hit_offset + ((pair >> 16) & 0x7FFF);
    const int i_hit2 = event_hit_offset + (pair & 0x7FFF);

    const auto dxdy_layer = forward ? 0 : 3;
    const auto zhitLayer0 = ut_hits.zAtYEq0(i_hit0);
    const auto yy0 = yyProto + (velo_state.ty * zhitLayer0);
    const auto xhitLayer0 = ut_hits.xAt(i_hit0, yy0, ut_dxDy[dxdy_layer]);

    const auto dxdy_layer_2 = forward ? 2 : 1;
    const auto zhitLayer2 = ut_hits.zAtYEq0(i_hit2);
    const auto yy2 = yyProto + (velo_state.ty * zhitLayer2);
    const auto xhitLayer2 = ut_hits.xAt(i_hit2, yy2, ut_dxDy[dxdy_layer_2]);

    const auto tx = (xhitLayer2 - xhitLayer0) / (zhitLayer2 - zhitLayer0);

    int temp_best_hits[4] = {i_hit0, -1, i_hit2, -1};
    const int layers[2] = {forward ? 1 : 2, forward ? 3 : 0};

    // search for a triplet in 3rd layer
    float hitTol = hit_tol_2;
    for (int i1 = 0; i1 < sum_layer_hits(ranges, layers[0]); ++i1) {

      int i_hit1 = calc_index(i1, ranges, layers[0], ut_hit_offsets);

      // Get info to check tolerance
      const float zhitLayer1 = ut_hits.zAtYEq0(i_hit1);
      const float yy1 = yyProto + (velo_state.ty * zhitLayer1);
      const float xhitLayer1 = ut_hits.xAt(i_hit1, yy1, ut_dxDy[layers[0]]);
      const float xextrapLayer1 = xhitLayer0 + tx * (zhitLayer1 - zhitLayer0);

      if (fabsf(xhitLayer1 - xextrapLayer1) < hitTol) {
        hitTol = fabsf(xhitLayer1 - xextrapLayer1);
        temp_best_hits[1] = i_hit1;
      }
    }

    // search for triplet/quadruplet in 4th layer
    hitTol = hit_tol_2;
    for (int i3 = 0; i3 < sum_layer_hits(ranges, layers[1]); ++i3) {

      int i_hit3 = calc_index(i3, ranges, layers[1], ut_hit_offsets);

      // Get info to check tolerance
      const float zhitLayer3 = ut_hits.zAtYEq0(i_hit3);
      const float yy3 = yyProto + (velo_state.ty * zhitLayer3);
      const float xhitLayer3 = ut_hits.xAt(i_hit3, yy3, ut_dxDy[layers[1]]);
      const float xextrapLayer3 = xhitLayer2 + tx * (zhitLayer3 - zhitLayer2);
      if (fabsf(xhitLayer3 - xextrapLayer3) < hitTol) {
        hitTol = fabsf(xhitLayer3 - xextrapLayer3);
        temp_best_hits[3] = i_hit3;
      }
    }

    // Fit the hits to get q/p, chi2
    const auto temp_number_of_hits = 2 + (temp_best_hits[1] != -1) + (temp_best_hits[3] != -1);
    const auto params =
      pkick_fit(temp_best_hits, ut_hits, velo_state, ut_dxDy, yyProto, forward, sigma_velo_slope, inv_sigma_velo_slope);

    // Save the best chi2 and number of hits triplet/quadruplet
    if (params.chi2UT < best_fit && temp_number_of_hits >= best_number_of_hits) {
      if (forward) {
        best_hits[0] = temp_best_hits[0];
        best_hits[1] = temp_best_hits[1];
        best_hits[2] = temp_best_hits[2];
        best_hits[3] = temp_best_hits[3];
      }
      else {
        best_hits[0] = temp_best_hits[3];
        best_hits[1] = temp_best_hits[2];
        best_hits[2] = temp_best_hits[1];
        best_hits[3] = temp_best_hits[0];
      }
      best_number_of_hits = temp_number_of_hits;
      best_params = params;
      best_fit = params.chi2UT;
    }
  }

  return std::tuple<int, int, int, int, BestParams> {
    best_hits[0], best_hits[1], best_hits[2], best_hits[3], best_params};
}

//=========================================================================
// Apply the p-kick method to the triplet/quadruplet
//=========================================================================
__device__ BestParams compass_ut::pkick_fit(
  const int best_hits[UT::Constants::n_layers],
  UT::ConstHits& ut_hits,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const float yyProto,
  const bool forward,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope)
{
  BestParams best_params;

  // Helper stuff from velo state
  const float xMidField = velo_state.x + velo_state.tx * (UT::Constants::zKink - velo_state.z);
  const float a = sigma_velo_slope * (UT::Constants::zKink - velo_state.z);
  const float wb = 1.0f / (a * a);

  float mat[3] = {wb, wb * UT::Constants::zDiff, wb * UT::Constants::zDiff * UT::Constants::zDiff};
  float rhs[2] = {wb * xMidField, wb * xMidField * UT::Constants::zDiff};

  // add hits
  float last_z = -10000.f;

  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = best_hits[i];
    if (hit_index >= 0) {
      const float wi = ut_hits.weight(hit_index);
      const int plane_code = forward ? i : UT::Constants::n_layers - 1 - i;
      const float dxDy = ut_dxDy[plane_code];
      const float ci = ut_hits.cosT(hit_index, dxDy);
      last_z = ut_hits.zAtYEq0(hit_index);
      const float dz = 0.001f * (last_z - UT::Constants::zMidUT);

      // x_pos_layer
      const float yy = yyProto + (velo_state.ty * last_z);
      const float ui = ut_hits.xAt(hit_index, yy, dxDy);

      mat[0] += wi * ci;
      mat[1] += wi * ci * dz;
      mat[2] += wi * ci * dz * dz;

      rhs[0] += wi * ui;
      rhs[1] += wi * ui * dz;
    }
  }

  const float denom = 1.0f / (mat[0] * mat[2] - mat[1] * mat[1]);
  const float xSlopeUTFit = 0.001f * (mat[0] * rhs[1] - mat[1] * rhs[0]) * denom;
  const float xUTFit = (mat[2] * rhs[0] - mat[1] * rhs[1]) * denom;

  // new VELO slope x
  const float xb = xUTFit + xSlopeUTFit * (UT::Constants::zKink - UT::Constants::zMidUT);
  const float invKinkVeloDist = 1.f / (UT::Constants::zKink - velo_state.z);
  const float xSlopeVeloFit = (xb - velo_state.x) * invKinkVeloDist;
  const float chi2VeloSlope = (velo_state.tx - xSlopeVeloFit) * inv_sigma_velo_slope;

  // chi2 takes chi2 from velo fit + chi2 from UT fit
  float chi2UT = chi2VeloSlope * chi2VeloSlope;
  // add chi2
  int total_num_hits = 0;

  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = best_hits[i];
    if (hit_index >= 0) {
      const float zd = ut_hits.zAtYEq0(hit_index);
      const float xd = xUTFit + xSlopeUTFit * (zd - UT::Constants::zMidUT);
      // x_pos_layer
      const int plane_code = forward ? i : UT::Constants::n_layers - 1 - i;
      const float dxDy = ut_dxDy[plane_code];
      const float yy = yyProto + (velo_state.ty * zd);
      const float x = ut_hits.xAt(hit_index, yy, dxDy);

      const float du = xd - x;
      chi2UT += (du * du) * ut_hits.weight(hit_index);

      // count the number of processed htis
      total_num_hits++;
    }
  }

  chi2UT /= (total_num_hits - 1);

  // Save the best parameters if chi2 is good
  if (chi2UT < UT::Constants::maxPseudoChi2) {
    // calculate q/p
    const float sinInX = xSlopeVeloFit * sqrtf(1.0f + xSlopeVeloFit * xSlopeVeloFit);
    const float sinOutX = xSlopeUTFit * sqrtf(1.0f + xSlopeUTFit * xSlopeUTFit);

    best_params.qp = sinInX - sinOutX;
    best_params.chi2UT = chi2UT;
    best_params.n_hits = total_num_hits;
    best_params.x = xUTFit;
    best_params.z = last_z;
    best_params.tx = xSlopeUTFit;
  }

  return best_params;
}

//=========================================================================
// Give total number of hits for N windows in 2 layers
//=========================================================================
__device__ int compass_ut::sum_layer_hits(const TrackCandidates& ranges, const int layer0, const int layer2)
{
  return sum_layer_hits(ranges, layer0) + sum_layer_hits(ranges, layer2);
}

//=========================================================================
// Give total number of hits for N windows in a layer
//=========================================================================
__device__ int compass_ut::sum_layer_hits(const TrackCandidates& ranges, const int layer)
{
  return ranges.get_size(layer, 0, threadIdx.x) + ranges.get_size(layer, 1, threadIdx.x) +
         ranges.get_size(layer, 2, threadIdx.x) + ranges.get_size(layer, 3, threadIdx.x) +
         ranges.get_size(layer, 4, threadIdx.x);
}

//=========================================================================
// Given a panel,
// return the index in the correct place depending on the iteration.
// Put the index first in the central window, then left, then right
//=========================================================================
__device__ int compass_ut::calc_index(
  const int index,
  const TrackCandidates& ranges,
  const int layer,
  const UT::HitOffsets& ut_hit_offsets)
{
  auto temp_index = index;
  for (uint i = 0; i < CompassUT::num_sectors; ++i) {
    const auto ranges_size = ranges.get_size(layer, i, threadIdx.x);
    if (temp_index < ranges_size) {
      return temp_index + ut_hit_offsets.layer_offset(layer) + ranges.get_from(layer, i, threadIdx.x);
    }
    temp_index -= ranges_size;
  }

  return -1;
}

//=========================================================================
// Given 2 panels (forward backward case),
// return the index in the correct place depending on the iteration.
// Put the index first in the central window, then left, then right
//=========================================================================
__device__ int compass_ut::calc_index(
  const int index,
  const TrackCandidates& ranges,
  const int layer0,
  const int layer2,
  const UT::HitOffsets& ut_hit_offsets)
{
  auto temp_index = index;
  for (uint i = 0; i < CompassUT::num_sectors; ++i) {
    const auto ranges_size = ranges.get_size(layer0, i, threadIdx.x);
    if (temp_index < ranges_size) {
      return temp_index + ut_hit_offsets.layer_offset(layer0) + ranges.get_from(layer0, i, threadIdx.x);
    }
    temp_index -= ranges_size;
  }

  return calc_index(temp_index, ranges, layer2, ut_hit_offsets);
}
