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
    arguments,
    first<host_number_of_reconstructed_velo_tracks_t>(arguments) * Velo::Consolidated::States::size);
  set_size<dev_velo_kalman_endvelo_states_t>(
    arguments,
    first<host_number_of_reconstructed_velo_tracks_t>(arguments) * Velo::Consolidated::States::size);
}

void velo_kalman_filter::velo_kalman_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(velo_kalman_filter)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments, constants.dev_beamline.data());

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_kalmanvelo_states,
      data<dev_velo_kalman_beamline_states_t>(arguments),
      size<dev_velo_kalman_beamline_states_t>(arguments),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

/**
 * @brief Calculates the parameters according to a root means square fit
 */
 __device__ MiniState least_means_square_fit(Velo::Consolidated::ConstHits& consolidated_hits, const unsigned number_of_hits)
 {
   MiniState state;
 
   // Fit parameters
   float s0, sx, sz, sxz, sz2;
   float u0, uy, uz, uyz, uz2;
   s0 = sx = sz = sxz = sz2 = 0.0f;
   u0 = uy = uz = uyz = uz2 = 0.0f;
 
   // Iterate over hits
   for (unsigned short h = 0; h < number_of_hits; ++h) {
     const auto x = consolidated_hits.x(h);
     const auto y = consolidated_hits.y(h);
     const auto z = consolidated_hits.z(h);
 
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
 * @brief Calculates the parameters according to a root means square fit
 */
 __device__ MiniState linear_fit(Velo::Consolidated::ConstHits& consolidated_hits, const unsigned number_of_hits, float* dev_beamline)
 {
   MiniState state;
 
   // Get first and last hits
   const auto first_x = consolidated_hits.x(0);
   const auto first_y = consolidated_hits.y(0);
   const auto first_z = consolidated_hits.z(0);
   const auto last_x = consolidated_hits.x(number_of_hits-1);
   const auto last_y = consolidated_hits.y(number_of_hits-1);
   const auto last_z = consolidated_hits.z(number_of_hits-1);
 
   // Calculate tx, ty
   state.tx = (last_x-first_x)/(last_z-first_z);
   state.ty = (last_y-first_y)/(last_z-first_z);
 
   // Propagate to the beamline
   auto delta_z = (state.tx * (dev_beamline[0] - last_x) + state.ty * (dev_beamline[1] - last_y)) / (state.tx * state.tx + state.ty * state.ty);
   state.x = last_x + state.tx * delta_z;
   state.y = last_y + state.ty * delta_z;
   state.z = last_z + delta_z;
 
   return state;
 }


__global__ void velo_kalman_filter::velo_kalman_filter(velo_kalman_filter::Parameters parameters, float* dev_beamline)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {
    parameters.dev_offsets_all_velo_tracks,
    parameters.dev_offsets_velo_track_hit_number,
    event_number,
    number_of_events};

  Velo::Consolidated::States kalman_beamline_states {parameters.dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks()};
  Velo::Consolidated::States kalman_endvelo_states {parameters.dev_velo_kalman_endvelo_states, velo_tracks.total_number_of_tracks()};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {

    Velo::Consolidated::ConstHits consolidated_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits.get(), i);
    const unsigned n_hits = velo_tracks.number_of_hits(i);

    // Get first estimate of the state , changed least means square fit to linear fit between first and last hit
    const auto lin_fit_at_beamline = linear_fit(consolidated_hits, n_hits, dev_beamline);

    //Perform a Kalman fit to obtain state at beamline
    const auto kalman_beamline_state = simplified_fit<true>(consolidated_hits, lin_fit_at_beamline, n_hits, dev_beamline);

    //Perform a Kalman fit in the other direction to obtain state at the end of the Velo
    const auto kalman_endvelo_state = simplified_fit<false>(consolidated_hits, kalman_beamline_state, n_hits, dev_beamline);

    kalman_beamline_states.set(event_tracks_offset + i, kalman_beamline_state);
    kalman_endvelo_states.set(event_tracks_offset + i, kalman_endvelo_state);
  }
}
