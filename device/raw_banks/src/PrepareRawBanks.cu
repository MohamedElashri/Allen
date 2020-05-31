/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PrepareRawBanks.cuh"
#include "DeviceLineTraverser.cuh"

void prepare_raw_banks::prepare_raw_banks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto total_number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  const auto padding_size = 3 * first<host_number_of_events_t>(arguments);
  const auto hits_size =
    ParKalmanFilter::nMaxMeasurements * first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  set_size<dev_sel_rb_hits_t>(arguments, hits_size + padding_size);
  set_size<dev_sel_rb_stdinfo_t>(arguments, total_number_of_events * Hlt1::maxStdInfoEvent);
  set_size<dev_sel_rb_objtyp_t>(arguments, total_number_of_events * (Hlt1::nObjTyp + 1));
  set_size<dev_sel_rb_substr_t>(arguments, total_number_of_events * Hlt1::subStrDefaultAllocationSize);
  set_size<dev_sel_rep_sizes_t>(arguments, total_number_of_events);
  set_size<dev_passing_event_list_t>(arguments, total_number_of_events);

  const auto n_hlt1_lines = std::tuple_size<configured_lines_t>::value;
  set_size<dev_dec_reports_t>(arguments, (2 + n_hlt1_lines) * total_number_of_events);

  // This is not technically enough to save every single track, but
  // should be more than enough in practice.
  // TODO: Implement some check for this.
  set_size<dev_candidate_lists_t>(arguments, total_number_of_events * Hlt1::maxCandidates * n_hlt1_lines);
  set_size<dev_candidate_counts_t>(arguments, total_number_of_events * n_hlt1_lines);
  set_size<dev_saved_tracks_list_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_saved_svs_list_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_save_track_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_save_sv_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_sel_atomics_t>(arguments, Hlt1::number_of_sel_atomics * total_number_of_events);
}

void prepare_raw_banks::prepare_raw_banks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto total_number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  initialize<dev_sel_rb_hits_t>(arguments, 0, stream);
  initialize<dev_sel_rb_stdinfo_t>(arguments, 0, stream);
  initialize<dev_sel_rb_objtyp_t>(arguments, 0, stream);
  initialize<dev_sel_rb_substr_t>(arguments, 0, stream);
  initialize<dev_sel_rep_sizes_t>(arguments, 0, stream);
  initialize<dev_passing_event_list_t>(arguments, 0, stream);
  initialize<dev_candidate_lists_t>(arguments, 0, stream);
  initialize<dev_candidate_counts_t>(arguments, 0, stream);
  initialize<dev_dec_reports_t>(arguments, 0, stream);
  initialize<dev_save_track_t>(arguments, -1, stream);
  initialize<dev_save_sv_t>(arguments, -1, stream);
  initialize<dev_sel_atomics_t>(arguments, 0, stream);

#ifdef CPU
  const unsigned grid_dim = 1;
  const unsigned block_dim = 1;
#else
  unsigned grid_dim =
    (first<host_number_of_events_t>(arguments) + property<block_dim_x_t>() - 1) / property<block_dim_x_t>();
  if (grid_dim == 0) {
    grid_dim = 1;
  }
  const unsigned block_dim = property<block_dim_x_t>().get();
#endif

  global_function(prepare_decisions)(dim3(grid_dim), dim3(block_dim), stream)(
    arguments, first<host_number_of_events_t>(arguments), event_start);

  global_function(prepare_raw_banks)(dim3(grid_dim), dim3(block_dim), stream)(
    arguments, first<host_number_of_events_t>(arguments), total_number_of_events, event_start);

  // Copy raw bank data.
  assign_to_host_buffer<dev_dec_reports_t>(host_buffers.host_dec_reports, arguments, stream);
  assign_to_host_buffer<dev_passing_event_list_t>(host_buffers.host_passing_event_list, arguments, stream);
}

