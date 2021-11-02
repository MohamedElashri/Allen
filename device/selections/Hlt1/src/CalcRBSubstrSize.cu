/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "CalcRBSubstrSize.cuh"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(calc_rb_substr_size::calc_rb_substr_size_t)

void calc_rb_substr_size::calc_rb_substr_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_sel_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_substr_sel_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_substr_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_stdinfo_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_objtyp_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_list_t>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
}

void calc_rb_substr_size::calc_rb_substr_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_sel_count_t>(arguments, 0, context);
  initialize<dev_substr_bank_size_t>(arguments, 0, context);
  initialize<dev_substr_sel_size_t>(arguments, 0, context);
  initialize<dev_stdinfo_bank_size_t>(arguments, 0, context);
  global_function(calc_size)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void calc_rb_substr_size::calc_size(calc_rb_substr_size::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const uint32_t* event_dec_reports =
    parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_number;
  const unsigned* event_candidate_count =
    parameters.dev_candidate_count + event_number * parameters.dev_number_of_active_lines[0];
  unsigned* event_sel_list = parameters.dev_sel_list + event_number * parameters.dev_number_of_active_lines[0];

  for (unsigned line_index = threadIdx.x; line_index < parameters.dev_number_of_active_lines[0];
       line_index += blockDim.x) {
    HltDecReport dec_report;
    dec_report.setDecReport(event_dec_reports[2 + line_index]);
    if (dec_report.getDecision()) {
      atomicAdd(parameters.dev_substr_bank_size + event_number, 1 + event_candidate_count[line_index]);
      atomicAdd(parameters.dev_substr_sel_size + event_number, 1 + event_candidate_count[line_index]);
      unsigned insert_index = atomicAdd(parameters.dev_sel_count + event_number, 1);
      event_sel_list[insert_index] = line_index;
    }
  }

  __syncthreads();

  if (threadIdx.x == 0) {

    // Get the size of the substructure bank.
    if (parameters.dev_sel_track_count[event_number] > 0) {
      // Each track substructure consists of 1 short that denotes the
      // size and 1 short pointer to hits in the hits bank.
      parameters.dev_substr_bank_size[event_number] += 2 * parameters.dev_sel_track_count[event_number];
      // Each SV substructure consists of 1 short that gives the size
      // and 2 shorts pointing to track substructures.
      parameters.dev_substr_bank_size[event_number] += 3 * parameters.dev_sel_sv_count[event_number];
    }

    // Get the size of the ObjTyp bank. The ObjTyp bank has 1 word defining the
    // bank structure and 1 word for each object type stored.
    parameters.dev_objtyp_bank_size[event_number] = 1 + (parameters.dev_sel_count[event_number] > 0) +
                                                    (parameters.dev_sel_track_count[event_number] > 0) +
                                                    (parameters.dev_sel_sv_count[event_number] > 0);

    // Convert from number of shorts to number of words. Add 2 shorts for bank size info.
    if (parameters.dev_substr_bank_size[event_number] > 0) {
      parameters.dev_substr_bank_size[event_number] = (parameters.dev_substr_bank_size[event_number] + 3) / 2;
    }

    // Get the size of the StdInfo bank.
    const unsigned n_objects = parameters.dev_sel_count[event_number] + parameters.dev_sel_track_count[event_number] +
                               parameters.dev_sel_sv_count[event_number];

    // StdInfo contains 1 word giving the structure of the bank, 8
    // bits per object with the number of values saved (with possible
    // padding). Saved info includes:
    // Selections: decision ID
    // Tracks: empty
    // SVs: empty
    if (n_objects > 0) {
      parameters.dev_stdinfo_bank_size[event_number] = 2 + n_objects / 4 + parameters.dev_sel_count[event_number] +
                                                       8 * parameters.dev_sel_track_count[event_number] +
                                                       4 * parameters.dev_sel_sv_count[event_number];
    }
    else {
      parameters.dev_stdinfo_bank_size[event_number] = 0;
    }
  }
}
