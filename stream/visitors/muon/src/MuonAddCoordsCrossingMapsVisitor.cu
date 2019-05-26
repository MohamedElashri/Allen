#include "SequenceVisitor.cuh"
#include "MuonAddCoordsCrossingMaps.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_add_coords_crossing_maps_t>(
  muon_add_coords_crossing_maps_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_muon_hits>(host_buffers.host_number_of_selected_events[0]);
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
  state.set_opts(host_buffers.host_number_of_selected_events[0],
    Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters,
    cuda_stream);
  state.set_arguments(
    arguments.offset<dev_storage_station_region_quarter_offsets>(),
    arguments.offset<dev_storage_tile_id>(),
    arguments.offset<dev_storage_tdc_value>(),
    arguments.offset<dev_atomics_muon>(),
    arguments.offset<dev_permutation_srq>(),
    arguments.offset<dev_muon_raw_to_hits>(),
    arguments.offset<dev_muon_hits>());
  state.invoke();
}
