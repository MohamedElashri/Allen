#include "CompassUT.cuh"
#include "BinarySearch.cuh"
#include "CalculateWindows.cuh"
#include "UTFastFitter.cuh"

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
      parameters.sigma_velo_slope,
      parameters.inv_sigma_velo_slope);
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
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope)
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
    inv_sigma_velo_slope,
    event_hit_offset);

  const int best_hits[UT::Constants::n_layers] = {std::get<0>(best_hits_and_params),
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
__device__ __inline__ void compass_ut::fill_shared_windows(
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
__host__ __device__ __inline__ int master_index(const int index1, const int index2, const int index3)
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
  const float bdls[num_idx] = {bdl_table[master_index(index1 + 1, index2, index3)],
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

  float finalParams[4] = {best_params.x,
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

  // to do: maybe save y from fit
  UT::TrackHits track;
  track.velo_track_index = i_track;
  track.qop = qop;
  track.x = best_params.x;
  track.z = best_params.z;
  track.tx = best_params.tx;
  track.hits_num = 0;

  // Adding hits to track
  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    if (best_hits[i] != -1) {
      track.hits[i] = best_hits[i] - event_hit_offset;
      ++track.hits_num;
    }
    else {
      track.hits[i] = -1;
    }
  }

  assert(n_tracks < UT::Constants::max_num_tracks);
  VeloUT_tracks[n_tracks] = track;
}
