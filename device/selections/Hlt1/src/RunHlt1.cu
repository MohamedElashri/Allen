#include "RunHlt1.cuh"

__global__ void
run_hlt1::run_hlt1(run_hlt1::Parameters parameters, const uint selected_number_of_events, const uint event_start)
{
  const uint total_number_of_events = gridDim.x;

  // Run all events through the Special line traverser with the last block
  if (blockIdx.x == gridDim.x - 1) {
    Hlt1::SpecialLineTraverse<configured_lines_t>::traverse(
      parameters.dev_sel_results,
      parameters.dev_sel_results_offsets,
      parameters.dev_odin_raw_input_offsets,
      parameters.dev_odin_raw_input,
      total_number_of_events);
  }

  if (blockIdx.x < selected_number_of_events) {
    // Run all events that passed the filter (GEC) through the other line traversers
    const uint selected_event_number = blockIdx.x;
    // TODO: Revisit when making composable lists
    const uint event_number = parameters.dev_event_list[blockIdx.x] - event_start;

    // Fetch tracks
    const ParKalmanFilter::FittedTrack* event_tracks =
      parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[selected_event_number];
    const auto number_of_tracks_in_event = parameters.dev_offsets_forward_tracks[selected_event_number + 1] -
                                           parameters.dev_offsets_forward_tracks[selected_event_number];

    // Fetch vertices
    const VertexFit::TrackMVAVertex* event_vertices =
      parameters.dev_consolidated_svs + parameters.dev_sv_offsets[selected_event_number];
    const auto number_of_vertices_in_event =
      parameters.dev_sv_offsets[selected_event_number + 1] - parameters.dev_sv_offsets[selected_event_number];

    // Fetch ODIN info.
    const char* event_odin_data = parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number];

    // Fetch number of velo tracks.
    const uint n_velo_tracks =
      parameters.dev_velo_offsets[selected_event_number + 1] - parameters.dev_velo_offsets[selected_event_number];

    // Process all lines
    Hlt1::Traverse<configured_lines_t>::traverse(
      parameters.dev_sel_results,
      parameters.dev_sel_results_offsets,
      parameters.dev_offsets_forward_tracks,
      parameters.dev_sv_offsets,
      event_tracks,
      event_vertices,
      event_odin_data,
      n_velo_tracks,
      selected_event_number,
      number_of_tracks_in_event,
      number_of_vertices_in_event);
  }
}