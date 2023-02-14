/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFSearchInitialWindows.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

INSTANTIATE_ALGORITHM(lf_search_initial_windows::lf_search_initial_windows_t)

void lf_search_initial_windows::lf_search_initial_windows_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const bool with_ut = first<host_track_type_id_t>(arguments) == Allen::TypeIDs::VeloUTTracks;
  set_size<dev_scifi_lf_initial_windows_t>(
    arguments,
    (with_ut ? LookingForward::InputUT::number_of_elements_initial_window :
               LookingForward::InputVelo::number_of_elements_initial_window) *
      first<host_number_of_reconstructed_input_tracks_t>(arguments) * LookingForward::number_of_x_layers);
  set_size<dev_input_states_t>(arguments, first<host_number_of_reconstructed_input_tracks_t>(arguments));
  set_size<dev_scifi_lf_number_of_tracks_t>(arguments, 2 * first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_lf_tracks_indices_t>(arguments, 2 * first<host_number_of_reconstructed_input_tracks_t>(arguments));
}

void lf_search_initial_windows::lf_search_initial_windows_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_lf_initial_windows_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_lf_number_of_tracks_t>(arguments, 0, context);

  global_function(lf_search_initial_windows)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_magnet_polarity.data());
}

template<bool with_ut, typename T>
__device__ void search_windows(
  const lf_search_initial_windows::Parameters& parameters,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity,
  const T* tracks)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const int number_of_elements_initial_window = with_ut ? LookingForward::InputUT::number_of_elements_initial_window :
                                                          LookingForward::InputVelo::number_of_elements_initial_window;

  const auto velo_states_view = parameters.dev_velo_states_view[event_number];
  const auto input_tracks_view = tracks->container(event_number);

  const unsigned event_number_of_tracks = input_tracks_view.size();
  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();
  // SciFi hits
  const unsigned total_number_of_hits =
    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_offsets, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::ConstHits scifi_hits(parameters.dev_scifi_hits, total_number_of_hits);
  const auto event_offset = scifi_hit_count.event_offset();

  MiniState* input_states = parameters.dev_input_states + event_tracks_offset;

  // if input velo track filter it based on UT acceptance and !backward
  const auto get_number_of_tracks = [&]() {
    if constexpr (with_ut) {
      return event_number_of_tracks;
    }
    else {
      return parameters.dev_ut_number_of_selected_velo_tracks[event_number];
    }
  };

  const auto get_track_index = [&](const unsigned i) {
    if constexpr (with_ut) {
      return i;
    }
    else {
      return parameters.dev_ut_selected_velo_tracks[event_tracks_offset + i];
    }
  };

  for (unsigned i_selected_tracks = threadIdx.x; i_selected_tracks < get_number_of_tracks();
       i_selected_tracks += blockDim.x) {
    // index for the input track (for velo input only accepted tracks)
    const int track_index = get_track_index(i_selected_tracks);
    const auto input_track = input_tracks_view.track(track_index);

    const auto qop = [&]() {
      if constexpr (with_ut) {
        return input_track.qop();
      }
      else {
        const auto velo_state = input_track.state(velo_states_view);
        const float input_tx = velo_state.tx;
        const float input_ty = velo_state.ty;
        // if I assume pt = 1 GeV , then I can calculate p from tx and ty of the Velo input track
        const float momentum_from_pt =
          parameters.input_pt / cosf(atanf(1 / sqrtf(input_tx * input_tx + input_ty * input_ty)));
        // here I pick the tighter cut (higher momentum) between the two
        const float input_qop_value = fabsf(1 / parameters.input_momentum) > fabsf(1 / momentum_from_pt) ?
                                        1 / momentum_from_pt :
                                        1 / parameters.input_momentum;
        return input_qop_value;
      }
    }();

    const auto input_state = [&]() {
      if constexpr (with_ut) {
        // Get x, tx, z from UT state, ty from Velo state
        const float input_x = input_track.x();
        const float input_tx = input_track.tx();
        const float input_z = input_track.z();
        const auto velo_track = input_track.velo_track();
        const auto velo_state = velo_track.state(velo_states_view);
        const float input_ty = velo_state.ty;
        const MiniState start_input_state {
          input_x, LookingForward::y_at_z(velo_state, input_z), input_z, input_tx, input_ty};
        return LookingForward::state_at_z(start_input_state, LookingForward::z_last_UT_plane);
      }
      else {
        // Get everything from the velo state
        const auto velo_state = input_track.state(velo_states_view);
        const float input_x = velo_state.x;
        const float input_tx = velo_state.tx;
        const float input_z = velo_state.z;
        const float input_ty = velo_state.ty;
        const MiniState start_input_state {
          input_x, LookingForward::y_at_z(velo_state, input_z), input_z, input_tx, input_ty};
        return LookingForward::state_at_z(start_input_state, LookingForward::z_last_UT_plane);
      }
    }();

    // Store state for access in other algorithms
    input_states[track_index] = input_state;

    // Parameters for the calculation of the windows
    const float y_projection =
      LookingForward::y_at_z_dzdy_corrected(input_state, dev_looking_forward_constants->Zone_zPos_xlayers[0]);

    const bool side = y_projection >= 0.f;
    int* initial_windows = parameters.dev_scifi_lf_initial_windows + event_tracks_offset + track_index;

    int iZoneStartingPoint = side ? LookingForward::number_of_x_layers : 0;
    uint16_t sizes = 0;

    if constexpr (with_ut) {
      for (int i = 0; i < LookingForward::number_of_x_layers; i++) {
        const auto iZone = iZoneStartingPoint + i;

        const auto stateInZone = LookingForward::propagate_state_from_velo_multi_par(
          input_state,
          qop,
          dev_looking_forward_constants->x_layers[i],
          dev_looking_forward_constants,
          dev_magnet_polarity);
        const float xInZone = stateInZone.x;

        const float xTol =
          LookingForward::initial_window_offset_xtol + LookingForward::initial_window_factor_qop * fabsf(qop);
        float xMin, xMax;
        if (*dev_magnet_polarity > 0.f) { // MU
          xMin = xInZone - xTol - LookingForward::initial_window_factor_assymmetric_opening * (signbit(qop) ^ 0x01);
          xMax = xInZone + xTol + LookingForward::initial_window_factor_assymmetric_opening * signbit(qop);
        }
        else { // MD
          xMin = xInZone - xTol - LookingForward::initial_window_factor_assymmetric_opening * signbit(qop);
          xMax = xInZone + xTol + LookingForward::initial_window_factor_assymmetric_opening * (signbit(qop) ^ 0x01);
        }

        // Get the hits within the bounds
        const int x_zone_offset_begin = scifi_hit_count.zone_offset(dev_looking_forward_constants->xZones[iZone]);
        const int x_zone_size = scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->xZones[iZone]);
        const int hits_within_bounds_start =
          binary_search_leftmost(scifi_hits.x0_p(x_zone_offset_begin), x_zone_size, xMin);
        const int hits_within_bounds_xInZone = binary_search_leftmost(
          scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start),
          x_zone_size - hits_within_bounds_start,
          xInZone);
        const int hits_within_bounds_size = binary_search_leftmost(
          scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start),
          x_zone_size - hits_within_bounds_start,
          xMax);

        // Cap the central windows to a certain size
        const int central_window_begin =
          max(hits_within_bounds_xInZone - static_cast<int>(parameters.hit_window_size) / 2, 0);
        const int central_window_size =
          min(central_window_begin + static_cast<int>(parameters.hit_window_size), hits_within_bounds_size) -
          central_window_begin;

        // Initialize windows
        initial_windows[i * number_of_elements_initial_window * total_number_of_tracks] =
          hits_within_bounds_start + x_zone_offset_begin - event_offset + central_window_begin;
        initial_windows[(i * number_of_elements_initial_window + 1) * total_number_of_tracks] = central_window_size;

        sizes |= (hits_within_bounds_size > 0) << i;

        // Skip making range but continue if the size is zero
        if (hits_within_bounds_size > 0) {
          // Now match the stereo hits
          const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[i];
          const float this_uv_z = dev_looking_forward_constants->Zone_zPos_uvlayers[i];
          const float dz = this_uv_z - zZone;
          const float xInUv = LookingForward::linear_propagation(xInZone, stateInZone.tx, dz);
          const float UvCorr =
            LookingForward::y_at_z(stateInZone, this_uv_z) * dev_looking_forward_constants->Zone_dxdy_uvlayers[i % 2];
          const float xInUvCorr = xInUv - UvCorr;
          const float xMinUV = xInUvCorr - parameters.initial_windows_max_offset_uv_window;
          const float xMaxUV = xInUvCorr + parameters.initial_windows_max_offset_uv_window;
          // Get bounds in UV layers
          // do one search on the same side as the x module
          const int uv_zone_offset_begin = scifi_hit_count.zone_offset(dev_looking_forward_constants->uvZones[iZone]);
          const int uv_zone_size = scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->uvZones[iZone]);
          const int hits_within_uv_bounds =
            binary_search_leftmost(scifi_hits.x0_p(uv_zone_offset_begin), uv_zone_size, xMinUV);
          const int hits_within_uv_bounds_size = binary_search_leftmost(
            scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds),
            uv_zone_size - hits_within_uv_bounds,
            xMaxUV);

          initial_windows[(i * number_of_elements_initial_window + 2) * total_number_of_tracks] =
            hits_within_uv_bounds + uv_zone_offset_begin - event_offset;
          initial_windows[(i * number_of_elements_initial_window + 3) * total_number_of_tracks] =
            hits_within_uv_bounds_size;

          sizes |= (hits_within_uv_bounds_size > 0) << (8 + i);
        }
      }
    } // if with ut
    else {
      for (int i = 0; i < LookingForward::number_of_x_layers; i++) {
        const auto iZone = iZoneStartingPoint + i;
        // simple straight line propagation
        const MiniState stateInZone =
          LookingForward::state_at_z(input_state, dev_looking_forward_constants->Zone_zPos_xlayers[i]);
        const float xInZone = stateInZone.x;

        // this is a term occurring in the polynomial from which the x prediction is deduced
        const auto term1 = dev_looking_forward_constants->toSciFiExtParams[0] +
                           input_state.tx * (-dev_looking_forward_constants->toSciFiExtParams[1] +
                                             dev_looking_forward_constants->toSciFiExtParams[2] * input_state.tx) +
                           input_state.ty * input_state.ty *
                             (dev_looking_forward_constants->toSciFiExtParams[3] +
                              input_state.tx * (dev_looking_forward_constants->toSciFiExtParams[4] +
                                                dev_looking_forward_constants->toSciFiExtParams[5] * input_state.tx));

        //*1000 to make in GeV
        const auto minInvPGeV = fabsf(qop) * 1000.f;
        const auto minPBorder =
          minInvPGeV * (term1 + minInvPGeV * (dev_looking_forward_constants->toSciFiExtParams[6] * input_state.tx +
                                              dev_looking_forward_constants->toSciFiExtParams[7] * minInvPGeV));

        // window shutters for case without momentum estimate, i.e. velo tracks as input
        float dxMin = -minPBorder * parameters.x_windows_factor;
        float dxMax = minPBorder * parameters.x_windows_factor;
        float xMin, xMax;

        xMin = xInZone + dxMin;
        xMax = xInZone + dxMax;

        // Get the hits within the bounds
        const int x_zone_offset_begin = scifi_hit_count.zone_offset(dev_looking_forward_constants->xZones[iZone]);
        const int x_zone_size = scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->xZones[iZone]);

        const int hits_within_bounds_start =
          binary_search_leftmost(scifi_hits.x0_p(x_zone_offset_begin), x_zone_size, xMin);

        const int hits_within_bounds_size = binary_search_leftmost(
          scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start),
          x_zone_size - hits_within_bounds_start,
          xMax);

        const int hits_within_bounds_xInZone_left = binary_search_leftmost(
          scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start),
          x_zone_size - hits_within_bounds_start,
          xInZone - parameters.overlap_in_mm);
        const int hits_within_bounds_xInZone_right = binary_search_leftmost(
          scifi_hits.x0_p(x_zone_offset_begin + hits_within_bounds_start),
          x_zone_size - hits_within_bounds_start,
          xInZone + parameters.overlap_in_mm);

        // Cap the central windows to a certain size
        // the beginning of the left window is center + overlap - parameters.hit_window_size
        const int central_window_begin_left =
          max(hits_within_bounds_xInZone_right - static_cast<int>(parameters.hit_window_size), 0);
        // the beginning of the right window is center - overlap
        const int central_window_begin_right = max(hits_within_bounds_xInZone_left, 0);

        const int central_window_size_left =
          min(static_cast<int>(parameters.hit_window_size), hits_within_bounds_xInZone_right);
        const int central_window_size_right =
          min(static_cast<int>(parameters.hit_window_size), hits_within_bounds_size - hits_within_bounds_xInZone_left);

        // Initialize windows
        // left
        initial_windows[(i * number_of_elements_initial_window + 0) * total_number_of_tracks] =
          hits_within_bounds_start + x_zone_offset_begin - event_offset + central_window_begin_left;
        initial_windows[(i * number_of_elements_initial_window + 1) * total_number_of_tracks] =
          central_window_size_left;

        // right
        initial_windows[(i * number_of_elements_initial_window + 2) * total_number_of_tracks] =
          hits_within_bounds_start + x_zone_offset_begin - event_offset + central_window_begin_right;
        initial_windows[(i * number_of_elements_initial_window + 3) * total_number_of_tracks] =
          central_window_size_right;

        // printf("(Search Windows) Initial window right %i, %i: ", track_index, track_index + (i *
        // number_of_elements_initial_window + 2) * total_number_of_tracks); for (unsigned ii = 0; ii <
        // central_window_size_right; ++ii) {
        //   printf("%f, ", scifi_hits.x0(hits_within_bounds_start + x_zone_offset_begin + central_window_begin_right +
        //   ii));
        // }
        // printf("\n");

        sizes |= (hits_within_bounds_size > 0) << i;

        // Skip making range but continue if the size is zero
        if (hits_within_bounds_size > 0) {
          // Now match the stereo hits
          const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[i];
          const float this_uv_z = dev_looking_forward_constants->Zone_zPos_uvlayers[i];
          const float dz = this_uv_z - zZone;
          const float xInUv = LookingForward::linear_propagation(xInZone, stateInZone.tx, dz);
          const float UvCorr =
            LookingForward::y_at_z(stateInZone, this_uv_z) * dev_looking_forward_constants->Zone_dxdy_uvlayers[i % 2];
          const float xInUvCorr = xInUv - UvCorr;
          const float xMinUV = xInUvCorr - parameters.initial_windows_max_offset_uv_window;
          const float xMaxUV = xInUvCorr + parameters.initial_windows_max_offset_uv_window;

          // Get bounds in UV layers
          // do one search on the same side as the x module
          const int uv_zone_offset_begin = scifi_hit_count.zone_offset(dev_looking_forward_constants->uvZones[iZone]);
          const int uv_zone_size = scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->uvZones[iZone]);
          const int hits_within_uv_bounds =
            binary_search_leftmost(scifi_hits.x0_p(uv_zone_offset_begin), uv_zone_size, xMinUV);
          const int hits_within_uv_bounds_size = binary_search_leftmost(
            scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds),
            uv_zone_size - hits_within_uv_bounds,
            xMaxUV);

          const int hits_within_bounds_xInUV_left = binary_search_leftmost(
            scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds),
            uv_zone_size - hits_within_uv_bounds,
            xInUvCorr - parameters.overlap_in_mm);
          const int hits_within_bounds_xInUV_right = binary_search_leftmost(
            scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds),
            uv_zone_size - hits_within_uv_bounds,
            xInUvCorr + parameters.overlap_in_mm);

          // Cap the central windows to a certain size
          // the beginning of the left window is center + overlap - parameters.hit_window_size
          const int central_uv_window_begin_left =
            max(hits_within_bounds_xInUV_right - static_cast<int>(parameters.hit_window_size), 0);
          // the beginning of the right window is center - overlap
          const int central_uv_window_begin_right = max(hits_within_bounds_xInUV_left, 0);

          const int central_uv_window_size_left =
            min(static_cast<int>(parameters.hit_window_size), hits_within_bounds_xInUV_right);
          const int central_uv_window_size_right = min(
            static_cast<int>(parameters.hit_window_size), hits_within_uv_bounds_size - hits_within_bounds_xInUV_left);

          initial_windows[(i * number_of_elements_initial_window + 4) * total_number_of_tracks] =
            hits_within_uv_bounds + uv_zone_offset_begin - event_offset + central_uv_window_begin_left;
          initial_windows[(i * number_of_elements_initial_window + 5) * total_number_of_tracks] =
            central_uv_window_size_left;
          initial_windows[(i * number_of_elements_initial_window + 6) * total_number_of_tracks] =
            hits_within_uv_bounds + uv_zone_offset_begin - event_offset + central_uv_window_begin_right;
          initial_windows[(i * number_of_elements_initial_window + 7) * total_number_of_tracks] =
            central_uv_window_size_right;

          sizes |= (hits_within_uv_bounds_size > 0) << (8 + i);
        }
      }
    } // velo input track

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

    if (do_process) {
      const auto track_number =
        atomicAdd(parameters.dev_scifi_lf_number_of_tracks + side * number_of_events + event_number, 1);
      parameters.dev_scifi_lf_tracks_indices[total_number_of_tracks * side + event_tracks_offset + track_number] =
        track_index;
    }
  } // end of loop over input tracks
}

__global__ void lf_search_initial_windows::lf_search_initial_windows(
  lf_search_initial_windows::Parameters parameters,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    search_windows<true>(parameters, dev_scifi_geometry, dev_looking_forward_constants, dev_magnet_polarity, ut_tracks);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    search_windows<false>(
      parameters, dev_scifi_geometry, dev_looking_forward_constants, dev_magnet_polarity, velo_tracks);
  }
}
