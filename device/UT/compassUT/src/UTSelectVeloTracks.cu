/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "UTSelectVeloTracks.cuh"
#include <tuple>

void ut_select_velo_tracks::ut_select_velo_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_number_of_selected_velo_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_ut_selected_velo_tracks_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void ut_select_velo_tracks::ut_select_velo_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ut_number_of_selected_velo_tracks_t>(arguments, 0, context);

  global_function(ut_select_velo_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void ut_select_velo_tracks::ut_select_velo_tracks(ut_select_velo_tracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  auto ut_number_of_selected_velo_tracks = parameters.dev_ut_number_of_selected_velo_tracks + event_number;
  auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + velo_tracks.offset();

  for (unsigned i = threadIdx.x; i < velo_states.size(); i += blockDim.x) {
    const auto velo_track = velo_tracks.track(i);
    const auto velo_state = velo_states.state(i);

    const auto backward = velo_state.z() > velo_track.hit(0).z();
    if (
      !backward && parameters.dev_accepted_velo_tracks[velo_tracks.offset() + i] &&
      velo_track_in_UTA_acceptance(velo_state)) {
      int current_track = atomicAdd(ut_number_of_selected_velo_tracks, 1);
      ut_selected_velo_tracks[current_track] = i;
    }
  }
}

//=============================================================================
// Reject tracks outside of acceptance or pointing to the beam pipe
//=============================================================================
__device__ bool ut_select_velo_tracks::velo_track_in_UTA_acceptance(const MiniState& state)
{
  const float xMidUT = state.x + state.tx * (UT::Constants::zMidUT - state.z);
  const float yMidUT = state.y + state.ty * (UT::Constants::zMidUT - state.z);

  if (xMidUT * xMidUT + yMidUT * yMidUT < UT::Constants::centralHoleSize * UT::Constants::centralHoleSize) return false;
  if ((fabsf(state.tx) > UT::Constants::maxXSlope) || (fabsf(state.ty) > UT::Constants::maxYSlope)) return false;

  if (
    UT::Constants::passTracks && fabsf(xMidUT) < UT::Constants::passHoleSize &&
    fabsf(yMidUT) < UT::Constants::passHoleSize) {
    return false;
  }

  return true;
}
