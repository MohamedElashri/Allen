/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeRBObjTyp.cuh"

INSTANTIATE_ALGORITHM(make_rb_objtyp::make_rb_objtyp_t)

void make_rb_objtyp::make_rb_objtyp_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // Each bank contains 1 + n_objtyps = 4 words.
  set_size<dev_rb_objtyp_t>(arguments, first<host_objtyp_banks_size_t>(arguments));
}

void make_rb_objtyp::make_rb_objtyp_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_rb_objtyp_t>(arguments, 0, context);
  global_function(make_objtyp_bank)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void make_rb_objtyp::make_objtyp_bank(make_rb_objtyp::Parameters parameters, const unsigned number_of_events)
{

  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {

    const unsigned bank_offset = parameters.dev_objtyp_offsets[event_number];
    const unsigned bank_size = parameters.dev_objtyp_offsets[event_number + 1] - bank_offset;
    const unsigned n_objtyps = bank_size - 1;
    const unsigned n_sels = parameters.dev_sel_count[event_number];
    const unsigned n_svs = parameters.dev_sel_sv_count[event_number];
    const unsigned n_tracks = parameters.dev_sel_track_count[event_number];
    unsigned* event_rb_objtyp = parameters.dev_rb_objtyp + bank_offset;
    const unsigned mask = 0xFFFFL;
    const unsigned bits = 16;
    unsigned i_obj = 1;
    // Bank size.
    event_rb_objtyp[0] = (event_rb_objtyp[0] & ~mask) | n_objtyps;
    event_rb_objtyp[0] = (event_rb_objtyp[0] & ~(mask << bits)) | (bank_size << bits);
    // Selections.
    if (n_sels > 0) {
      unsigned short CLID = 1;
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~mask) | n_sels;
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~(mask << bits)) | (CLID << bits);
      i_obj++;
    }
    // SVs.
    if (n_svs > 0) {
      unsigned short CLID = 10030;
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~mask) | (n_sels + n_svs);
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~(mask << bits)) | (CLID << bits);
      i_obj++;
    }
    // Tracks.
    if (n_tracks > 0) {
      unsigned short CLID = 10010;
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~mask) | (n_sels + n_svs + n_tracks);
      event_rb_objtyp[i_obj] = (event_rb_objtyp[i_obj] & ~(mask << bits)) | (CLID << bits);
    }
  }
}