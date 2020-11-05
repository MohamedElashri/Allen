/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SearchWindows.cuh"
#include "SearchWindowsDeviceFunctions.cuh"
#include "BinarySearch.cuh"
#include <tuple>

void ut_search_windows::ut_search_windows_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_windows_layers_t>(
    arguments,
    CompassUT::num_elems * UT::Constants::n_layers * first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void ut_search_windows::ut_search_windows_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ut_windows_layers_t>(arguments, 0, context);

  global_function(ut_search_windows)(
    dim3(size<dev_event_list_t>(arguments)), dim3(UT::Constants::n_layers, property<block_dim_y_t>()), stream)(
    arguments,
    constants.dev_ut_magnet_tool,
    constants.dev_ut_dxDy.data(),
    constants.dev_unique_x_sector_layer_offsets.data(),
    constants.dev_unique_sector_xs.data());
}

__global__ void ut_search_windows::ut_search_windows(
  ut_search_windows::Parameters parameters,
  UTMagnetTool* dev_ut_magnet_tool,
  const float* dev_ut_dxDy,
  const unsigned* dev_unique_x_sector_layer_offsets, // prefixsum to point to the x hit of the sector, per layer
  const float* dev_unique_sector_xs)                 // list of xs that define the groups
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};

  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};

  const float* fudge_factors = &(dev_ut_magnet_tool->dxLayTable[0]);

  const auto ut_number_of_selected_tracks = parameters.dev_ut_number_of_selected_velo_tracks[event_number];
  const auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;

  for (unsigned layer = threadIdx.x; layer < UT::Constants::n_layers; layer += blockDim.x) {
    const unsigned layer_offset = ut_hit_offsets.layer_offset(layer);

    for (unsigned i = threadIdx.y; i < ut_number_of_selected_tracks; i += blockDim.y) {
      const auto current_velo_track = ut_selected_velo_tracks[i];

      const unsigned current_track_offset = event_tracks_offset + current_velo_track;
      const MiniState velo_state = velo_states.getMiniState(current_track_offset);

      const auto candidates = calculate_windows(
        layer,
        velo_state,
        fudge_factors,
        ut_hits,
        ut_hit_offsets,
        dev_ut_dxDy,
        dev_unique_sector_xs,
        dev_unique_x_sector_layer_offsets,
        parameters.y_tol,
        parameters.y_tol_slope,
        parameters.min_pt,
        parameters.min_momentum);

      // Write the windows in SoA style
      short* windows_layers =
        parameters.dev_ut_windows_layers + event_tracks_offset * CompassUT::num_elems * UT::Constants::n_layers;

      const int track_pos = UT::Constants::n_layers * number_of_tracks_event;
      const int layer_pos = layer * number_of_tracks_event + current_velo_track;

      windows_layers[0 * track_pos + layer_pos] = std::get<0>(candidates) - layer_offset; // first_candidate
      windows_layers[1 * track_pos + layer_pos] = std::get<2>(candidates) - layer_offset; // left_group_first
      windows_layers[2 * track_pos + layer_pos] = std::get<4>(candidates) - layer_offset; // right_group_first
      windows_layers[3 * track_pos + layer_pos] = std::get<6>(candidates) - layer_offset; // left2_group_first
      windows_layers[4 * track_pos + layer_pos] = std::get<8>(candidates) - layer_offset; // right2_group_first
      windows_layers[5 * track_pos + layer_pos] = std::get<1>(candidates);                // last_size
      windows_layers[6 * track_pos + layer_pos] = std::get<3>(candidates);                // left_size_last
      windows_layers[7 * track_pos + layer_pos] = std::get<5>(candidates);                // right_size_first
      windows_layers[8 * track_pos + layer_pos] = std::get<7>(candidates);                // left2_size_last
      windows_layers[9 * track_pos + layer_pos] = std::get<9>(candidates);                // right2_size_first
    }
  }
}

//=========================================================================
// Check if hit is inside tolerance and refine by Y
//=========================================================================
__device__ void tol_refine(
  int& first_candidate,
  int& number_of_candidates,
  UT::ConstHits& ut_hits,
  const MiniState& velo_state,
  const float invNormfact,
  const float xTolNormFact,
  const float dxDy,
  const float y_tol,
  const float y_tol_slope)
{
  bool first_found = false;
  const auto const_first_candidate = first_candidate;
  int last_candidate = first_candidate;
  for (int candidate_i = 0; candidate_i < number_of_candidates; ++candidate_i) {
    const auto i = const_first_candidate + candidate_i;

    const auto zInit = ut_hits.zAtYEq0(i);
    const auto yApprox = velo_state.y + velo_state.ty * (zInit - velo_state.z);
    const auto xOnTrackProto = velo_state.x + velo_state.tx * (zInit - velo_state.z);
    const auto xx = ut_hits.xAt(i, yApprox, dxDy);
    const auto dx = xx - xOnTrackProto;

    if (
      dx >= -xTolNormFact && dx <= xTolNormFact &&
      !ut_hits.isNotYCompatible(i, yApprox, y_tol + y_tol_slope * fabsf(dx * invNormfact))) {
      // It is compatible
      if (!first_found) {
        first_found = true;
        first_candidate = i;
      }
      last_candidate = i;
    }
  }

  if (!first_found) {
    first_candidate = 0;
    number_of_candidates = 0;
  }
  else {
    number_of_candidates = last_candidate - first_candidate + 1;
  }
}

