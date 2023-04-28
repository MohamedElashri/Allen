/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CalcLumiSumSize.cuh"
#include "SelectionsEventModel.cuh"

#include "LumiDefinitions.cuh"

INSTANTIATE_ALGORITHM(calc_lumi_sum_size::calc_lumi_sum_size_t)

void calc_lumi_sum_size::calc_lumi_sum_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_lumi_sum_sizes_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_lumi_sum_present_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calc_lumi_sum_size::calc_lumi_sum_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_lumi_sum_sizes_t>(arguments, 0, context);
  Allen::memset_async<dev_lumi_sum_present_t>(arguments, 0, context);

  global_function(calc_lumi_sum_size)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void calc_lumi_sum_size::calc_lumi_sum_size(
  calc_lumi_sum_size::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    // read decision from line
    Selections::ConstSelections selections {
      parameters.dev_selections, parameters.dev_selections_offsets, number_of_events};

    const auto sel_span = selections.get_span(parameters.line_index, event_number);
    const auto sel_span_full = selections.get_span(parameters.line_index_full, event_number);

    if (!sel_span_full.empty() && sel_span_full[0] && parameters.line_index_full != parameters.line_index) {
      // if the 1 kHz line passes then use the full summary length
      // if the same line index is passed for both lines then the 1 kHz line is not in use
      parameters.dev_lumi_sum_sizes[event_number] = parameters.lumi_sum_length_full;
    }
    else if (!sel_span.empty() && sel_span[0]) {
      // if only the 30 kHz line passes then use the reduced summary length
      parameters.dev_lumi_sum_sizes[event_number] = parameters.lumi_sum_length;
    }
    else {
      // skip non-lumi event
      continue;
    }

    parameters.dev_lumi_sum_present[event_number] = 1u;
  }
}
