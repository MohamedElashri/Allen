#include "PrepareRawBanks.cuh"

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
  uint* event_list)
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

  // Tracks.
  const uint* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  int* event_save_track = dev_save_track + event_tracks_offsets[event_number];
  const int n_tracks_event = dev_atomics_scifi[event_number];
  uint* event_saved_tracks_list = dev_saved_tracks_list + event_tracks_offsets[event_number];
  const ParKalmanFilter::FittedTrack* event_kf_tracks = dev_kf_tracks + event_tracks_offsets[event_number];

  // Vertices.
  const uint* dev_sv_offsets = dev_sv_atomics + number_of_events;
  int* event_save_sv = dev_save_sv + dev_sv_offsets[event_number];
  const int n_vertices_event = dev_sv_offsets[event_number + 1] - dev_sv_offsets[event_number];
  uint* event_saved_svs_list = dev_saved_svs_list + dev_sv_offsets[event_number];
  const VertexFit::TrackMVAVertex* event_svs = dev_svs + dev_sv_offsets[event_number];

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

  // If any line is passed, add to selected events and create the rest of the DecReport.
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  if (threadIdx.x == 0) {

    // Return if event has not passed any selections.
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
    uint n_decisions = 0;
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      int line_index;
      if (i_line > Hlt1::Hlt1Lines::StartOneTrackLines) {
        line_index = i_line - 1;
      } else if (i_line > Hlt1::Hlt1Lines::StartTwoTrackLines) {
        line_index = i_line - 2;
      } else if (i_line == Hlt1::Hlt1Lines::StartOneTrackLines ||
                 i_line == Hlt1::Hlt1Lines::StartTwoTrackLines) {
        continue;
      } else {
        line_index = i_line;
      }
      HltDecReport dec_report;
      dec_report.setDecision(false);
      // TODO: These are all placeholder values for now.
      dec_report.setErrorBits(0);
      dec_report.setNumberOfCandidates(1);
      dec_report.setIntDecisionID(line_index);
      dec_report.setExecutionStage(1);
      event_dec_reports[2 + line_index] |= dec_report.getDecReport();
      if (event_dec_reports[2 + line_index] & dec_mask) {
        n_decisions++;
      }
    }

    // Create the hits sub-bank.
    HltSelRepRBHits hits_bank(
      dev_n_tracks_saved[event_number],
      dev_n_hits_saved[event_number],
      event_sel_rb_hits);

    // Create the substructure sub-bank.
    // Use default allocation size.
    HltSelRepRBSubstr substr_bank(0, event_sel_rb_substr);

    // Create the standard info sub-bank.
    uint nAllInfo = Hlt1::nStdInfoDecision * n_decisions +
      Hlt1::nStdInfoTrack * dev_n_tracks_saved[event_number] +
      Hlt1::nStdInfoSV * dev_n_svs_saved[event_number];
    uint nObj = n_decisions + dev_n_tracks_saved[event_number] + dev_n_svs_saved[event_number];
    bool writeStdInfo = nAllInfo < Hlt1::maxStdInfoEvent;
    HltSelRepRBStdInfo stdinfo_bank(nObj, nAllInfo, event_sel_rb_stdinfo);

    // Create the object type sub-bank.
    HltSelRepRBObjTyp objtyp_bank(Hlt1::nObjTyp, event_sel_rb_objtyp);
    objtyp_bank.addObj(Hlt1::selectionCLID, n_decisions);
    objtyp_bank.addObj(Hlt1::trackCLID, dev_n_tracks_saved[event_number]);
    objtyp_bank.addObj(Hlt1::svCLID, dev_n_svs_saved[event_number]);\

    // Add decision summaries to the StdInfo subbank. CLID = 1.
    // TODO: Don't loop over the decision lines multiple times.
    if (writeStdInfo) {
      for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
        uint line_index;
        if (i_line > Hlt1::Hlt1Lines::StartOneTrackLines) {
          line_index = i_line - 1;
        } else if (i_line > Hlt1::Hlt1Lines::StartTwoTrackLines) {
          line_index = i_line - 2;
        } else if (i_line == Hlt1::Hlt1Lines::StartOneTrackLines ||
                   i_line == Hlt1::Hlt1Lines::StartTwoTrackLines) {
          continue;
        } else {
          line_index = i_line;
        }
        if (event_dec_reports[2 + line_index] & dec_mask) {
          stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
          stdinfo_bank.addInfo(line_index);
        }
      }
    }

    // Add decisions to the substr bank.
    for (int i_line = Hlt1::Hlt1Lines::StartOneTrackLines; i_line < Hlt1::Hlt1Lines::StartTwoTrackLines; i_line++) {
      uint* candidate_counts = dev_candidate_counts + i_line * number_of_events + event_number;
      uint* candidate_list = dev_candidate_lists + (i_line * number_of_events + event_number) * Hlt1::maxCandidates;
      for (uint i_sub = 0; i_sub < candidate_counts[0]; i_sub++) {
        substr_bank.addPtr(n_decisions + event_save_track[candidate_list[i_sub]]);
      }
    }

    // Add tracks to the hits subbank and to the StdInfo. CLID = 10010.
    for (uint i_saved_track = 0; i_saved_track < dev_n_tracks_saved[event_number]; i_saved_track++) {
      uint i_track = event_saved_tracks_list[i_saved_track];
      // Add track parameters to StdInfo.
      if (writeStdInfo) {
        stdinfo_bank.addObj(Hlt1::nStdInfoTrack);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].state[0]);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].state[1]);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].z);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].state[2]);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].state[3]);
        stdinfo_bank.addInfo(event_kf_tracks[i_track].state[4]);
      }

      // Add to Substr.
      // No substructure. Ptr will be to hits.
      substr_bank.addSubstr(0, 1);
      substr_bank.addPtr(i_saved_track);

      // Create the tracks for saving.
      const int i_ut_track = scifi_tracks.ut_track[i_track];
      const int i_velo_track = ut_tracks.velo_track[i_ut_track];
      const uint n_hits = scifi_tracks.number_of_hits(i_track) +
        ut_tracks.number_of_hits(i_ut_track) + velo_tracks.number_of_hits(i_velo_track);
      uint begin = hits_bank.addSeq(n_hits);
      const SciFi::Consolidated::Hits scifi_hits =
        scifi_tracks.get_hits(dev_scifi_consolidated_hits, i_track, &scifi_geometry, dev_inv_clus_res);
      const UT::Consolidated::Hits ut_hits =
        ut_tracks.get_hits(dev_ut_consolidated_hits, i_ut_track);
      const Velo::Consolidated::Hits velo_hits =
        velo_tracks.get_hits((char*) dev_velo_track_hits, i_velo_track);

      // Add the velo hits.
      // NB: these are stored in backwards order.
      uint i_hit = 0;
      for (uint i_velo_hit = 0; i_velo_hit < velo_tracks.number_of_hits(i_velo_track); i_velo_hit++) {
        hits_bank.m_location[begin + i_hit] =
          velo_hits.LHCbID[velo_tracks.number_of_hits(i_velo_track) - 1 - i_velo_hit];
        i_hit++;
      }
      // Add UT hits.
      for (uint i_ut_hit = 0; i_ut_hit < ut_tracks.number_of_hits(i_ut_track); i_ut_hit++) {
        hits_bank.m_location[begin + i_hit] = ut_hits.LHCbID[i_ut_hit];
        i_hit++;
      }
      // Add SciFi hits.
      for (uint i_scifi_hit = 0; i_scifi_hit < scifi_tracks.number_of_hits(i_track); i_scifi_hit++) {
        hits_bank.m_location[begin + i_hit] = scifi_hits.LHCbID(i_scifi_hit);
        i_hit++;
      }
    }

    // Add secondary vertices to the hits StdInfo. CLID = 10030.
    for (uint i_saved_sv = 0; i_saved_sv < dev_n_svs_saved[event_number]; i_saved_sv++) {
      uint i_sv = event_saved_svs_list[i_saved_sv];

      // Add to Substr.
      int i_track = event_svs[i_sv].trk1;
      int j_track = event_svs[i_sv].trk2;
      // Two substructures, pointers to objects.
      substr_bank.addSubstr(2, 0);
      substr_bank.addPtr(n_decisions + event_save_track[i_track]);
      substr_bank.addPtr(n_decisions + event_save_track[j_track]);

      // Add to StdInfo.
      if (writeStdInfo) {
        stdinfo_bank.addObj(Hlt1::nStdInfoSV);
        stdinfo_bank.addInfo(event_svs[i_sv].x);
        stdinfo_bank.addInfo(event_svs[i_sv].y);
        stdinfo_bank.addInfo(event_svs[i_sv].z);
      }
    }

    // Get the sizes of the banks.
    objtyp_bank.saveSize();
    substr_bank.saveSize();
    stdinfo_bank.saveSize();
    uint selrep_size = HltSelRepRawBank::Header::kHeaderSize +
      hits_bank.size() +
      objtyp_bank.size() +
      substr_bank.size() +
      writeStdInfo * stdinfo_bank.size();
    dev_sel_rep_offsets[n_pass] = selrep_size;
  }
  __syncthreads();
  
}
