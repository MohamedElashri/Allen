/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFSearchInitialWindows.cuh"
#include "LFSearchInitialWindowsImpl.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

void lf_search_initial_windows::lf_search_initial_windows_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_lf_initial_windows_t>(
    arguments,
    LookingForward::number_of_elements_initial_window * first<host_number_of_reconstructed_ut_tracks_t>(arguments) *
      LookingForward::number_of_x_layers);
  set_size<dev_ut_states_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_scifi_lf_process_track_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
}

void lf_search_initial_windows::lf_search_initial_windows_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  initialize<dev_scifi_lf_initial_windows_t>(arguments, 0, stream);

  global_function(lf_search_initial_windows)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), stream)(
    arguments,
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_magnet_polarity.data());
}

__global__ void lf_search_initial_windows::lf_search_initial_windows(
  lf_search_initial_windows::Parameters parameters,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};
  const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   event_number,
                                                   number_of_events};

  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // SciFi hits
  const unsigned total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::ConstHits scifi_hits(parameters.dev_scifi_hits, total_number_of_hits);
  const auto event_offset = scifi_hit_count.event_offset();

  MiniState* ut_states = parameters.dev_ut_states + ut_event_tracks_offset;

  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const int velo_track_index = ut_tracks.velo_track(i);
    const int ut_track_index = ut_event_tracks_offset + i;
    const float ut_qop = ut_tracks.qop(i);

    // Note: These data should be accessed like
    //       the previous ut_tracks.qop[i] in the future
    const float ut_x = parameters.dev_ut_x[ut_track_index];
    const float ut_tx = parameters.dev_ut_tx[ut_track_index];
    const float ut_z = parameters.dev_ut_z[ut_track_index];

    const unsigned velo_states_index = velo_event_tracks_offset + velo_track_index;
    const MiniState velo_state = velo_states.get(velo_states_index);

    // extrapolate velo y & ty to z of UT x and tx
    // use ty from Velo state
    const MiniState ut_state {ut_x, LookingForward::y_at_z(velo_state, ut_z), ut_z, ut_tx, velo_state.ty};
    const MiniState state_at_z_last_ut_plane = LookingForward::state_at_z(ut_state, LookingForward::z_last_UT_plane);

    // Store state for access in other algorithms
    ut_states[i] = state_at_z_last_ut_plane;

    // Parameters for the calculation of the windows
    const float y_projection = LookingForward::y_at_z_dzdy_corrected(
      state_at_z_last_ut_plane, dev_looking_forward_constants->Zone_zPos_xlayers[0]);

    lf_search_initial_windows_impl(
      scifi_hits,
      scifi_hit_count,
      state_at_z_last_ut_plane,
      dev_looking_forward_constants,
      dev_magnet_polarity,
      ut_qop,
      y_projection >= 0.f,
      parameters.dev_scifi_lf_initial_windows + ut_event_tracks_offset + i,
      ut_tracks.total_number_of_tracks(),
      event_offset,
      parameters.dev_scifi_lf_process_track,
      ut_track_index);
  }
}

