/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeRBObjTyp.cuh"

void make_rb_objtyp::make_rb_objtyp_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // Each bank contains 1 + n_objtyps = 4 words.
  set_size<dev_rb_objtyp_t>(arguments, 4 * first<host_number_of_events_t>(arguments));
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
  const unsigned n_objtyps = 3;
  const unsigned bank_size = 1 + n_objtyps;
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const unsigned n_sels = parameters.dev_sel_count[event_number];
    const unsigned n_svs = parameters.dev_sel_sv_count[event_number];
    const unsigned n_tracks = parameters.dev_sel_track_count[event_number];
    unsigned* event_rb_objtyp = parameters.dev_rb_objtyp + bank_size * event_number;
    const unsigned mask = 0xFFFFL;
    const unsigned bits = 16;
    // Bank size.
    event_rb_objtyp[0] = (event_rb_objtyp[0] & ~mask) | n_objtyps;
    event_rb_objtyp[0] = (event_rb_objtyp[0] & ~(mask << bits)) | (bank_size << bits);
    // Selections.
    // Not sure if the CLID is correct.
    unsigned short CLID = 1;
    event_rb_objtyp[1] = (event_rb_objtyp[1] & ~mask) | n_sels;
    event_rb_objtyp[1] = (event_rb_objtyp[1] & ~(mask << bits)) | (CLID << bits);
    // SVs.
    CLID = 10030;
    event_rb_objtyp[2] = (event_rb_objtyp[2] & ~mask) | (n_sels + n_svs);
    event_rb_objtyp[2] = (event_rb_objtyp[2] & ~(mask << bits)) | (CLID << bits);
    // Tracks.
    CLID = 10010;
    event_rb_objtyp[3] = (event_rb_objtyp[3] & ~mask) | (n_sels + n_svs + n_tracks);
    event_rb_objtyp[3] = (event_rb_objtyp[3] & ~(mask << bits)) | (CLID << bits);
  }
}