/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DecReporter.cuh"
#include "HltDecReport.cuh"
#include "SelectionsEventModel.cuh"

void dec_reporter::dec_reporter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_dec_reports_t>(
    arguments, (2 + first<host_number_of_active_lines_t>(arguments)) * first<host_number_of_events_t>(arguments));
}

void dec_reporter::dec_reporter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(dec_reporter)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  if (runtime_options.do_check) {
    safe_assign_to_host_buffer<dev_dec_reports_t>(host_buffers.host_dec_reports, arguments, stream);
  }
}

__global__ void dec_reporter::dec_reporter(dec_reporter::Parameters parameters)
{
  const auto event_index = blockIdx.x;
  const auto number_of_events = gridDim.x;

  // Selections view
  Selections::ConstSelections selections {
    parameters.dev_selections, parameters.dev_selections_offsets, number_of_events};

  uint32_t* event_dec_reports =
    parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_index;

  if (threadIdx.x == 0) {
    // Set TCK and taskID for each event dec report
    event_dec_reports[0] = Hlt1::TCK;
    event_dec_reports[1] = Hlt1::taskID;
  }

  for (unsigned line_index = threadIdx.x; line_index < parameters.dev_number_of_active_lines[0];
       line_index += blockDim.x) {
    // Iterate all elements and get a decision for the current {event, line}
    bool final_decision = false;
    auto decs = selections.get_span(line_index, event_index);
    for (unsigned i = 0; i < decs.size(); ++i) {
      final_decision |= decs[i];
    }

    HltDecReport dec_report;
    dec_report.setDecision(final_decision);

    // TODO: The following are all placeholder values for now.
    dec_report.setErrorBits(0);
    dec_report.setNumberOfCandidates(1);
    dec_report.setIntDecisionID(line_index);
    dec_report.setExecutionStage(1);

    event_dec_reports[2 + line_index] = dec_report.getDecReport();
  }
}