__global__ void prepare_raw_banks::prepare_raw_banks(
  prepare_raw_banks::Parameters parameters,
  const unsigned selected_number_of_events,
  const unsigned total_number_of_events,
  const unsigned event_start)
{
  // Handle special lines for events that don't pass the GEC.
  for (unsigned selected_event_number = selected_number_of_events + blockIdx.x * blockDim.x + threadIdx.x;
       selected_event_number < total_number_of_events;
       selected_event_number += blockDim.x * gridDim.x) {
    const unsigned event_number = parameters.dev_event_list[selected_event_number] - event_start;
    const int n_hlt1_lines = std::tuple_size<configured_lines_t>::value;
    uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;

    // Set the DecReport.
    uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_hlt1_lines) * event_number;
    // Continue if event has not passed any selections.
    bool pass = false;
    for (int i_line = 0; i_line < n_hlt1_lines; i_line++) {
      pass = pass || ((event_dec_reports[2 + i_line] & dec_mask) == (1 & dec_mask));
      if (pass) {
        break;
      }
    }
    if (!pass) continue;

    // Set the rest of the DecReport.
    event_dec_reports[0] = Hlt1::TCK;
    event_dec_reports[1] = Hlt1::taskID;
    unsigned n_decisions = 0;
    
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::Line>::traverse([&](const unsigned long i_line) {
      HltDecReport dr;
      dr.setDecision(false);
      dr.setErrorBits(0);
      dr.setNumberOfCandidates(0);
      dr.setIntDecisionID(i_line);
      event_dec_reports[2 + i_line] |= dr.getDecReport();
      if (event_dec_reports[2 + i_line] & dec_mask) {
        n_decisions++;
      }
    });

    // TODO: Handle SelReports.
    const unsigned event_sel_rb_stdinfo_offset = event_number * Hlt1::maxStdInfoEvent;
    unsigned* event_sel_rb_stdinfo = parameters.dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const unsigned event_sel_rb_objtyp_offset = event_number * (Hlt1::nObjTyp + 1);
    unsigned* event_sel_rb_objtyp = parameters.dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const unsigned event_sel_rb_substr_offset = event_number * Hlt1::subStrDefaultAllocationSize;
    unsigned* event_sel_rb_substr = parameters.dev_sel_rb_substr + event_sel_rb_substr_offset;

    // Populate dev_passing_event_list
    parameters.dev_passing_event_list[event_number] = true;

    // Create the substructure sub-bank.
    // Use default allocation size.
    HltSelRepRBSubstr substr_bank(0, event_sel_rb_substr);

    // Create the standard info sub-bank.
    unsigned nAllInfo = Hlt1::nStdInfoDecision * n_decisions;
    unsigned nObj = n_decisions;
    bool writeStdInfo = nAllInfo < Hlt1::maxStdInfoEvent;
    HltSelRepRBStdInfo stdinfo_bank(nObj, nAllInfo, event_sel_rb_stdinfo);

    // Create the object type sub-bank.
    HltSelRepRBObjTyp objtyp_bank(Hlt1::nObjTyp, event_sel_rb_objtyp);
    objtyp_bank.addObj(Hlt1::selectionCLID, n_decisions);
    // TODO: Check if these are actually necessary.
    objtyp_bank.addObj(Hlt1::trackCLID, 0);
    objtyp_bank.addObj(Hlt1::svCLID, 0);

    // Add special decisions to the substr bank.
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::SpecialLine>::traverse([&](const unsigned int i_line) {
      if (event_dec_reports[2 + i_line] & dec_mask) {
        // Substructure is pointers, but there are no candidates.
        stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
        stdinfo_bank.addInfo(i_line);
        substr_bank.addSubstr(0, 0);
      }
    });

    // Set the sizes of the banks.
    objtyp_bank.saveSize();
    substr_bank.saveSize();
    stdinfo_bank.saveSize();
    unsigned selrep_size = HltSelRepRawBank::Header::kHeaderSize + objtyp_bank.size() + substr_bank.size() +
                       writeStdInfo * stdinfo_bank.size();
    parameters.dev_sel_rep_sizes[event_number] = selrep_size;
  }

  // Handle all lines for events that pass the GEC.
  for (auto selected_event_number = blockIdx.x * blockDim.x + threadIdx.x;
       selected_event_number < selected_number_of_events;
       selected_event_number += blockDim.x * gridDim.x) {
    const unsigned event_number = parameters.dev_event_list[selected_event_number] - event_start;

    // Create velo tracks.
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo,
      parameters.dev_velo_track_hit_number,
      selected_event_number,
      selected_number_of_events};

    // Create UT tracks.
    UT::Consolidated::ConstExtendedTracks ut_tracks {
      parameters.dev_atomics_ut,
      parameters.dev_ut_track_hit_number,
      parameters.dev_ut_qop,
      parameters.dev_ut_track_velo_indices,
      selected_event_number,
      selected_number_of_events};

    // Create SciFi tracks.
    SciFi::Consolidated::ConstTracks scifi_tracks {
      parameters.dev_offsets_forward_tracks,
      parameters.dev_scifi_track_hit_number,
      parameters.dev_scifi_qop,
      parameters.dev_scifi_states,
      parameters.dev_scifi_track_ut_indices,
      selected_event_number,
      selected_number_of_events};

    // Tracks.
    const int* event_save_track = parameters.dev_save_track + scifi_tracks.tracks_offset(selected_event_number);
    const unsigned* event_saved_tracks_list =
      parameters.dev_saved_tracks_list + scifi_tracks.tracks_offset(selected_event_number);
    const ParKalmanFilter::FittedTrack* event_kf_tracks =
      parameters.dev_kf_tracks + scifi_tracks.tracks_offset(selected_event_number);

    // Vertices.
    const int* event_save_sv = parameters.dev_save_sv + parameters.dev_sv_offsets[selected_event_number];
    const unsigned* event_saved_svs_list = parameters.dev_saved_svs_list + parameters.dev_sv_offsets[selected_event_number];
    const VertexFit::TrackMVAVertex* event_svs =
      parameters.dev_consolidated_svs + parameters.dev_sv_offsets[selected_event_number];

    // Dec reports.
    const int n_hlt1_lines = std::tuple_size<configured_lines_t>::value;
    uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_hlt1_lines) * event_number;

    // Sel reports.
    const unsigned event_sel_rb_hits_offset =
      scifi_tracks.tracks_offset(selected_event_number) * ParKalmanFilter::nMaxMeasurements + 3 * selected_event_number;
    unsigned* event_sel_rb_hits = parameters.dev_sel_rb_hits + event_sel_rb_hits_offset;
    const unsigned event_sel_rb_stdinfo_offset = event_number * Hlt1::maxStdInfoEvent;
    unsigned* event_sel_rb_stdinfo = parameters.dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const unsigned event_sel_rb_objtyp_offset = event_number * (Hlt1::nObjTyp + 1);
    unsigned* event_sel_rb_objtyp = parameters.dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const unsigned event_sel_rb_substr_offset = event_number * Hlt1::subStrDefaultAllocationSize;
    unsigned* event_sel_rb_substr = parameters.dev_sel_rb_substr + event_sel_rb_substr_offset;

    // If any line is passed, add to selected events and create the rest of the DecReport.
    uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;

    // Continue if event has not passed any selections.
    bool pass = false;
    for (int i_line = 0; i_line < n_hlt1_lines; i_line++) {
      pass = pass || ((event_dec_reports[2 + i_line] & dec_mask) == (1 & dec_mask));
      if (pass) {
        break;
      }
    }
    if (!pass) continue;

    // Populate dev_passing_event_list
    parameters.dev_passing_event_list[event_number] = true;

    // Create the rest of the dec report.
    event_dec_reports[0] = Hlt1::TCK;
    event_dec_reports[1] = Hlt1::taskID;
    unsigned n_decisions = 0;
    for (int i_line = 0; i_line < n_hlt1_lines; i_line++) {
      HltDecReport dec_report;
      dec_report.setDecision(false);
      // TODO: These are all placeholder values for now.
      dec_report.setErrorBits(0);
      dec_report.setNumberOfCandidates(1);
      dec_report.setIntDecisionID(i_line);
      dec_report.setExecutionStage(1);
      event_dec_reports[2 + i_line] |= dec_report.getDecReport();
      if (event_dec_reports[2 + i_line] & dec_mask) {
        n_decisions++;
      }
    }

    // Create the hits sub-bank.
    HltSelRepRBHits hits_bank(
      parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved],
      parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_hits_saved],
      event_sel_rb_hits);

    // Create the substructure sub-bank.
    // Use default allocation size.
    HltSelRepRBSubstr substr_bank(0, event_sel_rb_substr);

    // Create the standard info sub-bank.
    unsigned nAllInfo =
      Hlt1::nStdInfoDecision * n_decisions +
      Hlt1::nStdInfoTrack *
        (parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved]) +
      Hlt1::nStdInfoSV *
        (parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_svs_saved]);
    unsigned nObj = n_decisions +
                parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved] +
                parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_svs_saved];
    bool writeStdInfo = nAllInfo < Hlt1::maxStdInfoEvent;
    HltSelRepRBStdInfo stdinfo_bank(nObj, nAllInfo, event_sel_rb_stdinfo);

    // Create the object type sub-bank.
    HltSelRepRBObjTyp objtyp_bank(Hlt1::nObjTyp, event_sel_rb_objtyp);
    objtyp_bank.addObj(Hlt1::selectionCLID, n_decisions);
    objtyp_bank.addObj(
      Hlt1::trackCLID,
      parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved]);
    objtyp_bank.addObj(
      Hlt1::svCLID,
      parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_svs_saved]);

    // Note: This was moved because it needs to be in the same order
    // as the lines in the substr
    // Add decision summaries to the StdInfo subbank. CLID = 1.
    // if (writeStdInfo) {
    //   for (unsigned i_line = 0; i_line < n_hlt1_lines; i_line++) {
    //     if (event_dec_reports[2 + i_line] & dec_mask) {
    //       stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
    //       stdinfo_bank.addInfo(i_line);
    //     }
    //   }
    // }

    // Add one-track decisions to the substr and stdinfo.
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::OneTrackLine>::traverse([&](const unsigned int i_line) {
      const unsigned* candidate_counts = parameters.dev_candidate_counts + i_line * total_number_of_events + event_number;
      const unsigned* candidate_list =
        parameters.dev_candidate_lists + (i_line * total_number_of_events + event_number) * Hlt1::maxCandidates;
      // Substructure is pointers to candidates.
      if (event_dec_reports[2 + i_line] & dec_mask) {
        stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
        stdinfo_bank.addInfo(i_line);
        substr_bank.addSubstr(candidate_counts[0], 0);
        for (unsigned i_sub = 0; i_sub < candidate_counts[0]; i_sub++) {
          substr_bank.addPtr(n_decisions + event_save_track[candidate_list[i_sub]]);
        }
      }
    });

    // Add two-track decisions to the substr and stdinfo.
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::TwoTrackLine>::traverse([&](const unsigned int i_line) {
      const unsigned* candidate_counts = parameters.dev_candidate_counts + i_line * total_number_of_events + event_number;
      const unsigned* candidate_list =
        parameters.dev_candidate_lists + (i_line * total_number_of_events + event_number) * Hlt1::maxCandidates;
      if (event_dec_reports[2 + i_line] & dec_mask) {
        stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
        stdinfo_bank.addInfo(i_line);
        substr_bank.addSubstr(candidate_counts[0], 0);
        for (unsigned i_sub = 0; i_sub < candidate_counts[0]; i_sub++) {
          substr_bank.addPtr(n_decisions + event_save_sv[candidate_list[i_sub]]);
        }
      }
    });

    // Add special decisions to substr and stdinfo.
    // Can use this lambda for both the VELO and special lines.
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::VeloLine>::traverse([&](const unsigned int i_line) {
      if (event_dec_reports[2 + i_line] & dec_mask) {
        stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
        stdinfo_bank.addInfo(i_line);
        substr_bank.addSubstr(0, 0);
      }
    });
    
    Hlt1::DeviceTraverseLines<configured_lines_t, Hlt1::SpecialLine>::traverse([&](const unsigned int i_line) {
      if (event_dec_reports[2 + i_line] & dec_mask) {
        stdinfo_bank.addObj(Hlt1::nStdInfoDecision);
        stdinfo_bank.addInfo(i_line);
        substr_bank.addSubstr(0, 0);
      }
    });

    // Add tracks to the hits subbank and to the StdInfo. CLID = 10010.
    // TODO: dev_n_tracks_saved was 0s at the beginning! ./Allen -m3
    for (unsigned i_saved_track = 0;
         i_saved_track <
         parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved];
         i_saved_track++) {
      unsigned i_track = event_saved_tracks_list[i_saved_track];
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
      const int i_ut_track = scifi_tracks.ut_track(i_track);
      const int i_velo_track = ut_tracks.velo_track(i_ut_track);
      const unsigned n_hits = scifi_tracks.number_of_hits(i_track) + ut_tracks.number_of_hits(i_ut_track) +
                          velo_tracks.number_of_hits(i_velo_track);
      unsigned begin = hits_bank.addSeq(n_hits);
      SciFi::Consolidated::ConstHits scifi_hits = scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i_track);
      UT::Consolidated::ConstHits ut_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i_ut_track);
      Velo::Consolidated::ConstHits velo_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits, i_velo_track);

      // Add the velo hits.
      // NB: these are stored in backwards order.
      unsigned i_hit = 0;
      for (unsigned i_velo_hit = 0; i_velo_hit < velo_tracks.number_of_hits(i_velo_track); i_velo_hit++) {
        hits_bank.m_location[begin + i_hit] = velo_hits.id(velo_tracks.number_of_hits(i_velo_track) - 1 - i_velo_hit);
        i_hit++;
      }
      // Add UT hits.
      for (unsigned i_ut_hit = 0; i_ut_hit < ut_tracks.number_of_hits(i_ut_track); i_ut_hit++) {
        hits_bank.m_location[begin + i_hit] = ut_hits.id(i_ut_hit);
        i_hit++;
      }
      // Add SciFi hits.
      for (unsigned i_scifi_hit = 0; i_scifi_hit < scifi_tracks.number_of_hits(i_track); i_scifi_hit++) {
        hits_bank.m_location[begin + i_hit] = scifi_hits.id(i_scifi_hit);
        i_hit++;
      }
    }

    // Add secondary vertices to the hits StdInfo. CLID = 10030.
    for (unsigned i_saved_sv = 0;
         i_saved_sv <
         parameters.dev_sel_atomics[event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_svs_saved];
         i_saved_sv++) {
      unsigned i_sv = event_saved_svs_list[i_saved_sv];

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
    unsigned selrep_size = HltSelRepRawBank::Header::kHeaderSize + hits_bank.size() + objtyp_bank.size() +
                       substr_bank.size() + writeStdInfo * stdinfo_bank.size();
    parameters.dev_sel_rep_sizes[event_number] = selrep_size;
  }
}
