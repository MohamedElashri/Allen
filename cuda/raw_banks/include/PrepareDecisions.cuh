#pragma once

#include "HltDecReport.cuh"
#include "HltSelReport.cuh"
#include "RawBanksDefinitions.cuh"

#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "ParKalmanDefinitions.cuh"

#include "Handler.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsRawBanks.cuh"

__global__ void prepare_decisions(
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_track_hits,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_velo_indices,
  const uint* dev_atomics_scifi,
  const uint* dev_scifi_track_hit_number,
  const float* dev_scifi_qop,
  const MiniState* dev_scifi_states,
  const uint* dev_ut_indices,
  const char* dev_ut_consolidated_hits,
  const char* dev_scifi_consolidated_hits,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_svs,
  const uint* dev_sv_atomics,
  const bool* dev_sel_results,
  const uint* dev_sel_results_atomics,
  uint* dev_candidate_lists,
  uint* dev_candidate_counts,  
  uint* dev_n_passing_decisions,
  uint* dev_n_svs_saved,
  uint* dev_n_tracks_saved,
  uint* dev_n_hits_saved,
  uint* dev_saved_tracks_list,
  uint* dev_saved_svs_list,
  uint* dev_dec_reports,
  int* dev_save_track,
  int* dev_save_sv);

ALGORITHM(
  prepare_decisions,
  prepare_decisions_t,
  ARGUMENTS(
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_track_hits,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_atomics_scifi,
    dev_scifi_track_hit_number,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_ut_track_hits,
    dev_scifi_track_hits,
    dev_kf_tracks,
    dev_secondary_vertices,
    dev_sv_atomics,
    dev_sel_results,
    dev_sel_results_atomics,
    dev_candidate_lists,
    dev_candidate_counts,
    dev_n_passing_decisions,
    dev_n_svs_saved,
    dev_n_tracks_saved,
    dev_n_hits_saved,
    dev_saved_tracks_list,
    dev_saved_svs_list,
    dev_dec_reports,
    dev_save_track,
    dev_save_sv))
