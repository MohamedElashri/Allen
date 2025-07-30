/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "UTSelectVeloTracks.cuh"
#include <tuple>
#include "PrefixSum.cuh"
#include "WarpIntrinsicsTools.cuh"
#include "PrefixSum.cuh"

INSTANTIATE_ALGORITHM(ut_select_velo_tracks::ut_select_velo_tracks_t)

void ut_select_velo_tracks::ut_select_velo_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_selected_velo_tracks_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_ut_number_of_selected_velo_tracks_t>(arguments, 1);
  set_size<dev_ut_selected_velo_tracks_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_velo_tracks_offsets_t>(arguments, first<host_number_of_events_t>(arguments));
}

__global__ void
compress_array(const unsigned* src_offsets, const unsigned* dst_offsets, unsigned n_offsets, unsigned* data)
{
  unsigned group = 0;
  unsigned group_start = dst_offsets[0];
  unsigned group_end = dst_offsets[1];
  for (unsigned i = threadIdx.x; i < dst_offsets[n_offsets]; i += blockDim.x) {
    while (i >= group_end) {
      group++;
      group_start = group_end;
      group_end = dst_offsets[group + 1];
    }
    unsigned src_i = src_offsets[group] + i - group_start;
    auto val = data[src_i];
    __syncthreads();
    data[i] = val;
    // no sync needed
  }
}

void ut_select_velo_tracks::ut_select_velo_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_selected_velo_tracks_offsets_t>(arguments, 0, context);

  global_function(ut_select_velo_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);

  PrefixSum::prefix_sum<dev_ut_selected_velo_tracks_offsets_t, host_ut_number_of_selected_velo_tracks_t>(
    *this, arguments, context);
  global_function(compress_array)(dim3(1), dim3(256), context)(
    data<dev_velo_tracks_offsets_t>(arguments),
    data<dev_ut_selected_velo_tracks_offsets_t>(arguments),
    first<host_number_of_events_t>(arguments),
    data<dev_ut_selected_velo_tracks_t>(arguments));
  reduce_size<dev_ut_selected_velo_tracks_t>(arguments, first<host_ut_number_of_selected_velo_tracks_t>(arguments));
}

__global__ void ut_select_velo_tracks::ut_select_velo_tracks(ut_select_velo_tracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  auto ut_number_of_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks_offsets + event_number;
  auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + velo_tracks.offset();

  if (threadIdx.x == 0) {
    parameters.dev_velo_tracks_offsets[event_number] = velo_tracks.offset();
  }

  for (unsigned i = threadIdx.x; i < velo_states.size(); i += blockDim.x) {
    const auto velo_track = velo_tracks.track(i);
    const auto velo_state = velo_states.state(i);

    const auto backward = velo_state.z() > velo_track.hit(0).z();
    if (
      !backward && parameters.dev_accepted_velo_tracks[velo_tracks.offset() + i] &&
      velo_track_in_UTA_acceptance(velo_state)) {
      int current_track = Allen::warp::atomic_increment(ut_number_of_selected_velo_tracks);
      ut_selected_velo_tracks[current_track] = i;
    }
  }
}

//=============================================================================
// Reject tracks outside of acceptance or pointing to the beam pipe
//=============================================================================
__device__ bool ut_select_velo_tracks::velo_track_in_UTA_acceptance(const MiniState& state)
{
  const float xMidUT = state.x() + state.tx() * (UT::Constants::zMidUT - state.z());
  const float yMidUT = state.y() + state.ty() * (UT::Constants::zMidUT - state.z());

  if (xMidUT * xMidUT + yMidUT * yMidUT < UT::Constants::centralHoleSize * UT::Constants::centralHoleSize) return false;
  if ((fabsf(state.tx()) > UT::Constants::maxXSlope) || (fabsf(state.ty()) > UT::Constants::maxYSlope)) return false;

  if (
    UT::Constants::passTracks && fabsf(xMidUT) < UT::Constants::passHoleSize &&
    fabsf(yMidUT) < UT::Constants::passHoleSize) {
    return false;
  }

  return true;
}