//=============================================================================
// Get the windows
//=============================================================================
__device__ std::tuple<int, int, int, int, int, int, int, int, int, int> calculate_windows(
  const int layer,
  const MiniState& velo_state,
  const float* fudge_factors,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const float* ut_dxDy,
  const float* dev_unique_sector_xs,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const float y_tol,
  const float y_tol_slope,
  const float min_pt,
  const float min_momentum)
{
  // -- This is hardcoded, so faster
  // -- If you ever change the Table in the magnet tool, this will be wrong
  const float absSlopeY = fabsf(velo_state.ty);
  const int index = (int) (absSlopeY * 100 + 0.5f);
  assert(3 + 4 * index < UTMagnetTool::N_dxLay_vals);
  const float normFact[4] {
    fudge_factors[4 * index], fudge_factors[1 + 4 * index], fudge_factors[2 + 4 * index], fudge_factors[3 + 4 * index]};

  // -- this 500 seems a little odd...
  // to do: change back!
  const float invTheta = min(500.0f, 1.0f / sqrtf(velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty));
  const float minMom = max(min_pt * invTheta, min_momentum);
  const float xTol = fabsf(1.0f / (UT::Constants::distToMomentum * minMom));
  // const float yTol     = UT::Constants::yTol + UT::Constants::yTolSlope * xTol;

  int layer_offset = ut_hit_offsets.layer_offset(layer);

  const float dx_dy = ut_dxDy[layer];
  const float z_at_layer = ut_hits.zAtYEq0(layer_offset);
  const float y_track = velo_state.y + velo_state.ty * (z_at_layer - velo_state.z);
  const float x_track = velo_state.x + velo_state.tx * (z_at_layer - velo_state.z);
  const float invNormFact = 1.0f / normFact[layer];
  const float xTolNormFact = xTol * invNormFact;

  // Second sector group search
  // const float tolerance_in_x = xTol * invNormFact;

  // Find sector group for lowerBoundX and upperBoundX
  const int first_sector_group_in_layer = dev_unique_x_sector_layer_offsets[layer];
  const int last_sector_group_in_layer = dev_unique_x_sector_layer_offsets[layer + 1];
  const int sector_group_size = last_sector_group_in_layer - first_sector_group_in_layer;

  const int local_sector_group =
    binary_search_leftmost(dev_unique_sector_xs + first_sector_group_in_layer, sector_group_size, x_track);
  int sector_group = first_sector_group_in_layer + local_sector_group;

  int first_candidate = 0, number_of_candidates = 0;
  int left_group_first_candidate = 0, left_group_number_of_candidates = 0;
  int left2_group_first_candidate = 0, left2_group_number_of_candidates = 0;
  int right_group_first_candidate = 0, right_group_number_of_candidates = 0;
  int right2_group_first_candidate = 0, right2_group_number_of_candidates = 0;

  // Get correct index position in array
  sector_group -= 1;
  // central sector group
  if ((sector_group + 1) < last_sector_group_in_layer && sector_group > first_sector_group_in_layer) {
    const auto sector_candidates = find_candidates_in_sector_group(
      ut_hits,
      ut_hit_offsets,
      velo_state,
      dev_unique_sector_xs,
      x_track,
      y_track,
      dx_dy,
      invNormFact,
      xTolNormFact,
      sector_group,
      y_tol,
      y_tol_slope);

    first_candidate = std::get<0>(sector_candidates);
    number_of_candidates = std::get<1>(sector_candidates);
  }

  // left sector group
  const int left_group = sector_group - 1;
  if ((left_group + 1) < last_sector_group_in_layer && left_group > first_sector_group_in_layer) {
    // Valid sector group to find compatible hits
    const auto left_group_candidates = find_candidates_in_sector_group(
      ut_hits,
      ut_hit_offsets,
      velo_state,
      dev_unique_sector_xs,
      x_track,
      y_track,
      dx_dy,
      invNormFact,
      xTolNormFact,
      left_group,
      y_tol,
      y_tol_slope);

    left_group_first_candidate = std::get<0>(left_group_candidates);
    left_group_number_of_candidates = std::get<1>(left_group_candidates);
  }

  // left-left sector group
  const int left2_group = sector_group - 2;
  if ((left2_group + 1) < last_sector_group_in_layer && left2_group > first_sector_group_in_layer) {
    // Valid sector group to find compatible hits
    const auto left2_group_candidates = find_candidates_in_sector_group(
      ut_hits,
      ut_hit_offsets,
      velo_state,
      dev_unique_sector_xs,
      x_track,
      y_track,
      dx_dy,
      invNormFact,
      xTolNormFact,
      left2_group,
      y_tol,
      y_tol_slope);

    left2_group_first_candidate = std::get<0>(left2_group_candidates);
    left2_group_number_of_candidates = std::get<1>(left2_group_candidates);
  }

  // right sector group
  const int right_group = sector_group + 1;
  if ((right_group + 1) < last_sector_group_in_layer && right_group > first_sector_group_in_layer) {
    // Valid sector group to find compatible hits
    const auto right_group_candidates = find_candidates_in_sector_group(
      ut_hits,
      ut_hit_offsets,
      velo_state,
      dev_unique_sector_xs,
      x_track,
      y_track,
      dx_dy,
      invNormFact,
      xTolNormFact,
      right_group,
      y_tol,
      y_tol_slope);

    right_group_first_candidate = std::get<0>(right_group_candidates);
    right_group_number_of_candidates = std::get<1>(right_group_candidates);
  }

  // right-right sector group
  const int right2_group = sector_group + 2;
  if ((right2_group + 1) < last_sector_group_in_layer && right2_group > first_sector_group_in_layer) {
    // Valid sector group to find compatible hits
    const auto right2_group_candidates = find_candidates_in_sector_group(
      ut_hits,
      ut_hit_offsets,
      velo_state,
      dev_unique_sector_xs,
      x_track,
      y_track,
      dx_dy,
      invNormFact,
      xTolNormFact,
      right2_group,
      y_tol,
      y_tol_slope);

    right2_group_first_candidate = std::get<0>(right2_group_candidates);
    right2_group_number_of_candidates = std::get<1>(right2_group_candidates);
  }

  return std::tuple<int, int, int, int, int, int, int, int, int, int> {first_candidate,
                                                                       number_of_candidates,
                                                                       left_group_first_candidate,
                                                                       left_group_number_of_candidates,
                                                                       right_group_first_candidate,
                                                                       right_group_number_of_candidates,
                                                                       left2_group_first_candidate,
                                                                       left2_group_number_of_candidates,
                                                                       right2_group_first_candidate,
                                                                       right2_group_number_of_candidates};
}

