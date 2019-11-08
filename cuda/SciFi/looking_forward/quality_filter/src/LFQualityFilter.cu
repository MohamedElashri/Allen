#include "LFQualityFilter.cuh"

#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"

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
  SciFi::TrackHits* dev_scifi_tracks,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_scifi_lf_parametrization_length_filter,
  const MiniState* dev_ut_states,
  const uint number_of_events)
{
  TFile* f = new TFile("../output/scifi.root", "RECREATE");
  TTree* t_scifi_tracks_chi2s = new TTree("t_scifi_tracks_chi2s", "t_scifi_tracks_chi2s");

  float t_xchi2, t_ychi2, t_uvchi2;
  t_scifi_tracks_chi2s->Branch("t_xchi2", &t_xchi2);
  t_scifi_tracks_chi2s->Branch("t_ychi2", &t_ychi2);
  t_scifi_tracks_chi2s->Branch("t_uvchi2", &t_uvchi2);

  if (Configuration::verbosity_level >= logger::debug) {
    if (blockIdx.y == 0) {
      printf("\n\n------------- Quality filter ---------------\n");
    }
  }

  for (uint event_number = 0; event_number < number_of_events; ++event_number) {

    // const auto number_of_events = gridDim.x;
    // const auto event_number = blockIdx.x;

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
      const auto scifi_track_index = ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i;
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
      
      // Do X fit
      float x_fit_chi2 = 0.f;
      for (uint i_hit = 0; i_hit < track.hitsNum - number_of_uv_hits; ++i_hit) {
        const auto hit_index = event_offset + track.hits[i_hit];
        const auto layer_index = scifi_hits.planeCode(hit_index) / 2;
        const auto x = scifi_hits.x0[hit_index];
        const auto z = dev_looking_forward_constants->Zone_zPos[layer_index];
        const auto dz = z - LookingForward::z_mid_t;
        const auto predicted_x =
          c1 + b1 * dz +
          a1 * dz * dz * (1.f + LookingForward::d_ratio * dz);
        x_fit_chi2 += (x - predicted_x) * (x - predicted_x);
      }
      x_fit_chi2 /= (track.hitsNum - number_of_uv_hits - 3);

      // Do Y line fit
      const auto y_lms_fit = LookingForward::lms_y_fit(
        track,
        number_of_uv_hits,
        scifi_hits,
        a1,
        b1,
        c1,
        event_offset,
        dev_looking_forward_constants);

      // Stereo hits X fit
      const auto uv_x_fit = track.quality / (number_of_uv_hits - 3);

      // Combined value
      const auto combined_value = x_fit_chi2 + std::get<0>(y_lms_fit) / 1000.f + uv_x_fit / 8.f;

      t_xchi2 = x_fit_chi2;
      t_ychi2 = std::get<0>(y_lms_fit);
      t_uvchi2 = uv_x_fit;

      t_scifi_tracks_chi2s->Fill();

      // printf("Qualities: %f, %f, %f, %f\n", x_fit_chi2, std::get<0>(y_lms_fit), uv_x_fit, combined_value);

      if (Configuration::verbosity_level >= logger::debug) {
        track.print(event_number);
      }

      const auto in_ty_window = fabsf(std::get<2>(y_lms_fit) - ut_state.ty) < 0.02f;

      track.quality = (in_ty_window && 
        hit_in_T1_UV && hit_in_T2_UV && hit_in_T3_UV) ? combined_value : 10000.f;

      // // This code is to keep all the tracks
      if (track.quality < 1000.f) {
        const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
        dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = track;
        dev_scifi_selected_track_indices[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = i;
      }
    }


    f->Write();
    f->Close();

    // __syncthreads();

    // for (uint i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    //   float best_quality = 10.f;
    //   short best_track_index = -1;

    //   for (uint j = 0; j < number_of_tracks; j++) {
    //     const SciFi::TrackHits& track = dev_scifi_lf_tracks
    //       [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + j];
    //     if (track.ut_track_index == i && track.quality < best_quality) {
    //       best_quality = track.quality;
    //       best_track_index = j;
    //     }
    //   }

    //   if (best_track_index != -1) {
    //     const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
    //     assert(insert_index < ut_event_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track);

    //     const auto& track = dev_scifi_lf_tracks
    //       [ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter +
    //        best_track_index];

    //     dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = track;
    //     dev_scifi_selected_track_indices
    //       [ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index] = best_track_index;
    //   }
    // }
  }
}
