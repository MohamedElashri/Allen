#include "PrepareRawBanks.cuh"

__global__ void prepare_raw_banks(
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  const bool* dev_sel_results,
  const uint* dev_sel_results_atomics,
  uint32_t* dev_dec_reports,
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
  const int n_hlt1_lines = Hlt1::Hlt1Lines::End - 2;
  uint32_t* event_dec_reports = dev_dec_reports + (2 + n_hlt1_lines) * event_number;

  // Set track decisions.
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  for (uint i_line = Hlt1::Hlt1Lines::StartOneTrackLines; i_line < Hlt1::Hlt1Lines::StartTwoTrackLines; i_line++) {
    const bool* decisions = dev_sel_results +
      dev_sel_results_offsets[i_line] + event_tracks_offsets[event_number];
    for (int i_track = threadIdx.x; i_track < n_tracks_event; i_track += blockDim.x) {    
      // One track.
      uint32_t dec = ((decisions[i_track] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + 2 + i_line - 1, dec);
    }
  }
  
  // Set vertex decisions.
  for (uint i_line = Hlt1::Hlt1Lines::StartTwoTrackLines; i_line < Hlt1::Hlt1Lines::End; i_line++) {
    const bool* decisions = dev_sel_results +
      dev_sel_results_offsets[i_line] + dev_sv_offsets[event_number];
    for (int i_sv = threadIdx.x; i_sv < n_vertices_event; i_sv += blockDim.x) {
      // Two track.
      uint32_t dec = ((decisions[i_sv] ? 1 : 0) & dec_mask);
      atomicOr(event_dec_reports + i_line, dec);
    }
  }
  __syncthreads();

  // If any line is passed, add to selected events and create the rest of the DecReport.
  if (threadIdx.x == 0) {
    
    // Return if event has not passed.
    bool pass = false;
    for (int i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      if (i_line == Hlt1::Hlt1Lines::StartOneTrackLines ||
          i_line == Hlt1::Hlt1Lines::StartTwoTrackLines) {
        continue;
      }      
      int line_location = (i_line < Hlt1::Hlt1Lines::End ? i_line - 1 : i_line - 2);
      pass = pass || ((event_dec_reports[2 + line_location] & dec_mask) == (1 & dec_mask));
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
