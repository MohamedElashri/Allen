/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeRBSubstr.cuh"
#include "HltDecReport.cuh"
#include "SelectionsEventModel.cuh"
#include "LHCbIDContainer.cuh"
#include "VertexDefinitions.cuh"

INSTANTIATE_ALGORITHM(make_rb_substr::make_rb_substr_t)

void make_rb_substr::make_rb_substr_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_rb_substr_t>(arguments, first<host_substr_bank_size_t>(arguments));
}

void make_rb_substr::make_rb_substr_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_rb_substr_t>(arguments, 0, context);
  global_function(make_substr_bank)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void make_rb_substr::make_substr_bank(make_rb_substr::Parameters parameters, const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {

    unsigned* event_rb_substr = parameters.dev_rb_substr + parameters.dev_rb_substr_offsets[event_number];
    const unsigned event_rb_substr_size =
      parameters.dev_rb_substr_offsets[event_number + 1] - parameters.dev_rb_substr_offsets[event_number];
    const Selections::CandidateTable sv_table = parameters.dev_sel_sv_tables[event_number];
    const unsigned sv_idx_offset = 10 * VertexFit::max_svs * event_number;
    const unsigned* event_svs_trk1 = parameters.dev_svs_trk1_idx + sv_idx_offset;
    const unsigned* event_svs_trk2 = parameters.dev_svs_trk2_idx + sv_idx_offset;
    const Selections::CandidateTable track_table = parameters.dev_sel_track_tables[event_number];
    const unsigned n_tracks = track_table.n_candidates();
    const unsigned n_svs = sv_table.n_candidates();
    const unsigned n_sels = parameters.dev_sel_count[event_number];

    const unsigned sels_start_short = 2;
    const unsigned svs_start_short = sels_start_short + parameters.dev_substr_sel_size[event_number];
    const unsigned tracks_start_short = svs_start_short + 3 * sv_table.n_candidates();

    // Skip empty banks.
    if (event_rb_substr_size == 0) continue;

    // Add the track substructures.
    // Each track substructure has one pointer to a sequence of LHCbIDs.
    unsigned track_struct = ((1 & 0xFFFF) << 1) | 1;
    for (unsigned i_track = 0; i_track < n_tracks; i_track++) {
      const unsigned i_short = tracks_start_short + 2 * i_track;
      const unsigned i_word = i_short / 2;
      const unsigned i_part = i_short % 2;
      const unsigned mask = 0xFFFFL;
      const unsigned bits = 16;

      if (i_part == 0) {
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | track_struct;
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~(mask << bits)) | (i_track << bits);
      }
      else {
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~(mask << bits)) | (track_struct << bits);
        event_rb_substr[i_word + 1] = (event_rb_substr[i_word + 1] & ~mask) | i_track;
      }
    }

    // Add the SV substructures.
    // Each SV substructure has two pointers to tracks.
    unsigned sv_struct = ((2 & 0xFFFF) << 1) | 0;
    for (unsigned i_sv = 0; i_sv < n_svs; i_sv++) {
      const unsigned i_short = svs_start_short + 3 * i_sv;
      const unsigned i_word = i_short / 2;
      const unsigned i_part = i_short % 2;
      const unsigned mask = 0xFFFFL;
      const unsigned bits = 16;

      unsigned sv_index = sv_table.get_index_from_insert(i_sv);
      unsigned trk1_index = event_svs_trk1[sv_index];
      unsigned trk2_index = event_svs_trk2[sv_index];
      unsigned seq1_loc = n_sels + n_svs + track_table.get_insert_from_index(trk1_index);
      unsigned seq2_loc = n_sels + n_svs + track_table.get_insert_from_index(trk2_index);
      if (i_part == 0) {
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | sv_struct;
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~(mask << bits)) | (seq1_loc << bits);
        event_rb_substr[i_word + 1] = (event_rb_substr[i_word + 1] & ~mask) | seq2_loc;
      }
      else {
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~(mask << bits)) | (sv_struct << bits);
        event_rb_substr[i_word + 1] = (event_rb_substr[i_word + 1] & ~mask) | seq1_loc;
        event_rb_substr[i_word + 1] = (event_rb_substr[i_word + 1] & ~(mask << bits)) | (seq2_loc << bits);
      }
    }

    // Set the bank size here.
    event_rb_substr[0] = (event_rb_substr[0] & ~0xFFFFL) | (unsigned) (n_sels + n_svs + n_tracks);
    event_rb_substr[0] = (event_rb_substr[0] & ~(0xFFFL << 16)) | (unsigned) (event_rb_substr_size << 16);

    const unsigned* event_candidate_offsets =
      parameters.dev_candidate_offsets + event_number * parameters.dev_number_of_active_lines[0];
    const unsigned* event_sel_list = parameters.dev_sel_list + event_number * parameters.dev_number_of_active_lines[0];

    Selections::ConstSelections selections {
      parameters.dev_selections, parameters.dev_selections_offsets, number_of_events};

    unsigned insert_short =
      sels_start_short; // + line_index + event_candidate_offsets[line_index] - event_candidate_offsets[0];

    for (unsigned i_line = 0; i_line < n_sels; i_line += 1) {
      unsigned line_id = event_sel_list[i_line];
      uint8_t sel_type = parameters.dev_lhcbid_containers[line_id];

      // If the line does not select tracks or SVs, it contains 0
      // pointers to object-type substrcutures.
      if (sel_type == to_integral(LHCbIDContainer::none)) {
        unsigned i_word = insert_short / 2;
        unsigned i_part = insert_short % 2;
        unsigned bits = 16 * i_part;
        unsigned mask = 0xFFFFL << bits;
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | (0 << bits);
        insert_short++;
      }

      // Handle lines that select tracks.
      if (sel_type == to_integral(LHCbIDContainer::track)) {
        unsigned n_cand = event_candidate_offsets[line_id + 1] - event_candidate_offsets[line_id];
        unsigned i_word = insert_short / 2;
        unsigned i_part = insert_short % 2;
        unsigned bits = 16 * i_part;
        unsigned mask = 0xFFFFL << bits;
        unsigned sel_struct = ((n_cand & 0xFFFF) << 1) | 0;
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | (sel_struct << bits);
        insert_short++;
        auto decs = selections.get_span(line_id, event_number);
        for (unsigned i_track = 0; i_track < n_tracks; i_track++) {
          unsigned track_index = track_table.get_index_from_insert(i_track);
          unsigned obj_index = n_sels + n_svs + i_track;
          if (decs[track_index]) {
            unsigned i_word = insert_short / 2;
            unsigned i_part = insert_short % 2;
            unsigned bits = 16 * i_part;
            unsigned mask = 0xFFFFL << bits;
            event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | (obj_index << bits);
            insert_short++;
          }
        }
      }

      // Handle lines that select SVs.
      if (sel_type == to_integral(LHCbIDContainer::sv)) {
        unsigned n_cand = event_candidate_offsets[line_id + 1] - event_candidate_offsets[line_id];
        unsigned i_word = insert_short / 2;
        unsigned i_part = insert_short % 2;
        unsigned bits = 16 * i_part;
        unsigned mask = 0xFFFFL << bits;
        unsigned sel_struct = ((n_cand & 0xFFFF) << 1) | 0;
        event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | (sel_struct << bits);
        insert_short++;
        auto decs = selections.get_span(line_id, event_number);
        for (unsigned i_sv = 0; i_sv < n_svs; i_sv++) {
          unsigned sv_index = sv_table.get_index_from_insert(i_sv);
          unsigned obj_index = n_sels + i_sv;
          if (decs[sv_index]) {
            unsigned i_word = insert_short / 2;
            unsigned i_part = insert_short % 2;
            unsigned bits = 16 * i_part;
            unsigned mask = 0xFFFFL << bits;
            event_rb_substr[i_word] = (event_rb_substr[i_word] & ~mask) | (obj_index << bits);
            insert_short++;
          }
        }
      }
    }
  }
}