__device__ void lf_search_initial_windows_impl(
  SciFi::ConstHits& scifi_hits,
  SciFi::ConstHitCount& scifi_hit_count,
  const MiniState& UT_state,
  const LookingForward::Constants* looking_forward_constants,
  const float* magnet_polarity,
  const float qop,
  const bool side,
  int* initial_windows,
  const int number_of_tracks,
  const unsigned event_offset,
  bool* dev_process_track,
  const unsigned ut_track_index)
{
  int iZoneStartingPoint = side ? LookingForward::number_of_x_layers : 0;
  uint16_t sizes = 0;

  for (int i = 0; i < LookingForward::number_of_x_layers; i++) {
    const auto iZone = iZoneStartingPoint + i;

    const auto stateInZone = LookingForward::propagate_state_from_velo_multi_par(
      UT_state, qop, looking_forward_constants->x_layers[i], looking_forward_constants, magnet_polarity);
    const float xInZone = stateInZone.x;

    const float xTol =
      LookingForward::initial_window_offset_xtol + LookingForward::initial_window_factor_qop * fabsf(qop);
    float xMin, xMax;
    if (*magnet_polarity > 0.f) { // MU
      xMin = xInZone - xTol - LookingForward::initial_window_factor_assymmetric_opening * (signbit(qop) ^ 0x01);
      xMax = xInZone + xTol + LookingForward::initial_window_factor_assymmetric_opening * signbit(qop);
    }
    else { // MD
      xMin = xInZone - xTol - LookingForward::initial_window_factor_assymmetric_opening * signbit(qop);
      xMax = xInZone + xTol + LookingForward::initial_window_factor_assymmetric_opening * (signbit(qop) ^ 0x01);
    }

    // Get the hits within the bounds
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->xZones[iZone]);
    const int hits_within_bounds_start =
      binary_search_leftmost(scifi_hits.x0_p(x_zone_offset_begin), x_zone_size, xMin);
    const int hits_within_bounds_xInZone = binary_search_leftmost(
      scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start), x_zone_size - hits_within_bounds_start, xInZone);
    const int hits_within_bounds_size = binary_search_leftmost(
      scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start), x_zone_size - hits_within_bounds_start, xMax);

    // Cap the central windows to a certain size
    const int central_window_begin =
      max(hits_within_bounds_xInZone - LookingForward::max_number_of_hits_in_window / 2, 0);
    const int central_window_size =
      min(central_window_begin + LookingForward::max_number_of_hits_in_window, hits_within_bounds_size) -
      central_window_begin;

    // Initialize windows
    initial_windows[i * LookingForward::number_of_elements_initial_window * number_of_tracks] =
      hits_within_bounds_start + x_zone_offset_begin - event_offset + central_window_begin;
    initial_windows[(i * LookingForward::number_of_elements_initial_window + 1) * number_of_tracks] =
      central_window_size;

    sizes |= (hits_within_bounds_size > 0) << i;

    // Skip making range but continue if the size is zero
    if (hits_within_bounds_size > 0) {
      // Now match the stereo hits
      const float zZone = looking_forward_constants->Zone_zPos_xlayers[i];
      const float this_uv_z = looking_forward_constants->Zone_zPos_uvlayers[i];
      const float dz = this_uv_z - zZone;
      const float xInUv = LookingForward::linear_propagation(xInZone, stateInZone.tx, dz);
      const float UvCorr =
        LookingForward::y_at_z(stateInZone, this_uv_z) * looking_forward_constants->Zone_dxdy_uvlayers[i % 2];
      const float xInUvCorr = xInUv - UvCorr;
      const float xMinUV = xInUvCorr - LookingForward::initial_windows_max_offset_uv_window;
      const float xMaxUV = xInUvCorr + LookingForward::initial_windows_max_offset_uv_window;

      // Get bounds in UV layers
      // do one search on the same side as the x module
      const int uv_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->uvZones[iZone]);
      const int uv_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->uvZones[iZone]);
      const int hits_within_uv_bounds =
        binary_search_leftmost(scifi_hits.x0_p(uv_zone_offset_begin), uv_zone_size, xMinUV);
      const int hits_within_uv_bounds_size = binary_search_leftmost(
        scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds), uv_zone_size - hits_within_uv_bounds, xMaxUV);

      initial_windows[(i * LookingForward::number_of_elements_initial_window + 2) * number_of_tracks] =
        hits_within_uv_bounds + uv_zone_offset_begin - event_offset;
      initial_windows[(i * LookingForward::number_of_elements_initial_window + 3) * number_of_tracks] =
        hits_within_uv_bounds_size;

      sizes |= (hits_within_uv_bounds_size > 0) << (8 + i);
    }
  }

  // Process track if:
  // * It can have a triplet 0,2,4 or 1,3,5
  // * It can have at least one hit in UV layers
  //   (1 or 2) and (5 or 6) and (9 or 10)
  const bool do_process = (((sizes & LookingForward::bit_layer0) && (sizes & LookingForward::bit_layer4) &&
                            (sizes & LookingForward::bit_layer8)) ||
                           ((sizes & LookingForward::bit_layer3) && (sizes & LookingForward::bit_layer7) &&
                            (sizes & LookingForward::bit_layer11))) &&
                          ((sizes & LookingForward::bit_layer1) || (sizes & LookingForward::bit_layer2)) &&
                          ((sizes & LookingForward::bit_layer5) || (sizes & LookingForward::bit_layer6)) &&
                          ((sizes & LookingForward::bit_layer9) || (sizes & LookingForward::bit_layer10));

  dev_process_track[ut_track_index] = do_process;
}
