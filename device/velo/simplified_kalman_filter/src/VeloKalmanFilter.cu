/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VeloKalmanFilter.cuh"

void velo_kalman_filter::velo_kalman_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_velo_kalman_beamline_states_t>(
    arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments) * Velo::Consolidated::States::size);
  set_size<dev_velo_kalman_endvelo_states_t>(
    arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments) * Velo::Consolidated::States::size);
  set_size<dev_velo_kalman_beamline_states_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_velo_kalman_endvelo_states_view_t>(arguments, first<host_number_of_events_t>(arguments));
}

void velo_kalman_filter::velo_kalman_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(velo_kalman_filter)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_beamline.data());

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_velo_kalman_beamline_states_t>(
      host_buffers.host_velo_kalman_beamline_states, arguments, context);
    assign_to_host_buffer<dev_velo_kalman_endvelo_states_t>(
      host_buffers.host_velo_kalman_endvelo_states, arguments, context);
  }
}

/**
 * @brief Calculates the parameters according to a root means square fit
 */
__device__ MiniState least_means_square_fit(const Allen::Views::Velo::Consolidated::Track& track)
{
  MiniState state;

  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned short h = 0; h < track.number_of_hits(); ++h) {
    const auto hit = track.hit(h);
    const auto x = hit.x();
    const auto y = hit.y();
    const auto z = hit.z();

    const auto wx = Velo::Tracking::param_w;
    const auto wx_t_x = wx * x;
    const auto wx_t_z = wx * z;
    s0 += wx;
    sx += wx_t_x;
    sz += wx_t_z;
    sxz += wx_t_x * z;
    sz2 += wx_t_z * z;

    const auto wy = Velo::Tracking::param_w;
    const auto wy_t_y = wy * y;
    const auto wy_t_z = wy * z;
    u0 += wy;
    uy += wy_t_y;
    uz += wy_t_z;
    uyz += wy_t_y * z;
    uz2 += wy_t_z * z;
  }

  // Calculate tx, ty and backward
  const auto dens = 1.0f / (sz2 * s0 - sz * sz);
  state.tx = (sxz * s0 - sx * sz) * dens;
  state.x = (sx * sz2 - sxz * sz) * dens;

  const auto denu = 1.0f / (uz2 * u0 - uz * uz);
  state.ty = (uyz * u0 - uy * uz) * denu;
  state.y = (uy * uz2 - uyz * uz) * denu;

  state.z = -(state.x * state.tx + state.y * state.ty) / (state.tx * state.tx + state.ty * state.ty);
  state.x = state.x + state.tx * state.z;
  state.y = state.y + state.ty * state.z;

  return state;
}

/**
 * @brief Calculates the parameters according to a linear fit between the first and last velo hit
 */
__device__ MiniState linear_fit(const Allen::Views::Velo::Consolidated::Track& track, float* dev_beamline)
{
  MiniState state;

  // Get first and last hits
  const auto first = static_cast<::Velo::HitBase>(track.hit(0));
  const auto last = static_cast<::Velo::HitBase>(track.hit(track.number_of_hits() - 1));

  // Calculate tx, ty
  state.tx = (last.x - first.x) / (last.z - first.z);
  state.ty = (last.y - first.y) / (last.z - first.z);

  // Propagate to the beamline
  auto delta_z = (state.tx * (dev_beamline[0] - last.x) + state.ty * (dev_beamline[1] - last.y)) /
                 (state.tx * state.tx + state.ty * state.ty);
  state.x = last.x + state.tx * delta_z;
  state.y = last.y + state.ty * delta_z;
  state.z = last.z + delta_z;

  return state;
}

__global__ void velo_kalman_filter::velo_kalman_filter(velo_kalman_filter::Parameters parameters, float* dev_beamline)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto velo_tracks_view = parameters.dev_velo_tracks_view[event_number];
  const auto total_number_of_tracks = parameters.dev_offsets_all_velo_tracks[number_of_events];

  parameters.dev_velo_kalman_beamline_states_view[event_number] = Allen::Views::Velo::Consolidated::States {
    parameters.dev_velo_kalman_beamline_states, parameters.dev_offsets_all_velo_tracks, event_number, number_of_events};

  parameters.dev_velo_kalman_endvelo_states_view[event_number] = Allen::Views::Velo::Consolidated::States {
    parameters.dev_velo_kalman_endvelo_states, parameters.dev_offsets_all_velo_tracks, event_number, number_of_events};

  Velo::Consolidated::States kalman_beamline_states {parameters.dev_velo_kalman_beamline_states,
                                                     total_number_of_tracks};
  Velo::Consolidated::States kalman_endvelo_states {parameters.dev_velo_kalman_endvelo_states, total_number_of_tracks};

  for (unsigned i = threadIdx.x; i < velo_tracks_view.size(); i += blockDim.x) {

    const auto track = velo_tracks_view.track(i);

    // Get first estimate of the state , changed least means square fit to linear fit between first and last hit
    const auto lin_fit_at_beamline = linear_fit(track, dev_beamline);

    // Perform a Kalman fit to obtain state at beamline
    const auto kalman_beamline_state = simplified_fit<true>(track, lin_fit_at_beamline, dev_beamline);

    // Perform a Kalman fit in the other direction to obtain state at the end of the Velo
    const auto kalman_endvelo_state = simplified_fit<false>(track, kalman_beamline_state, dev_beamline);

    kalman_beamline_states.set(velo_tracks_view.offset() + i, kalman_beamline_state);
    kalman_endvelo_states.set(velo_tracks_view.offset() + i, kalman_endvelo_state);
  }
}
