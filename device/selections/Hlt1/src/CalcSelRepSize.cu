/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "CalcSelRepSize.cuh"

void calc_selrep_size::calc_selrep_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_selrep_sizes_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calc_selrep_size::calc_selrep_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_selrep_sizes_t>(arguments, 0, context);
  global_function(calc_size)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void calc_selrep_size::calc_size(calc_selrep_size::Parameters parameters, const unsigned number_of_events)
{
  const unsigned header_size = 10;
  const unsigned objtyp_size = 4;
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const unsigned hits_size =
      parameters.dev_rb_hits_offsets[event_number + 1] - parameters.dev_rb_hits_offsets[event_number];
    const unsigned substr_size =
      parameters.dev_rb_substr_offsets[event_number + 1] - parameters.dev_rb_substr_offsets[event_number];
    const unsigned stdinfo_size =
      parameters.dev_rb_stdinfo_offsets[event_number + 1] - parameters.dev_rb_stdinfo_offsets[event_number];

    // Size of (empty) extraInfo sub-bank depends on the number of objects
    const unsigned objtyp_offset = objtyp_size * event_number;
    const unsigned* event_rb_objtyp = parameters.dev_rb_objtyp + objtyp_offset;
    const unsigned short n_objtyp = event_rb_objtyp[0] & 0xFFFFL;
    const unsigned n_obj = event_rb_objtyp[n_objtyp] & 0xFFFFL;
    const unsigned einfo_size = 2 + n_obj / 4;

    parameters.dev_selrep_sizes[event_number] =
      header_size + hits_size + substr_size + stdinfo_size + objtyp_size + einfo_size;
  }
}
