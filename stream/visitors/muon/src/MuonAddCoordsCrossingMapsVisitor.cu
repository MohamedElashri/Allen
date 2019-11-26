#include "SequenceVisitor.cuh"
#include "MuonAddCoordsCrossingMaps.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_add_coords_crossing_maps_t>(
  const muon_add_coords_crossing_maps_t& state,
  muon_add_coords_crossing_maps_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_muon_hits>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_station_ocurrences_offset>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::n_stations + 1);
  arguments.set_size<dev_muon_compact_hit>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::max_numhits_per_event);
}

template<>
void SequenceVisitor::visit<muon_add_coords_crossing_maps_t>(
  muon_add_coords_crossing_maps_t& state,
  const muon_add_coords_crossing_maps_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_station_ocurrences_offset>(),
    0,
    arguments.size<dev_station_ocurrences_offset>(),
    cuda_stream));

  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_muon_compact_hit>(), 0, arguments.size<dev_muon_compact_hit>(), cuda_stream));

  state.set_opts(host_buffers.host_number_of_selected_events[0], cuda_stream);
  state.set_arguments(
    arguments.offset<dev_storage_station_region_quarter_offsets>(),
    arguments.offset<dev_storage_tile_id>(),
    arguments.offset<dev_storage_tdc_value>(),
    arguments.offset<dev_atomics_muon>(),
    arguments.offset<dev_muon_raw_to_hits>(),
    arguments.offset<dev_muon_compact_hit>(),
    arguments.offset<dev_station_ocurrences_offset>());
  state.invoke();
}
