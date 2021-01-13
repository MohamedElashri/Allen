/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "UTSelectVeloTracksWithWindows.cuh"
#include <tuple>

void ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_number_of_selected_velo_tracks_with_windows_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_ut_selected_velo_tracks_with_windows_t>(
    arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ut_number_of_selected_velo_tracks_with_windows_t>(arguments, 0, context);

  global_function(ut_select_velo_tracks_with_windows)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

//=========================================================================
// Determine if there are valid windows for this track looking at the sizes
//=========================================================================
__device__ bool
found_active_windows(const short* dev_windows_layers, const int number_of_tracks_event, const int i_track)
{
  const int track_pos = UT::Constants::n_layers * number_of_tracks_event;

  // The windows are stored in SOA, with the first 5 arrays being the first hits of the windows,
  // and the next 5 the sizes of the windows. We check the sizes of all the windows.
  const bool l0_found = dev_windows_layers[5 * track_pos + 0 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[6 * track_pos + 0 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[7 * track_pos + 0 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[8 * track_pos + 0 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[9 * track_pos + 0 * number_of_tracks_event + i_track] != 0;

  const bool l1_found = dev_windows_layers[5 * track_pos + 1 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[6 * track_pos + 1 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[7 * track_pos + 1 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[8 * track_pos + 1 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[9 * track_pos + 1 * number_of_tracks_event + i_track] != 0;

  const bool l2_found = dev_windows_layers[5 * track_pos + 2 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[6 * track_pos + 2 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[7 * track_pos + 2 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[8 * track_pos + 2 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[9 * track_pos + 2 * number_of_tracks_event + i_track] != 0;

  const bool l3_found = dev_windows_layers[5 * track_pos + 3 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[6 * track_pos + 3 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[7 * track_pos + 3 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[8 * track_pos + 3 * number_of_tracks_event + i_track] != 0 ||
                        dev_windows_layers[9 * track_pos + 3 * number_of_tracks_event + i_track] != 0;

  return (l0_found && l2_found && (l1_found || l3_found)) || (l3_found && l1_found && (l2_found || l0_found));
}

__global__ void ut_select_velo_tracks_with_windows::ut_select_velo_tracks_with_windows(
  ut_select_velo_tracks_with_windows::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const auto ut_number_of_selected_tracks = parameters.dev_ut_number_of_selected_velo_tracks[event_number];
  const auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;
  const auto ut_windows_layers =
    parameters.dev_ut_windows_layers + event_tracks_offset * CompassUT::num_elems * UT::Constants::n_layers;

  auto ut_number_of_selected_velo_tracks_with_windows =
    parameters.dev_ut_number_of_selected_velo_tracks_with_windows + event_number;
  auto ut_selected_velo_tracks_with_windows = parameters.dev_ut_selected_velo_tracks_with_windows + event_tracks_offset;

  for (unsigned i = threadIdx.x; i < ut_number_of_selected_tracks; i += blockDim.x) {
    const auto current_velo_track = ut_selected_velo_tracks[i];
    if (found_active_windows(ut_windows_layers, number_of_tracks_event, current_velo_track)) {
      int current_track = atomicAdd(ut_number_of_selected_velo_tracks_with_windows, 1);
      ut_selected_velo_tracks_with_windows[current_track] = current_velo_track;
    }
  }
}
