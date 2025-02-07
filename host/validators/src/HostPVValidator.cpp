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
#include "HostPVValidator.h"
#include "PrimaryVertexChecker.h"

INSTANTIATE_ALGORITHM(host_pv_validator::host_pv_validator_t)

void host_pv_validator::host_pv_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto multi_final_vertices = make_host_buffer<dev_multi_final_vertices_t>(arguments, context);
  const auto number_of_multi_final_vertices =
    make_host_buffer<dev_number_of_multi_final_vertices_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  auto& checker = runtime_options.checker_invoker->checker<PVChecker>(name(), m_root_output_filename);
  checker.accumulate(
    *first<host_mc_events_t>(arguments),
    multi_final_vertices,
    number_of_multi_final_vertices,
    event_list,
    m_pp_minNumTracksPerVertex);
}
