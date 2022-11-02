/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "CheckLocalizedBeamlineIP.cuh"

INSTANTIATE_ALGORITHM(check_localized_beamline_ip::check_localized_beamline_ip_t)

void check_localized_beamline_ip::check_localized_beamline_ip_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void check_localized_beamline_ip::check_localized_beamline_ip_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(check_localized_beamline_ip)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void check_localized_beamline_ip::check_localized_beamline_ip(
  check_localized_beamline_ip::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_states = parameters.dev_velo_states_view[event_number];

  __shared__ unsigned local_nTracks;
  if (threadIdx.x == 0) local_nTracks = 0;
  __syncthreads();

  for (unsigned i = threadIdx.x; i < velo_states.size(); i += blockDim.x) {
    const auto poca = velo_states.state(i);
    const float poca_rho_sq = poca.x() * poca.x() + poca.y() * poca.y();
    const bool flag = poca.z() >= parameters.min_state_z and poca.z() < parameters.max_state_z and
                      poca_rho_sq < parameters.max_state_rho_sq;
    if (flag) atomicAdd(&local_nTracks, 1);
  }

  __syncthreads();

  if (threadIdx.x == 0 && local_nTracks >= parameters.min_local_nTracks) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
    parameters.dev_event_list_output[current_event] = mask_t {event_number};
  }
}
