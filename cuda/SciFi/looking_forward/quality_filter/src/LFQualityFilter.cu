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
  uint* dev_scifi_selected_track_indices,
  SciFi::TrackHits* dev_scifi_tracks)
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

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};

  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_lf_tracks
      [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];

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

    // TODO: Do Y line fit and check it doesn't deviate too much
    // // Traverse all UV hits
    // for (uint j = track.hitsNum - number_of_uv_hits; j < track.hitsNum; ++j) {
    //   const auto hit_index = event_offset + track.hits[j];
    // }

    if (Configuration::verbosity_level >= logger::debug) {
      track.print(event_number);
    }

    const auto ndof = track.hitsNum - 5;
    track.quality = (hit_in_T1_UV && hit_in_T2_UV && hit_in_T3_UV) ? track.quality / ndof : 10000.f;

    // // This code is to keep all the tracks
    // if (track.quality < 10.f) {
    //   const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
    //   dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = track;
    //   dev_scifi_selected_track_indices[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = i;
    // }
  }

  __syncthreads();

  for (uint i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    float best_quality = 10.f;
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

      const auto& track = dev_scifi_lf_tracks
        [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
         best_track_index];

      dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = track;
      dev_scifi_selected_track_indices
        [ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = best_track_index;
    }
  }
}
