/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeRBStdInfo.cuh"

void make_rb_stdinfo::make_rb_stdinfo_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_rb_stdinfo_t>(arguments, first<host_stdinfo_bank_size_t>(arguments));
}

void make_rb_stdinfo::make_rb_stdinfo_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_rb_stdinfo_t>(arguments, 0, context);
  global_function(make_stdinfo_bank)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void make_rb_stdinfo::make_stdinfo_bank(
  make_rb_stdinfo::Parameters parameters,
  const unsigned number_of_events)
{

  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {

    unsigned* event_rb_stdinfo = parameters.dev_rb_stdinfo + parameters.dev_rb_stdinfo_bank_offsets[event_number];
    const unsigned event_rb_stdinfo_size =
      parameters.dev_rb_stdinfo_bank_offsets[event_number + 1] - parameters.dev_rb_stdinfo_bank_offsets[event_number];
    const unsigned* event_sel_list = parameters.dev_sel_list + event_number * parameters.dev_number_of_active_lines[0];

    const unsigned n_tracks = parameters.dev_sel_track_count[event_number];
    const unsigned n_svs = parameters.dev_sel_sv_count[event_number];
    const unsigned n_sels = parameters.dev_sel_count[event_number];

    const unsigned sels_start_word = 1 + (3 + n_tracks + n_svs + n_sels) / 4;
    // const unsigned svs_start_word = sels_start_word + n_sels;
    // const unsigned tracks_start_word = svs_start_word + 4 * n_svs;

    // Skip events with an empty StdInfo bank.
    if (event_rb_stdinfo_size == 0) continue;

    // Number of objects stored in the less significant short.
    event_rb_stdinfo[0] = (event_rb_stdinfo[0] & ~0xFFFFu) | ((unsigned) (n_tracks + n_svs + n_sels));
    // Bank size in words in the more significant short.
    event_rb_stdinfo[0] = (event_rb_stdinfo[0] & ~(0xFFFFu << 16)) | ((unsigned) (event_rb_stdinfo_size << 16));

    for (unsigned i_sel = 0; i_sel < n_sels; i_sel++) {
      unsigned i_word = 1 + i_sel / 4;
      unsigned i_part = i_sel % 4;
      unsigned bits = 8 * i_part;
      unsigned mask = 0xFFL << bits;
      unsigned n_info = 1;
      event_rb_stdinfo[i_word] = (event_rb_stdinfo[i_word] & ~mask) | (n_info << bits);

      // Selection IDs must be stored as floats
      i_word = sels_start_word + i_sel;
      float* float_info = reinterpret_cast<float*>(event_rb_stdinfo);
      float_info[i_word] = static_cast<float>(event_sel_list[i_sel] + 1);
    }

    // Add SV information to the beginning of the bank.
    for (unsigned i_sv = 0; i_sv < n_svs; i_sv++) {
      unsigned i_obj = n_sels + i_sv;
      unsigned i_word = 1 + i_obj / 4;
      unsigned i_part = i_obj % 4;
      unsigned bits = 8 * i_part;
      unsigned mask = 0xFFL << bits;
      unsigned n_info = 4;
      event_rb_stdinfo[i_word] = (event_rb_stdinfo[i_word] & ~mask) | (n_info << bits);

      // i_word = svs_start_word + i_sv;
      // event_rb_stdinfo[i_word] = 0;
    }

    // Add track information to the beginning of the bank.
    for (unsigned i_track = 0; i_track < n_tracks; i_track++) {
      unsigned i_obj = n_sels + n_svs + i_track;
      unsigned i_word = 1 + i_obj / 4;
      unsigned i_part = i_obj % 4;
      unsigned bits = 8 * i_part;
      unsigned mask = 0xFFL << bits;
      unsigned n_info = 8;
      event_rb_stdinfo[i_word] = (event_rb_stdinfo[i_word] & ~mask) | (n_info << bits);

      // i_word = tracks_start_word + i_track;
      // event_rb_stdinfo[i_word] = 0;
    }
  }
}
