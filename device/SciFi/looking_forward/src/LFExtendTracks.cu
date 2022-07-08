/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFCreateTracks.cuh"
#include "BinarySearch.cuh"

template<bool with_ut, typename T>
__device__ void extend_tracks(
  lf_create_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const T* tracks)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned number_of_elements_initial_window = with_ut ?
                                                       LookingForward::InputUT::number_of_elements_initial_window :
                                                       LookingForward::InputVelo::number_of_elements_initial_window;

  const unsigned uv_hits_chi2_factor = parameters.uv_hits_chi2_factor;
  const unsigned max_triplets_per_input_track = parameters.max_triplets_per_input_track;
  const float chi2_max_extrapolation_to_x_layers_single = parameters.chi2_max_extrapolation_to_x_layers_single;

  const auto input_tracks_view = tracks->container(event_number);

  const int event_tracks_offset = input_tracks_view.offset();

  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  // SciFi hits
  const unsigned total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = parameters.dev_scifi_lf_atomics[event_number];

  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index = event_tracks_offset * max_triplets_per_input_track + i;
    SciFi::TrackHits& track = parameters.dev_scifi_lf_tracks[scifi_track_index];
    const auto current_input_track_index = event_tracks_offset + track.input_track_index;
    const auto input_state = parameters.dev_input_states[current_input_track_index];
    const auto left_right_side = track.charge_seed;

    // Load track parametrization
    const auto a1 = parameters.dev_scifi_lf_parametrization[scifi_track_index];
    const auto b1 =
      parameters
        .dev_scifi_lf_parametrization[total_number_of_tracks * max_triplets_per_input_track + scifi_track_index];
    const auto c1 =
      parameters
        .dev_scifi_lf_parametrization[2 * total_number_of_tracks * max_triplets_per_input_track + scifi_track_index];
    const auto d_ratio =
      parameters
        .dev_scifi_lf_parametrization[3 * total_number_of_tracks * max_triplets_per_input_track + scifi_track_index];

    // Note: This logic assumes the candidate layers have hits in {T0, T1, T2}
    for (auto current_layer : {1 - track.get_layer(0), 5 - track.get_layer(1), 9 - track.get_layer(2)}) {

      // Note: This logic assumes the candidate layers are {0, 2, 4} and {1, 3, 5}
      // for (auto current_layer : {1 - track.get_layer(0), 3 - track.get_layer(0), 5 - track.get_layer(0)}) {
      // Find window
      const auto window_start =
        parameters.dev_scifi_lf_initial_windows
          [current_input_track_index +
           (current_layer * number_of_elements_initial_window + left_right_side * 2) * total_number_of_tracks];
      const auto window_size =
        parameters.dev_scifi_lf_initial_windows
          [current_input_track_index +
           (current_layer * number_of_elements_initial_window + 1 + left_right_side * 2) * total_number_of_tracks];
      const float z = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

      const auto dz = z - LookingForward::z_mid_t;
      const auto predicted_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);

      // Pick the best, according to chi2
      int best_index = -1;
      float best_chi2 = chi2_max_extrapolation_to_x_layers_single;

      const auto scifi_hits_x0 = scifi_hits.x0_p(event_offset + window_start);

      // Binary search of candidate
      const auto candidate_index = binary_search_leftmost(scifi_hits_x0, window_size, predicted_x);

      // It is now either candidate_index - 1 or candidate_index
      for (int h4_rel = candidate_index - 1; h4_rel < candidate_index + 1; ++h4_rel) {
        if (h4_rel >= 0 && h4_rel < window_size) {
          const auto x4 = scifi_hits_x0[h4_rel];
          const auto chi2 = (x4 - predicted_x) * (x4 - predicted_x);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_index = h4_rel;
          }
        }
      }

      if (best_index != -1) {
        track.add_hit_with_quality((uint16_t)(window_start + best_index), best_chi2);
      }
    }

    // Normalize track quality
    track.quality *= (1.f / chi2_max_extrapolation_to_x_layers_single);

    // Add UV hits
    for (int relative_uv_layer = 0; relative_uv_layer < 6; relative_uv_layer++) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];

      // Use UV windows
      const auto uv_window_start =
        parameters.dev_scifi_lf_initial_windows
          [current_input_track_index + (relative_uv_layer * number_of_elements_initial_window +
                                        int(number_of_elements_initial_window / 2) + left_right_side * 2) *
                                         total_number_of_tracks];
      const auto uv_window_size =
        parameters.dev_scifi_lf_initial_windows
          [current_input_track_index + (relative_uv_layer * number_of_elements_initial_window +
                                        int(number_of_elements_initial_window / 2) + 1 + left_right_side * 2) *
                                         total_number_of_tracks];

      // Calculate expected X true position in z-UV layer, use expected X-position to evaluate expected Y with
      // correction in Y Note : the correction in y is currently ONLY dependent on the x position of the choosen hit,
      // and input VeloTracks. Potentially stronger Y constraints can be obtained using (tx,ty from Velo(or Velo-UT))
      // plus the local x-z projection under processing ( local SciFI ax,tx,cx ) , instead of a single x position of the
      // hit
      const auto dz = z4 - LookingForward::z_mid_t;
      const auto expected_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);
      const auto expected_y = LookingForward::project_y(
        dev_looking_forward_constants,
        input_state,
        expected_x,
        z4,
        dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer]);
      // This is the predicted_x in the u/v reference plane (i.e. the actual hit position measured)
      const auto predicted_x =
        expected_x - expected_y * dev_looking_forward_constants->Zone_dxdy_uvlayers[relative_uv_layer & 0x1];

      // Pick the best, according to chi2.
      // TODO : This needs some dedicated tuning. We scale the max_chi2 ( i.e the max distance in the x-plane )
      // as a function of ty of the track and delta_slope (  of tracks ).
      // Bigger windows for higher slopes and delta_slope  (small momentum)
      // If slopees are small the track is central,  the track bends a little, thee error on the estimation is small.
      // +-2 mm windows is ok (2^{2}  = 4) . If we have large slope the error on x can be big,  For super peripheral
      // tracks ( delta-slope = 0.3, ty = 0.3) you want to open up up to : sqrt(4+60*0.3+60*0.3) = 6 mm windows. Anyway,
      // we need some retuning of this scaling windows.
      const float max_chi2 = uv_hits_chi2_factor * fabsf(input_state.ty) + uv_hits_chi2_factor * fabsf(input_state.tx);

      int best_index = -1;
      float best_chi2 = max_chi2;

      const auto scifi_hits_x0 = scifi_hits.x0_p(event_offset + uv_window_start);

      // Binary search of candidate
      const auto candidate_index = binary_search_leftmost(scifi_hits_x0, uv_window_size, predicted_x);

      // It is now either candidate_index - 1 or candidate_index
      for (int h4_rel = candidate_index - 1; h4_rel < candidate_index + 1; ++h4_rel) {
        if (h4_rel >= 0 && h4_rel < uv_window_size) {
          const auto x4 = scifi_hits_x0[h4_rel];
          const auto chi2 = (x4 - predicted_x) * (x4 - predicted_x);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_index = h4_rel;
          }
        }
      }

      if (best_index != -1) {
        track.add_hit_with_quality((uint16_t) uv_window_start + best_index, best_chi2 / max_chi2);
      }
    }
  }
}

__global__ void lf_create_tracks::lf_extend_tracks(
  lf_create_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    extend_tracks<true>(parameters, dev_looking_forward_constants, ut_tracks);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    extend_tracks<false>(parameters, dev_looking_forward_constants, velo_tracks);
  }
}
