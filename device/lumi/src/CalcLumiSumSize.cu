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
#include "LumiSummaryOffsets.h"

INSTANTIATE_ALGORITHM(calc_lumi_sum_size::calc_lumi_sum_size_t)

void calc_lumi_sum_size::calc_lumi_sum_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_lumi_sum_sizes_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calc_lumi_sum_size::calc_lumi_sum_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_lumi_sum_sizes_t>(arguments, 0, context);

  global_function(calc_lumi_sum_size)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
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
    // skip non-lumi event
    const auto sel_span = selections.get_span(parameters.line_index, event_number);
    if (sel_span.empty() || !sel_span[0]) continue;

    // the unit of LHCb::LumiSummaryOffsets::V2::TotalSize is bit
    // convert it to be unsigned int
    parameters.dev_lumi_sum_sizes[event_number] = Lumi::Constants::lumi_length;
  }
}
