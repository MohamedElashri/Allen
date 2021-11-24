/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "GlobalDecision.cuh"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(global_decision::global_decision_t)

void global_decision::global_decision_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_global_decision_t>(arguments, first<host_number_of_events_t>(arguments));
}

void global_decision::global_decision_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{

  auto const grid_size =
    dim3((first<host_number_of_events_t>(arguments) + property<block_dim_x_t>() - 1) / property<block_dim_x_t>());

  global_function(global_decision)(grid_size, dim3(property<block_dim_x_t>().get()), context)(arguments);

  assign_to_host_buffer<dev_global_decision_t>(host_buffers.host_passing_event_list, arguments, context);
}

__global__ void global_decision::global_decision(global_decision::Parameters parameters)
{
  for (unsigned event_index = threadIdx.x; event_index < parameters.dev_number_of_events[0];
       event_index += blockDim.x) {
    bool global_decision = false;

    uint32_t const* event_dec_reports =
      parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_index;

    for (unsigned line_index = 0; line_index < parameters.dev_number_of_active_lines[0]; ++line_index) {
      // Iterate all lines to get the decision for the current {event, line}
      HltDecReport dec_report(event_dec_reports[2 + line_index]);
      global_decision |= dec_report.decision();
      if (global_decision) break;
    }
    parameters.dev_global_decision[event_index] = global_decision;
  }
}
