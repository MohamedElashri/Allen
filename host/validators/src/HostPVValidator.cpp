/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostPVValidator.h"
#include "PrimaryVertexChecker.h"

void host_pv_validator::host_pv_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto multi_final_vertices = make_vector<dev_multi_final_vertices_t>(arguments);
  const auto number_of_multi_final_vertices = make_vector<dev_number_of_multi_final_vertices_t>(arguments);
  const auto event_list = make_vector<dev_event_list_t>(arguments);

  auto& checker = runtime_options.checker_invoker->checker<PVChecker>(name(), property<root_output_filename_t>());
  checker.accumulate(
    *first<host_mc_events_t>(arguments), multi_final_vertices, number_of_multi_final_vertices, event_list);
}
