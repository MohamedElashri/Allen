#include "PrepareRawBanks.cuh"

__global__ void prepare_raw_banks(
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_track_hits,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const MiniState* dev_scifi_states,
  const uint dev_ut_indices,
  const char* dev_ut_consolidated_hits,
  const char* dev_scifi_consolidated_hits,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_svs,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  const bool* dev_sel_results,
  const uint* dev_sel_results_atomics,
  // Information about candidates for each line.
  uint* dev_candidate_lists,
  uint* dev_candidate_counts,
  // Information about the total number of saved candidates per event.
  uint* dev_n_svs_saved,
  uint* dev_n_tracks_saved,
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
  uint* event_list)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Tracks.
  const uint* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const auto n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const uint* dev_sv_offsets = dev_sv_atomics + number_of_events;
  const uint n_vertices_event = dev_sv_atomics[event_number];

  // Results.
  const uint* dev_sel_results_offsets = dev_sel_results_atomics + Hlt1::Hlt1Lines::End;
  
  // Dec reports.
  const int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  uint32_t* event_dec_reports = dev_dec_reports + (2 + n_hlt1_lines) * event_number;
  

  // Sel reports. 
  const uint event_sel_rb_hits_offset =
    event_tracks_offsets[event_number] * ParKalmanFilter::nMaxMeasurements;
  uint* event_sel_rb_hits = dev_sel_rb_hits + event_sel_rb_hits_offset;
  const uint event_sel_rb_stdinfo_offset = event_number * Hlt1::maxStdInfoEvent;
  uint* event_sel_rb_stdinfo = dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
  const uint event_sel_rb_objtyp_offset = event_number * (Hlt1::nObjTyp + 1);
  uint* event_sel_rb_objtyp = dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
  const uint event_sel_rb_substr_offset = event_number * Hlt1::subStrDefaultAllocationSize;
  uint* event_sel_rb_substr = dev_sel_rb_substr + event_sel_rb_substr_offset; 
  
  // Set track decisions.
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    const bool* decisions = dev_sel_results +
      dev_sel_results_offsets[i_line] + event_tracks_offsets[event_number];
    for (int i_track = threadIdx.x; i_track < n_tracks_event; i_track += blockDim.x) {    
      // One track.
      uint32_t dec = ((decisions[i_track] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + 2 + i_line, dec);
    }
  }
  
  // Set vertex decisions.
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    const bool* decisions = dev_sel_results +
      dev_sel_results_offsets[i_line] + dev_sv_offsets[event_number];
    for (int i_sv = threadIdx.x; i_sv < n_vertices_event; i_sv += blockDim.x) {
      // Two track.
      uint32_t dec = ((decisions[i_sv] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + 2 + i_line, dec);
    }
  }
  __syncthreads();

  // If any line is passed, add to selected events and create the rest of the DecReport.
  if (threadIdx.x == 0) {
    
    // Return if event has not passed.
    bool pass = false;
    for (int i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      pass = pass || ((event_dec_reports[2 + i_line] & dec_mask) == (1 & dec_mask));
      if (pass) {
        break;
      }
    }
    if (!pass) return;

    const uint n_pass = atomicAdd(number_of_passing_events, 1);
    event_list[n_pass] = event_number;
    // Create the rest of the dec report.
    event_dec_reports[0] = Hlt1::TCK;
    event_dec_reports[1] = Hlt1::taskID;
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      HltDecReport dec_report;
      dec_report.setDecision(false);
      // TODO: These are all placeholder values for now.
      dec_report.setErrorBits(0);
      dec_report.setNumberOfCandidates(1);
      dec_report.setIntDecisionID(i_line);
      dec_report.setExecutionStage(1);
      // Set the final dec report.
      event_dec_reports[2 + i_line] |= dec_report.getDecReport();
    }
  }
  
}
