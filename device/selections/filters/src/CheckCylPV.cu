/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "CheckCylPV.cuh"

INSTANTIATE_ALGORITHM(check_cyl_pvs::check_cyl_pvs_t)

void check_cyl_pvs::check_cyl_pvs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void check_cyl_pvs::check_cyl_pvs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(check_cyl_pvs)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void check_cyl_pvs::check_cyl_pvs(check_cyl_pvs::Parameters parameters)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const PV::Vertex* vertices = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;

  __shared__ unsigned event_decision;
  if (threadIdx.x == 0) event_decision = 0;
  __syncthreads();

  for (unsigned i = threadIdx.x; i < parameters.dev_number_of_multi_final_vertices[event_number]; i += blockDim.x) {
    const auto& pv = vertices[i];
    const auto rho_sq = pv.position.x * pv.position.x + pv.position.y * pv.position.y;
    const bool dec = pv.nTracks >= parameters.min_vtx_nTracks and pv.position.z >= parameters.min_vtx_z and
                     pv.position.z < parameters.max_vtz_z and rho_sq < parameters.max_vtx_rho_sq;
    if (dec) atomicOr(&event_decision, dec);
  }

  __syncthreads();

  if (threadIdx.x == 0 && event_decision) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
    parameters.dev_event_list_output[current_event] = mask_t {event_number};
  }
}
