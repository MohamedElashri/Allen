#include "LFQualityFilter.cuh"

__global__ void lf_quality_filter::lf_quality_filter(
  lf_quality_filter::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states,
                                                velo_tracks.total_number_of_tracks()};

  const auto ut_event_tracks_offset = parameters.dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks =
    parameters.dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = parameters.dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];

  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  const auto number_of_tracks = parameters.dev_scifi_lf_length_filtered_atomics[event_number];
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    SciFi::TrackHits& track = parameters.dev_scifi_lf_length_filtered_tracks[scifi_track_index];
    const auto& ut_state = parameters.dev_ut_states[ut_event_tracks_offset + track.ut_track_index];

    bool hit_in_T1_UV = false;
    bool hit_in_T2_UV = false;
    bool hit_in_T3_UV = false;
    uint number_of_uv_hits = 0;
    for (uint j = 3; j < track.hitsNum; ++j) {
      const auto hit_index = event_offset + track.hits[j];
      const auto layer_number = scifi_hits.planeCode(hit_index) / 2;

      const bool current_hit_in_T1_UV = (layer_number == 1) || (layer_number == 2);
      const bool current_hit_in_T2_UV = (layer_number == 5) || (layer_number == 6);
      const bool current_hit_in_T3_UV = (layer_number == 9) || (layer_number == 10);

      hit_in_T1_UV |= current_hit_in_T1_UV;
      hit_in_T2_UV |= current_hit_in_T2_UV;
      hit_in_T3_UV |= current_hit_in_T3_UV;
      number_of_uv_hits += current_hit_in_T1_UV + current_hit_in_T2_UV + current_hit_in_T3_UV;
    }

    // Load parametrization
    const auto a1 = parameters.dev_scifi_lf_parametrization_length_filter[scifi_track_index];
    const auto b1 =
      parameters.dev_scifi_lf_parametrization_length_filter
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto c1 =
      parameters.dev_scifi_lf_parametrization_length_filter
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto d_ratio =
      parameters.dev_scifi_lf_parametrization_length_filter
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];

    // Do Y line fit
    const auto y_lms_fit = LookingForward::least_mean_square_y_fit(
      track, number_of_uv_hits, scifi_hits, a1, b1, c1, d_ratio, event_offset, dev_looking_forward_constants);

    // Save Y line fit
    parameters.dev_scifi_lf_y_parametrization_length_filter[scifi_track_index] = std::get<1>(y_lms_fit);
    parameters.dev_scifi_lf_y_parametrization_length_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index] =
      std::get<2>(y_lms_fit);

    const float y_fit_contribution = std::get<0>(y_lms_fit) / LookingForward::range_y_fit_end;

    const auto in_ty_window = fabsf(std::get<2>(y_lms_fit) - ut_state.ty) < LookingForward::max_diff_ty_window;
    const bool acceptable = hit_in_T1_UV && hit_in_T2_UV && hit_in_T3_UV &&
                            (track.hitsNum >= LookingForward::min_hits_or_ty_window || in_ty_window);

    // Combined value
    const auto combined_value = track.quality / (track.hitsNum - 3);

    track.quality = acceptable ? combined_value + y_fit_contribution : 10000.f;

    // Apply multipliers to quality of tracks depending on number of hits
    if (track.hitsNum == 9) {
      track.quality *= LookingForward::track_9_hits_quality_multiplier;
    }
    else if (track.hitsNum == 10) {
      track.quality *= LookingForward::track_10_hits_quality_multiplier;
    }
    else if (track.hitsNum == 11) {
      track.quality *= LookingForward::track_11_hits_quality_multiplier;
    }
    else if (track.hitsNum == 12) {
      track.quality *= LookingForward::track_12_hits_quality_multiplier;
    }

    // // This code is to keep all the tracks
    // const auto insert_index = atomicAdd(parameters.dev_atomics_scifi + event_number, 1);
    // parameters.dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track +
    // insert_index] = track;
  }

  __syncthreads();

  for (uint i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    float best_quality = LookingForward::quality_filter_max_quality;
    short best_track_index = -1;

    for (uint j = 0; j < number_of_tracks; j++) {
      const SciFi::TrackHits& track =
        parameters.dev_scifi_lf_length_filtered_tracks
          [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + j];
      if (track.ut_track_index == i && track.quality < best_quality) {
        best_quality = track.quality;
        best_track_index = j;
      }
    }

    if (best_track_index != -1) {
      const auto insert_index = atomicAdd(parameters.dev_atomics_scifi + event_number, 1);
      assert(insert_index < ut_event_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track);

      const auto scifi_track_index =
        ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + best_track_index;
      const auto& track = parameters.dev_scifi_lf_length_filtered_tracks[scifi_track_index];

      const auto new_scifi_track_index =
        ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index;
      parameters.dev_scifi_tracks[new_scifi_track_index] = track;

      // Save track parameters to last container as well
      const auto a1 = parameters.dev_scifi_lf_parametrization_length_filter[scifi_track_index];
      const auto b1 =
        parameters.dev_scifi_lf_parametrization_length_filter
          [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = parameters.dev_scifi_lf_parametrization_length_filter
                        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
                         scifi_track_index];
      const auto d_ratio =
        parameters.dev_scifi_lf_parametrization_length_filter
          [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
           scifi_track_index];
      const auto y_b = parameters.dev_scifi_lf_y_parametrization_length_filter[scifi_track_index];
      const auto y_m =
        parameters.dev_scifi_lf_y_parametrization_length_filter
          [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track + scifi_track_index];

      parameters.dev_scifi_lf_parametrization_consolidate[new_scifi_track_index] = a1;
      parameters.dev_scifi_lf_parametrization_consolidate
        [ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = b1;
      parameters.dev_scifi_lf_parametrization_consolidate
        [2 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = c1;
      parameters.dev_scifi_lf_parametrization_consolidate
        [3 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] =
        d_ratio;
      parameters.dev_scifi_lf_parametrization_consolidate
        [4 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = y_b;
      parameters.dev_scifi_lf_parametrization_consolidate
        [5 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = y_m;

      // Update qop of the track
      const auto velo_track_index = parameters.dev_ut_track_velo_indices[ut_event_tracks_offset + track.ut_track_index];
      const auto velo_states_index = velo_tracks_offset_event + velo_track_index;
      const auto velo_state = velo_states.getMiniState(velo_states_index);

      const auto x0 = scifi_hits.x0(event_offset + track.hits[0]);
      const auto x1 = scifi_hits.x0(event_offset + track.hits[2]);
      const auto layer0 = scifi_hits.planeCode(event_offset + track.hits[0]) / 2;
      const auto layer1 = scifi_hits.planeCode(event_offset + track.hits[2]) / 2;
      const auto z0 = dev_looking_forward_constants->Zone_zPos[layer0];
      const auto z1 = dev_looking_forward_constants->Zone_zPos[layer1];
      const auto bx = (x0 - x1) / (z0 - z1);

      const auto bx2 = bx * bx;
      const auto ty2 = velo_state.ty * velo_state.ty;
      const auto coef =
        (dev_looking_forward_constants->momentumParams[0] + dev_looking_forward_constants->momentumParams[1] * bx2 +
         dev_looking_forward_constants->momentumParams[2] * bx2 * bx2 +
         dev_looking_forward_constants->momentumParams[3] * bx * velo_state.tx +
         dev_looking_forward_constants->momentumParams[4] * ty2 +
         dev_looking_forward_constants->momentumParams[5] * ty2 * ty2);
      const auto tx2 = velo_state.tx * velo_state.tx;
      const auto slope2 = tx2 + ty2;
      const auto proj = sqrtf((1.f + slope2) / (1.f + tx2));
      const auto updated_qop = (velo_state.tx - bx) / (coef * Gaudi::Units::GeV * proj * dev_magnet_polarity[0]);
      parameters.dev_scifi_tracks[new_scifi_track_index].qop = updated_qop;
    }
  }
}
