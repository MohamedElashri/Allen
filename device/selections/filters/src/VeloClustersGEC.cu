/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\************************************************************************/
#include "VeloClustersGEC.cuh"

INSTANTIATE_ALGORITHM(velo_clusters_gec::velo_clusters_gec_t)

void velo_clusters_gec::velo_clusters_gec_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{

  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void velo_clusters_gec::velo_clusters_gec_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);
  global_function(velo_clusters_gec)(dim3(1), dim3(m_block_dim_x), context)(
    arguments, size<dev_event_list_t>(arguments), m_min_clusters, m_max_clusters);
  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void velo_clusters_gec::velo_clusters_gec(
  velo_clusters_gec::Parameters parameters,
  const unsigned number_of_selected_events,
  const unsigned min_clusters,
  const unsigned max_clusters)
{

  for (unsigned event_idx = blockIdx.x * blockDim.x + threadIdx.x; event_idx < number_of_selected_events;
       event_idx += blockDim.x * gridDim.x) {
    const auto event_number = parameters.dev_event_list[event_idx];

    const unsigned* module_pair_hit_start =
      parameters.dev_offsets_velo_clusters + event_number * Velo::Constants::n_module_pairs;
    const unsigned event_hit_start = module_pair_hit_start[0];
    const unsigned number_of_velo_clusters_event =
      module_pair_hit_start[Velo::Constants::n_module_pairs] - event_hit_start;

    if (number_of_velo_clusters_event >= min_clusters && number_of_velo_clusters_event < max_clusters) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}
