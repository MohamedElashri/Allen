#include "CalculateWindows.cuh"
#include "SearchWindows.cuh"
#include <tuple>

__global__ void ut_search_windows::ut_search_windows(
  ut_search_windows::Parameters parameters,
  UTMagnetTool* dev_ut_magnet_tool,
  const float* dev_ut_dxDy,
  const uint* dev_unique_x_sector_layer_offsets, // prefixsum to point to the x hit of the sector, per layer
  const float* dev_unique_sector_xs)             // list of xs that define the groups
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const uint total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];

  // Velo consolidated types
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};

  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};

  const float* fudge_factors = &(dev_ut_magnet_tool->dxLayTable[0]);
  
  const auto ut_number_of_selected_tracks = parameters.dev_ut_number_of_selected_velo_tracks[event_number];
  const auto ut_selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + event_tracks_offset;

  for (uint layer = threadIdx.x; layer < UT::Constants::n_layers; layer += blockDim.x) {
    const uint layer_offset = ut_hit_offsets.layer_offset(layer);

    for (uint i = threadIdx.y; i < ut_number_of_selected_tracks; i += blockDim.y) {
      const auto current_velo_track = ut_selected_velo_tracks[i];

      const uint current_track_offset = event_tracks_offset + current_velo_track;
      const MiniState velo_state = velo_states.getMiniState(current_track_offset);

      const auto candidates = calculate_windows(
        layer,
        velo_state,
        fudge_factors,
        ut_hits,
        ut_hit_offsets,
        dev_ut_dxDy,
        dev_unique_sector_xs,
        dev_unique_x_sector_layer_offsets,
        parameters.y_tol,
        parameters.y_tol_slope,
        parameters.min_pt,
        parameters.min_momentum);

      // Write the windows in SoA style
      short* windows_layers =
        parameters.dev_ut_windows_layers + event_tracks_offset * CompassUT::num_elems * UT::Constants::n_layers;

      const int track_pos = UT::Constants::n_layers * number_of_tracks_event;
      const int layer_pos = layer * number_of_tracks_event + current_velo_track;

      windows_layers[0 * track_pos + layer_pos] = std::get<0>(candidates) - layer_offset; // first_candidate
      windows_layers[1 * track_pos + layer_pos] = std::get<2>(candidates) - layer_offset; // left_group_first
      windows_layers[2 * track_pos + layer_pos] = std::get<4>(candidates) - layer_offset; // right_group_first
      windows_layers[3 * track_pos + layer_pos] = std::get<6>(candidates) - layer_offset; // left2_group_first
      windows_layers[4 * track_pos + layer_pos] = std::get<8>(candidates) - layer_offset; // right2_group_first
      windows_layers[5 * track_pos + layer_pos] = std::get<1>(candidates) - std::get<0>(candidates); // last_size
      windows_layers[6 * track_pos + layer_pos] = std::get<3>(candidates) - std::get<2>(candidates); // left_size_last
      windows_layers[7 * track_pos + layer_pos] =
        std::get<5>(candidates) - std::get<4>(candidates); // right_size_first
      windows_layers[8 * track_pos + layer_pos] =
        std::get<7>(candidates) - std::get<6>(candidates); // left2_size_last
      windows_layers[9 * track_pos + layer_pos] =
        std::get<9>(candidates) - std::get<8>(candidates); // right2_size_first
    }
  }
}
