#include "LFExtendTracksUV.cuh"
#include "BinarySearch.cuh"

__global__ void lf_extend_tracks_uv::lf_extend_tracks_uv(
  lf_extend_tracks_uv::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  UT::Consolidated::ConstTracks ut_tracks {
    parameters.dev_atomics_ut, parameters.dev_ut_track_hit_number, event_number, number_of_events};

  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = parameters.dev_scifi_lf_atomics[event_number];

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    SciFi::TrackHits& track = parameters.dev_scifi_lf_tracks[scifi_track_index];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;
    const auto ut_state = parameters.dev_ut_states[current_ut_track_index];

    // Use quality normalized
    track.quality *= (1.f / LookingForward::chi2_max_extrapolation_to_x_layers_single);

    // Load parametrization
    const auto a1 = parameters.dev_scifi_lf_parametrization[scifi_track_index];
    const auto b1 =
      parameters.dev_scifi_lf_parametrization
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto c1 =
      parameters.dev_scifi_lf_parametrization
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto d_ratio =
      parameters.dev_scifi_lf_parametrization
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];

    for (int relative_uv_layer = 0; relative_uv_layer < 6; relative_uv_layer++) {
      const auto layer4 = dev_looking_forward_constants->extrapolation_uv_layers[relative_uv_layer];
      const auto z4 = dev_looking_forward_constants->Zone_zPos[layer4];

      // Use UV windows
      const auto uv_window_start =
        parameters.dev_scifi_lf_initial_windows
          [ut_event_tracks_offset + track.ut_track_index +
           (relative_uv_layer * LookingForward::number_of_elements_initial_window + 2) * ut_total_number_of_tracks];
      const auto uv_window_size =
        parameters.dev_scifi_lf_initial_windows
          [ut_event_tracks_offset + track.ut_track_index +
           (relative_uv_layer * LookingForward::number_of_elements_initial_window + 3) * ut_total_number_of_tracks];

      // Calculate expected X true position in z-UV layer, use expected X-position to evaluate expected Y with correction in Y
      // Note : the correction in y is currently ONLY dependent on the x position of the choosen hit, and input VeloTracks. 
      // Potentially stronger Y constraints can be obtained using (tx,ty from Velo(or Velo-UT)) 
      // plus the local x-z projection under processing ( local SciFI ax,tx,cx ) , instead of a single x position of the hit
      const auto dz = z4 - LookingForward::z_mid_t;
      const auto expected_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);
      const auto expected_y = LookingForward::project_y(
        dev_looking_forward_constants,
        ut_state,
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
      // If slopees are small the track is central,  the track bends a little, thee error on the estimation is small. +-2 mm windows is ok (2^{2}  = 4) .
      // If we have large slope the error on x can be big,  For super peripheral tracks ( delta-slope = 0.3, ty = 0.3) you want to open up up to :
      // sqrt(4+60*0.3+60*0.3) = 6 mm windows. Anyway, we need some retuning of this scaling windows.
      const float max_chi2 = 50.f * fabsf(ut_state.ty) + 50.f * fabsf(ut_state.tx);

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
