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
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  global_function(velo_kalman_filter)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), stream)(
    arguments);

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_velo_kalman_beamline_states_t>(host_buffers.host_kalmanvelo_states, arguments, stream);
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

__global__ void velo_kalman_filter::velo_kalman_filter(velo_kalman_filter::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {parameters.dev_offsets_all_velo_tracks,
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

    // Get first estimate of the state , calculate least means square fit
    // (Doesn't have to be the output of the least square fit, could be a simple linear fit between first and last hit)
    const auto lms_fit_at_beamline = least_means_square_fit(consolidated_hits, n_hits);

    //Perform a Kalman fit to obtain state at beamline
    const auto kalman_beamline_state = simplified_fit<true>(consolidated_hits, lms_fit_at_beamline, n_hits);

    //Perform a Kalman fit in the other direction to obtain state at the end of the Velo
    const auto kalman_endvelo_state = simplified_fit<false>(consolidated_hits, kalman_beamline_state, n_hits);

    kalman_beamline_states.set(event_tracks_offset + i, kalman_beamline_state);
    kalman_endvelo_states.set(event_tracks_offset + i, kalman_endvelo_state);
  }
}
