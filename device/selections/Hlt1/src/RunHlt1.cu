/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RunHlt1.cuh"
#include "DeviceLineTraverser.cuh"

void run_hlt1::run_hlt1_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto total_number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  set_size<dev_sel_results_t>(
    arguments, 1000 * total_number_of_events * std::tuple_size<configured_lines_t>::value);
  set_size<dev_sel_results_offsets_t>(arguments, std::tuple_size<configured_lines_t>::value + 1);
}

void run_hlt1::run_hlt1_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto total_number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  // TODO: Do this on the GPU, or rather remove completely
  // Prepare prefix sum of sizes of number of tracks and number of secondary vertices
  for (unsigned i_line = 0; i_line < std::tuple_size<configured_lines_t>::value; i_line++) {
    host_buffers.host_sel_results_atomics[i_line] = 0;
  }

  const auto lambda_one_track_fn = [&](const unsigned long i_line) {
    host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::OneTrackLine>::traverse(
    lambda_one_track_fn);

  const auto lambda_two_track_fn = [&](const unsigned long i_line) {
    host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_svs_t>(arguments);
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::TwoTrackLine>::traverse(
    lambda_two_track_fn);

  const auto lambda_special_fn = [&](const unsigned long i_line) {
    host_buffers.host_sel_results_atomics[i_line] = total_number_of_events;
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::SpecialLine>::traverse(
    lambda_special_fn);

  const auto lambda_velo_fn = [&](const unsigned long i_line) {
    host_buffers.host_sel_results_atomics[i_line] = first<host_number_of_selected_events_t>(arguments);
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::VeloLine>::traverse(lambda_velo_fn);

  // Prefix sum
  host_prefix_sum::host_prefix_sum_impl(
    host_buffers.host_sel_results_atomics, std::tuple_size<configured_lines_t>::value);

  cudaCheck(cudaMemcpyAsync(
    data<dev_sel_results_offsets_t>(arguments),
    host_buffers.host_sel_results_atomics,
    size<dev_sel_results_offsets_t>(arguments),
    cudaMemcpyHostToDevice,
    cuda_stream));

  initialize<dev_sel_results_t>(arguments, 0, cuda_stream);

  global_function(run_hlt1)(dim3(total_number_of_events), property<block_dim_t>(), cuda_stream)(
    arguments,
    first<host_number_of_selected_events_t>(arguments),
    event_start);

  // // Run the postscaler.
  // global_function(run_postscale)(dim3(total_number_of_events), property<block_dim_t>(), cuda_stream)(
  //   arguments,
  //   first<host_number_of_selected_events_t>(arguments),
  //   event_start);

  // if (runtime_options.do_check) {
  //   safe_assign_to_host_buffer<dev_sel_results_t>(
  //     host_buffers.host_sel_results, host_buffers.host_sel_results_size, arguments, cuda_stream);
  // }
}

__global__ void
run_hlt1::run_hlt1(run_hlt1::Parameters parameters, const unsigned selected_number_of_events, const unsigned event_start)
{
  const unsigned total_number_of_events = gridDim.x;

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
    const unsigned selected_event_number = blockIdx.x;
    // TODO: Revisit when making composable lists
    const unsigned event_number = parameters.dev_event_list[blockIdx.x] - event_start;

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
    const unsigned n_velo_tracks =
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