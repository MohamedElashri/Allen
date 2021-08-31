/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeRBHits.cuh"

void make_rb_hits::make_rb_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_rb_hits_t>(arguments, first<host_total_hits_bank_size_t>(arguments));
}

void make_rb_hits::make_rb_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_rb_hits_t>(arguments, 0, context);
  global_function(make_bank)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void make_rb_hits::make_bank(make_rb_hits::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const Selections::CandidateTable track_table = parameters.dev_sel_track_tables[event_number];

  // Hit "sequence" here refers to the hits associated to a single
  // long track. See
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRBHits.h
  const unsigned n_hit_sequences = track_table.n_candidates();
  const unsigned tracks_offset = parameters.dev_offsets_forward_tracks[event_number];
  const unsigned* event_hits_offsets = parameters.dev_hits_offsets + tracks_offset;
  const unsigned* event_sel_hits_offsets = parameters.dev_sel_hits_offsets + tracks_offset;
  unsigned* event_rb_hits = parameters.dev_rb_hits + parameters.dev_rb_hits_offsets[event_number];
  const unsigned bank_info_size = 1 + (n_hit_sequences / 2);

  for (unsigned i_seq = threadIdx.x; i_seq < n_hit_sequences; i_seq += blockDim.x) {
    const unsigned i_track = track_table.get_index_from_insert(i_seq);
    const unsigned* track_hits = parameters.dev_hits_container + event_hits_offsets[i_track];
    const unsigned n_hits = event_hits_offsets[i_track + 1] - event_hits_offsets[i_track];
    const unsigned seq_start = event_sel_hits_offsets[i_seq] - event_sel_hits_offsets[0] + bank_info_size;
    unsigned* hits_insert_pointer = event_rb_hits + seq_start;

    // Copy the hits for the sequence.
    memcpy(hits_insert_pointer, track_hits, n_hits * sizeof(unsigned));
  }

  __syncthreads();

  if (threadIdx.x == 0) {
    event_rb_hits[0] = (event_rb_hits[0] & ~0xFFFFL) | n_hit_sequences;
    for (unsigned i_seq = 0; i_seq < n_hit_sequences; i_seq++) {
      const unsigned seq_end = event_sel_hits_offsets[i_seq + 1] - event_sel_hits_offsets[0] + bank_info_size;

      // This needs to be done sequentially so two threads don't try
      // to edit the same word at the same time.
      unsigned i_word = (i_seq + 1) / 2;
      unsigned i_part = (i_seq + 1) % 2;
      unsigned bits = i_part * 16;
      unsigned mask = 0xFFFFL << bits;
      event_rb_hits[i_word] = (event_rb_hits[i_word] & ~mask) | (seq_end << bits);
    }
  }
}
