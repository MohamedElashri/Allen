#include "LFQualityFilter.cuh"

__global__ void lf_quality_filter(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  uint* dev_atomics_scifi,
  SciFi::TrackHits* dev_scifi_tracks,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_scifi_lf_parametrization_length_filter,
  float* dev_scifi_lf_y_parametrization_length_filter,
  float* dev_scifi_lf_parametrization_consolidate,
  const MiniState* dev_ut_states)
{
  if (Configuration::verbosity_level >= logger::debug) {
    if (blockIdx.y == 0) {
      printf("\n\n------------- Quality filter ---------------\n");
    }
  }

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};

  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i;
    SciFi::TrackHits& track = dev_scifi_lf_tracks[scifi_track_index];
    const auto& ut_state = dev_ut_states[ut_event_tracks_offset + track.ut_track_index];

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
    const auto a1 = dev_scifi_lf_parametrization_length_filter[scifi_track_index];
    const auto b1 = dev_scifi_lf_parametrization_length_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto c1 = dev_scifi_lf_parametrization_length_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];
    const auto d_ratio = dev_scifi_lf_parametrization_length_filter
      [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index];

    // Do Y line fit
    const auto y_lms_fit = LookingForward::lms_y_fit(
      track, number_of_uv_hits, scifi_hits, a1, b1, c1, d_ratio, event_offset, dev_looking_forward_constants);

    // Save Y line fit
    dev_scifi_lf_y_parametrization_length_filter[scifi_track_index] = std::get<1>(y_lms_fit);
    dev_scifi_lf_y_parametrization_length_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
       scifi_track_index] = std::get<2>(y_lms_fit);

    constexpr float range_y_fit_end = 800.f;
    const float y_fit_contribution = std::get<0>(y_lms_fit) / range_y_fit_end;

    const auto in_ty_window = fabsf(std::get<2>(y_lms_fit) - ut_state.ty) < 0.02f;
    const bool acceptable = hit_in_T1_UV && hit_in_T2_UV && hit_in_T3_UV && (track.hitsNum >= 11 || in_ty_window);

    // Combined value
    const auto combined_value = track.quality / (track.hitsNum - 3);

    track.quality = acceptable ? combined_value + y_fit_contribution : 10000.f;

    if (track.hitsNum == 11) {
      track.quality *= 0.8f;
    }
    else if (track.hitsNum == 12) {
      track.quality *= 0.5f;
    }

    // // This code is to keep all the tracks
    // const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
    // dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] =
    // track;
  }

  __syncthreads();

  for (uint i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    float best_quality = 0.5f;
    short best_track_index = -1;

    for (uint j = 0; j < number_of_tracks; j++) {
      const SciFi::TrackHits& track = dev_scifi_lf_tracks
        [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + j];
      if (track.ut_track_index == i && track.quality < best_quality) {
        best_quality = track.quality;
        best_track_index = j;
      }
    }

    if (best_track_index != -1) {
      const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
      assert(insert_index < ut_event_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track);

      const auto scifi_track_index = ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         best_track_index;
      const auto& track = dev_scifi_lf_tracks[scifi_track_index];

      const auto new_scifi_track_index = ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index;
      dev_scifi_tracks[new_scifi_track_index] = track;

      // Save track parameters to last container as well
      const auto a1 = dev_scifi_lf_parametrization_length_filter[scifi_track_index];
      const auto b1 = dev_scifi_lf_parametrization_length_filter
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + scifi_track_index];
      const auto c1 = dev_scifi_lf_parametrization_length_filter
        [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         scifi_track_index];
      const auto d_ratio = dev_scifi_lf_parametrization_length_filter
        [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         scifi_track_index];
      const auto y_b = dev_scifi_lf_y_parametrization_length_filter[scifi_track_index];
      const auto y_m = dev_scifi_lf_y_parametrization_length_filter
        [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         scifi_track_index];

      dev_scifi_lf_parametrization_consolidate[new_scifi_track_index] = a1;
      dev_scifi_lf_parametrization_consolidate
        [ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
         new_scifi_track_index] = b1;
      dev_scifi_lf_parametrization_consolidate
        [2 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
         new_scifi_track_index] = c1;
      dev_scifi_lf_parametrization_consolidate
        [3 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
         new_scifi_track_index] = d_ratio;
      dev_scifi_lf_parametrization_consolidate
        [4 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
         new_scifi_track_index] = y_b;
      dev_scifi_lf_parametrization_consolidate
        [5 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
         new_scifi_track_index] = y_m;
    }
  }
}
