#include "PrepareDecisions.cuh"
#include "RawBanksDefinitions.cuh"

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
  int* dev_save_sv)
{
  
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Create velo tracks.
  const Velo::Consolidated::Tracks velo_tracks {(uint*) dev_atomics_velo,
                                                (uint*) dev_velo_track_hit_number,
                                                event_number,
                                                number_of_events};

  // Create UT tracks.
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_velo_indices,
                                            event_number,
                                            number_of_events};

  // Create SciFi tracks.
  const SciFi::Consolidated::Tracks scifi_tracks {(uint*) dev_atomics_scifi,
                                                  (uint*) dev_scifi_track_hit_number,
                                                  (float*) dev_scifi_qop,
                                                  (MiniState*) dev_scifi_states,
                                                  (uint*) dev_ut_indices,
                                                  event_number,
                                                  number_of_events};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};

  // Selection results.
  const uint* dev_sel_results_offsets = dev_sel_results_atomics + Hlt1::Hlt1Lines::End;
  
  // Tracks.
  const uint* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  int* event_save_track = dev_save_track + event_tracks_offsets[event_number];
  const int n_tracks_event = dev_atomics_scifi[event_number];
  uint* event_saved_tracks_list = dev_saved_tracks_list + event_tracks_offsets[event_number];
  const ParKalmanFilter::FittedTrack* event_kf_tracks = dev_kf_tracks + event_tracks_offsets[event_number];
  
  // Vertices.
  const uint* dev_sv_offsets = dev_sv_atomics + number_of_events;
  int* event_save_sv = dev_save_sv + dev_sv_offsets[event_number];
  const int n_vertices_event = dev_sv_atomics[event_number];
  uint* event_saved_svs_list = dev_saved_svs_list + dev_sv_offsets[event_number];
  const VertexFit::TrackMVAVertex* event_svs = dev_svs + dev_sv_offsets[event_number];

  const int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  uint32_t* event_dec_reports = dev_dec_reports + (2 + n_hlt1_lines) * event_number;

  // Set vertex decisions first.
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  uint insert_index = 0;
  for (uint i_sv = threadIdx.x; i_sv < n_vertices_event; i_sv += blockDim.x) {
    uint32_t save_sv = 0;
    for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
      const bool* decisions = dev_sel_results +
        dev_sel_results_offsets[i_line] + dev_sv_offsets[event_number];
      uint* candidate_counts = dev_candidate_counts + i_line * number_of_events + event_number;
      uint* candidate_list = dev_candidate_lists + number_of_events * Hlt1::maxCandidates * i_line +
      event_number * Hlt1::maxCandidates;
      uint32_t dec = ((decisions[i_sv] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + 2 + i_line, dec);
      insert_index = atomicAdd(candidate_counts, dec);
      save_sv |= dec;
      if (dec) {
        candidate_list[insert_index] = i_sv;
      }
    }
    if (save_sv & dec_mask) {
      const uint sv_insert_index = atomicAdd(dev_n_svs_saved + event_number, 1);
      event_save_sv[i_sv] = sv_insert_index;
      event_saved_svs_list[sv_insert_index] = i_sv;
      // Set to 1 for as a placeholder.
      event_save_track[event_svs[i_sv].trk1] = 1;
      event_save_track[event_svs[i_sv].trk2] = 1;
    }
  }
  __syncthreads();

  // Set track decisions.
  for (int i_track = threadIdx.x; i_track < n_tracks_event; i_track += blockDim.x) {
    uint32_t save_track = 0;
    for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
      const bool* decisions = dev_sel_results +
        dev_sel_results_offsets[i_line] + event_tracks_offsets[event_number];
      uint* candidate_counts = dev_candidate_counts + i_line * number_of_events + event_number;
      uint* candidate_list = dev_candidate_lists + number_of_events * Hlt1::maxCandidates * i_line +
        event_number * Hlt1::maxCandidates;
      uint32_t dec = ((decisions[i_track] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + 2 + i_line, dec);
      insert_index = atomicAdd(candidate_counts, dec);
      save_track |= dec;
      if (dec) {
        candidate_list[insert_index] = i_track;
      }
    }
    if (save_track) {
      event_save_track[i_track] = 1;
    }
    // Count the number of tracks and hits to save in the SelReport.
    if (event_save_track[i_track] >= 0) {
      const int i_ut_track = scifi_tracks.ut_track[i_track];
      const int i_velo_track = ut_tracks.velo_track[i_ut_track];
      const int n_hits = scifi_tracks.number_of_hits(i_track) +
        ut_tracks.number_of_hits(i_ut_track) + velo_tracks.number_of_hits(i_velo_track);
      const uint track_insert_index = atomicAdd(dev_n_tracks_saved + event_number, 1);
      atomicAdd(dev_n_hits_saved + event_number, n_hits);
      event_saved_tracks_list[track_insert_index] = (uint) i_track;
      event_save_track[i_track] = (int) track_insert_index;
    }
  }
  __syncthreads();
  
}