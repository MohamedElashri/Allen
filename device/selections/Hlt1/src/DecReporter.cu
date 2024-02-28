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
#include "DecReporter.cuh"
#include "HltDecReport.cuh"
#include "SelectionsEventModel.cuh"

INSTANTIATE_ALGORITHM(dec_reporter::dec_reporter_t)

void dec_reporter::dec_reporter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const n_lines = first<host_number_of_active_lines_t>(arguments);
  set_size<dev_dec_reports_t>(
    arguments, HltDecReports<false>::size(n_lines) * first<host_number_of_events_t>(arguments));
  set_size<host_dec_reports_t>(
    arguments, HltDecReports<false>::size(n_lines) * first<host_number_of_events_t>(arguments));
  set_size<dev_selected_candidates_counts_t>(arguments, n_lines * first<host_number_of_events_t>(arguments));
}

void dec_reporter::dec_reporter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<host_dec_reports_t>(arguments, 0, context);
  Allen::memset_async<dev_selected_candidates_counts_t>(arguments, 0, context);

  global_function(dec_reporter)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  Allen::copy_async<host_dec_reports_t, dev_dec_reports_t>(arguments, context);
  Allen::synchronize(context);
}

__global__ void dec_reporter::dec_reporter(dec_reporter::Parameters parameters)
{
  const auto event_index = blockIdx.x;
  const auto number_of_events = gridDim.x;

  // Selections view
  Selections::ConstSelections selections {
    parameters.dev_selections, parameters.dev_selections_offsets, number_of_events};

  HltDecReports<false> reports(parameters.dev_dec_reports, event_index, parameters.dev_number_of_active_lines[0]);
  unsigned* event_selected_candidates_counts =
    parameters.dev_selected_candidates_counts + event_index * parameters.dev_number_of_active_lines[0];

  if (threadIdx.x == 0) {
    // Set TCK and taskID for each event dec report
    reports.set_number_of_lines(parameters.dev_number_of_active_lines[0]);
    reports.set_key(parameters.key);
    reports.set_tck(parameters.tck);
    reports.set_task_id(parameters.task_id);
  }

  __syncthreads();

  for (unsigned line_index = threadIdx.x; line_index < reports.number_of_lines(); line_index += blockDim.x) {
    // Iterate all elements and get a decision for the current {event, line}
    bool final_decision = false;
    auto decs = selections.get_span(line_index, event_index);
    for (unsigned i = 0; i < decs.size(); ++i) {
      final_decision |= decs[i];
      if (decs[i]) {
        event_selected_candidates_counts[line_index]++;
      }
    }

    reports.set_dec_report(
      line_index,
      HltDecReport {final_decision,
                    std::byte {0},          // error
                    static_cast<std::byte>( // number of candidates
                      std::min(event_selected_candidates_counts[line_index], 15U)),
                    std::byte {1},                                 // execution stage
                    static_cast<unsigned short>(line_index + 1)}); // decision ID
  }
}
