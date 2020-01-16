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

__global__ void prepare_raw_banks(
  uint* dev_atomics_velo,
  uint* dev_velo_track_hit_number,
  char* dev_velo_track_hits,
  uint* dev_atomics_ut,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  uint* dev_velo_indices,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_ut_indices,
  char* dev_ut_consolidated_hits,
  char* dev_scifi_consolidated_hits,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_svs,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  // Information about candidates for each line.
  uint* dev_candidate_lists,
  uint* dev_candidate_counts,
  // Information about the total number of saved candidates per event.
  uint* dev_n_svs_saved,
  uint* dev_n_tracks_saved,
  uint* dev_n_hits_saved,
  // Lists of saved candidates.
  uint* dev_saved_tracks_list,
  uint* dev_saved_svs_list,
  // Flags for saving candidates.
  int* dev_save_track,
  int* dev_save_sv,
  // Output.
  uint32_t* dev_dec_reports,
  uint32_t* dev_sel_rb_hits,
  uint32_t* dev_sel_rb_stdinfo,
  uint32_t* dev_sel_rb_objtyp,
  uint32_t* dev_sel_rb_substr,
  uint* dev_sel_rep_offsets,
  uint* number_of_passing_events,
  uint* event_list);

ALGORITHM(
  prepare_raw_banks,
  prepare_raw_banks_t,
  ARGUMENTS(
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_track_hits,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_scifi_track_hit_number,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_ut_track_hits,
    dev_scifi_track_hits,
    dev_kf_tracks,
    dev_secondary_vertices,
    dev_atomics_scifi,
    dev_sv_atomics,
    dev_candidate_lists,
    dev_candidate_counts,
    dev_n_svs_saved,
    dev_n_tracks_saved,
    dev_n_hits_saved,
    dev_saved_tracks_list,
    dev_saved_svs_list,
    dev_save_track,
    dev_save_sv,
    dev_dec_reports,
    dev_sel_rb_hits,
    dev_sel_rb_stdinfo,
    dev_sel_rb_objtyp,
    dev_sel_rb_substr,
    dev_sel_rep_offsets,
    dev_number_of_passing_events,
    dev_passing_event_list))
