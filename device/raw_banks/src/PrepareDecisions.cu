#include "PrepareRawBanks.cuh"

__global__ void prepare_raw_banks::prepare_decisions(
  prepare_raw_banks::Parameters parameters,
  const uint selected_number_of_events,
  const uint event_start)
{
  const int n_hlt1_lines = std::tuple_size<configured_lines_t>::value;
  const uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;

  // Set special line decisions.
  const auto event_number = blockIdx.x;
  uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_hlt1_lines) * event_number;
  const auto lambda_fn = [&](const unsigned long i_line) {
    const bool* decisions = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + event_number;
    uint32_t dec = ((decisions[0] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + i_line, dec);
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::SpecialLine>::traverse(lambda_fn);

  if (blockIdx.x < selected_number_of_events) {
    const uint selected_event_number = blockIdx.x;
    const uint total_number_of_events = gridDim.x;
    const uint event_number = parameters.dev_event_list[selected_event_number] - event_start;

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
    int* event_save_track = parameters.dev_save_track + scifi_tracks.tracks_offset(selected_event_number);
    const int n_tracks_event = scifi_tracks.number_of_tracks(selected_event_number);
    uint* event_saved_tracks_list =
      parameters.dev_saved_tracks_list + scifi_tracks.tracks_offset(selected_event_number);

    // Vertices.
    int* event_save_sv = parameters.dev_save_sv + parameters.dev_sv_offsets[selected_event_number];
    const uint n_vertices_event =
      parameters.dev_sv_offsets[selected_event_number + 1] - parameters.dev_sv_offsets[selected_event_number];
    uint* event_saved_svs_list = parameters.dev_saved_svs_list + parameters.dev_sv_offsets[selected_event_number];
    const VertexFit::TrackMVAVertex* event_svs =
      parameters.dev_consolidated_svs + parameters.dev_sv_offsets[selected_event_number];

    uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_hlt1_lines) * event_number;

    // Set vertex decisions first.
    uint insert_index = 0;
    for (uint i_sv = threadIdx.x; i_sv < n_vertices_event; i_sv += blockDim.x) {
      uint32_t save_sv = 0;
      const auto lambda_fn = [&](const unsigned long i_line) {
        const bool* decisions = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] +
                                parameters.dev_sv_offsets[selected_event_number];

        uint* candidate_counts = parameters.dev_candidate_counts + i_line * total_number_of_events + event_number;
        uint* candidate_list = parameters.dev_candidate_lists + total_number_of_events * Hlt1::maxCandidates * i_line +
                               event_number * Hlt1::maxCandidates;
        uint32_t dec = ((decisions[i_sv] ? 1 : 0) & dec_mask);
        atomicOr(event_dec_reports + 2 + i_line, dec);
        insert_index = atomicAdd(candidate_counts, dec);
        save_sv |= dec;
        if (dec) {
          candidate_list[insert_index] = i_sv;
        }
      };

      Hlt1::TraverseLines<configured_lines_t, Hlt1::TwoTrackLine>::traverse(lambda_fn);

      if (save_sv & dec_mask) {
        const uint sv_insert_index = atomicAdd(
          parameters.dev_sel_atomics + event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_svs_saved, 1);
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
      const auto lambda_fn = [&](const unsigned long i_line) {
        const bool* decisions = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] +
                                scifi_tracks.tracks_offset(selected_event_number);

        uint* candidate_counts = parameters.dev_candidate_counts + i_line * total_number_of_events + event_number;
        uint* candidate_list = parameters.dev_candidate_lists + total_number_of_events * Hlt1::maxCandidates * i_line +
                               event_number * Hlt1::maxCandidates;
        const uint32_t dec = ((decisions[i_track] ? 1 : 0) & dec_mask);
        atomicOr(event_dec_reports + 2 + i_line, dec);
        insert_index = atomicAdd(candidate_counts, dec);
        save_track |= dec;
        if (dec) {
          candidate_list[insert_index] = i_track;
        }
      };

      Hlt1::TraverseLines<configured_lines_t, Hlt1::OneTrackLine>::traverse(lambda_fn);

      if (save_track) {
        event_save_track[i_track] = 1;
      }
      // Count the number of tracks and hits to save in the SelReport.
      if (event_save_track[i_track] >= 0) {
        const int i_ut_track = scifi_tracks.ut_track(i_track);
        const int i_velo_track = ut_tracks.velo_track(i_ut_track);
        const int n_hits = scifi_tracks.number_of_hits(i_track) + ut_tracks.number_of_hits(i_ut_track) +
                           velo_tracks.number_of_hits(i_velo_track);
        const uint track_insert_index = atomicAdd(
          parameters.dev_sel_atomics + event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_tracks_saved, 1);
        atomicAdd(
          parameters.dev_sel_atomics + event_number * Hlt1::number_of_sel_atomics + Hlt1::atomics::n_hits_saved,
          n_hits);
        event_saved_tracks_list[track_insert_index] = (uint) i_track;
        event_save_track[i_track] = (int) track_insert_index;
      }
    }

    // Set velo line decisions.
    for (uint selected_event_number = blockIdx.x; selected_event_number < selected_number_of_events;
         selected_event_number++) {
      const uint event_number = parameters.dev_event_list[selected_event_number] - event_start;
      uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_hlt1_lines) * event_number;
      const auto lambda_fn = [&](const unsigned long i_line) {
        const bool* decisions =
          parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + selected_event_number;
        uint32_t dec = ((decisions[0] ? 1 : 0) & dec_mask);
        atomicOr(event_dec_reports + 2 + i_line, dec);
      };
      Hlt1::TraverseLines<configured_lines_t, Hlt1::VeloLine>::traverse(lambda_fn);
    }
  }
}