/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "MakeSelRep.cuh"

INSTANTIATE_ALGORITHM(make_selrep::make_selrep_t)

void make_selrep::make_selrep_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<host_selrep_offsets_t>(arguments, size<dev_selrep_offsets_t>(arguments));
  set_size<host_sel_reports_t>(arguments, first<host_selrep_size_t>(arguments));
  set_size<dev_sel_reports_t>(arguments, first<host_selrep_size_t>(arguments));
}

void make_selrep::make_selrep_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // Initialization might not be necessary.
  Allen::memset_async<dev_sel_reports_t>(arguments, 0, context);
  global_function(make_selrep::make_selrep)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments, first<host_number_of_events_t>(arguments));

  Allen::copy_async<host_selrep_offsets_t, dev_selrep_offsets_t>(arguments, context);
  Allen::copy_async<host_sel_reports_t, dev_sel_reports_t>(arguments, context);
  Allen::synchronize(context);
}

__host__ __device__ void make_selrep::make_selrep_bank(
  unsigned* selrep,
  const unsigned* rb_objtyp,
  const unsigned* rb_hits,
  const unsigned* rb_substr,
  const unsigned* rb_stdinfo,
  const unsigned bank_size,
  const unsigned objtyp_size,
  const unsigned hits_size,
  const unsigned substr_size,
  const unsigned stdinfo_size)
{
  const unsigned header_size = 10;
  selrep[0] = bank_size;
  // First 3 bits holds number of subbanks. For now this is fixed to 4.
  unsigned mask = 0x7L;
  unsigned bits = 3;
  unsigned n_banks = 0;
  unsigned size_iter = header_size;

  // First subbank is objtyp = 1.
  if (objtyp_size > 0) {
    n_banks++;
    selrep[1] = (selrep[1] & ~(mask << (n_banks * bits))) | (1 << (n_banks * bits));
    selrep[1 + n_banks] = size_iter + objtyp_size;
    memcpy(selrep + size_iter, rb_objtyp, objtyp_size * sizeof(unsigned));
    size_iter += objtyp_size;
  }
  // Second subbank is substr = 2.
  if (substr_size > 0) {
    n_banks++;
    selrep[1] = (selrep[1] & ~(mask << (n_banks * bits))) | (2 << (n_banks * bits));
    selrep[1 + n_banks] = size_iter + substr_size;
    memcpy(selrep + size_iter, rb_substr, substr_size * sizeof(unsigned));
    size_iter += substr_size;
  }
  // ExtraInfo subbank is substr = 3. Not filled, but minimal sub bank must be present
  // The minimal bank must house as many objects as there are in the
  // objtyp bank, which can all be empty.
  {
    n_banks++;
    selrep[1] = (selrep[1] & ~(mask << (n_banks * bits))) | (3 << (n_banks * bits));
    // Calculate the size of the empty extraInfo sub-bank from the number of objects
    const unsigned short n_objtyp = rb_objtyp[0] & 0xFFFFL;
    const unsigned n_obj = rb_objtyp[n_objtyp] & 0xFFFFL;
    const unsigned rb_einfo_size = 2 + n_obj / 4;
    selrep[1 + n_banks] = size_iter + rb_einfo_size;

    // Build the empty extraInfo bank
    // Size of the bank in the high 16 bits, number of objects in the low 16 bits
    (selrep + size_iter)[0] = (rb_einfo_size << 16) | n_obj;
    // Extra info size is stored in 8 bits pieces per object, write
    // as many empty words as needed (with padding)
    for (unsigned i_word = 1; i_word < 2 + n_obj / 4; ++i_word) {
      (selrep + size_iter)[i_word] = 0;
    }
    size_iter += rb_einfo_size;
  }
  // Third subbank is StdInfo = 4.
  if (stdinfo_size > 0) {
    n_banks++;
    selrep[1] = (selrep[1] & ~(mask << (n_banks * bits))) | (4 << (n_banks * bits));
    selrep[1 + n_banks] = size_iter + stdinfo_size;
    memcpy(selrep + size_iter, rb_stdinfo, stdinfo_size * sizeof(unsigned));
    size_iter += stdinfo_size;
  }
  // Put hits at the end because it doesn't always exist. Subbank ID = 0.
  if (hits_size > 0) {
    n_banks++;
    selrep[1] = (selrep[1] & ~(mask << (n_banks * bits))) | (0 << (n_banks * bits));
    selrep[1 + n_banks] = size_iter + hits_size;
    memcpy(selrep + size_iter, rb_hits, hits_size * sizeof(unsigned));
    size_iter += hits_size;
  }
  selrep[1] = (selrep[1] & ~mask) | n_banks;
}

__global__ void make_selrep::make_selrep(make_selrep::Parameters parameters, const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const unsigned bank_offset = parameters.dev_selrep_offsets[event_number];
    const unsigned objtyp_offset = parameters.dev_rb_objtyp_offsets[event_number];
    const unsigned hits_offset = parameters.dev_rb_hits_offsets[event_number];
    const unsigned substr_offset = parameters.dev_rb_substr_offsets[event_number];
    const unsigned stdinfo_offset = parameters.dev_rb_stdinfo_offsets[event_number];
    const unsigned bank_size = parameters.dev_selrep_offsets[event_number + 1] - bank_offset;
    const unsigned objtyp_size = parameters.dev_rb_objtyp_offsets[event_number + 1] - objtyp_offset;
    const unsigned hits_size = parameters.dev_rb_hits_offsets[event_number + 1] - hits_offset;
    const unsigned substr_size = parameters.dev_rb_substr_offsets[event_number + 1] - substr_offset;
    const unsigned stdinfo_size = parameters.dev_rb_stdinfo_offsets[event_number + 1] - stdinfo_offset;
    const unsigned* event_rb_objtyp = parameters.dev_rb_objtyp + objtyp_offset;
    const unsigned* event_rb_hits = parameters.dev_rb_hits + hits_offset;
    const unsigned* event_rb_substr = parameters.dev_rb_substr + substr_offset;
    const unsigned* event_rb_stdinfo = parameters.dev_rb_stdinfo + stdinfo_offset;

    // Make the bank header.
    unsigned* event_selrep = parameters.dev_sel_reports + bank_offset;

    make_selrep_bank(
      event_selrep,
      event_rb_objtyp,
      event_rb_hits,
      event_rb_substr,
      event_rb_stdinfo,
      bank_size,
      objtyp_size,
      hits_size,
      substr_size,
      stdinfo_size);
  }
}
