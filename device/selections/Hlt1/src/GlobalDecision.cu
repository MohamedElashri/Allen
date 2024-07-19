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
#include "GlobalDecision.cuh"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(global_decision::global_decision_t)

void global_decision::global_decision_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_global_decision_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<host_global_decision_t>(arguments, first<host_number_of_events_t>(arguments));
}

void global_decision::global_decision_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(global_decision)(1, dim3(property<block_dim_x_t>().get()), context)(arguments);

  Allen::copy_async<host_global_decision_t, dev_global_decision_t>(arguments, context);

  Allen::synchronize(context);
}

__global__ void global_decision::global_decision(global_decision::Parameters parameters)
{
  for (unsigned event_index = threadIdx.x; event_index < parameters.dev_number_of_events[0];
       event_index += blockDim.x) {
    bool global_decision = false;

    HltDecReports reports(parameters.dev_dec_reports, event_index);

    for (HltDecReport dec_report : reports) {
      global_decision |= dec_report.decision();
      if (global_decision) break;
    }
    parameters.dev_global_decision[event_index] = global_decision;
  }
}