__device__ std::tuple<int, int> find_candidates_in_sector_group(
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const MiniState& velo_state,
  const float* dev_unique_sector_xs,
  const float x_track,
  const float y_track,
  const float dx_dy,
  const float invNormFact,
  const float xTolNormFact,
  const int sector_group,
  const float y_tol,
  const float y_tol_slope)
{
  const float x_at_left_sector = dev_unique_sector_xs[sector_group];
  const float x_at_right_sector = dev_unique_sector_xs[sector_group + 1];
  const float xx_at_left_sector = x_at_left_sector + y_track * dx_dy;
  const float xx_at_right_sector = x_at_right_sector + y_track * dx_dy;
  const float dx_max = max(xx_at_left_sector - x_track, xx_at_right_sector - x_track);

  const float tol = y_tol + y_tol_slope * fabsf(dx_max * invNormFact);
  const unsigned sector_group_offset = ut_hit_offsets.sector_group_offset(sector_group);

  int number_of_candidates = 0;

  // Find the first candidate (y_track - tol) employing a normal binary search
  int first_candidate = binary_search_leftmost(
    ut_hits.yEnd_p(sector_group_offset), ut_hit_offsets.sector_group_number_of_hits(sector_group), y_track - tol);

  // In case we found a first candidate
  if (first_candidate < static_cast<int>(ut_hit_offsets.sector_group_number_of_hits(sector_group))) {
    // Find the last candidate (y_track + tol)
    number_of_candidates = binary_search_leftmost(
      ut_hits.yBegin_p(sector_group_offset + first_candidate),
      ut_hit_offsets.sector_group_number_of_hits(sector_group) - first_candidate,
      y_track + tol);

    first_candidate += sector_group_offset;

    // If there is no last candidate, we are done
    if (number_of_candidates > 0) {
      // Refine the found candidate to fulfill some specific criteria
      tol_refine(
        first_candidate,
        number_of_candidates,
        ut_hits,
        velo_state,
        invNormFact,
        xTolNormFact,
        dx_dy,
        y_tol,
        y_tol_slope);
    }
  }

  return std::tuple<int, int> {first_candidate, number_of_candidates};
}
