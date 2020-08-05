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
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_beamline_states {parameters.dev_velo_beamline_states, velo_tracks.total_number_of_tracks()};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  auto ut_number_of_selected_velo_tracks = parameters.dev_ut_number_of_selected_velo_tracks + event_number;
  auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;

  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const unsigned current_track_offset = event_tracks_offset + i;
    const auto velo_beamline_state = velo_beamline_states.get(current_track_offset);
    Velo::Consolidated::ConstHits consolidated_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits.get(), i);
    const auto backward = velo_beamline_state.z > consolidated_hits.z(0);
    if (
      !backward && parameters.dev_accepted_velo_tracks[current_track_offset] &&
      velo_track_in_UTA_acceptance(velo_beamline_state)) {
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
