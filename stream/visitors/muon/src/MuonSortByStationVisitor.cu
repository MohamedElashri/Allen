#include "SequenceVisitor.cuh"
#include "MuonSortByStation.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_sort_by_station_t>(
  const muon_sort_by_station_t& state,
  muon_sort_by_station_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_permutation_station>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::max_numhits_per_event);
}

template<>
void SequenceVisitor::visit<muon_sort_by_station_t>(
  muon_sort_by_station_t& state,
  const muon_sort_by_station_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_permutation_station>(), 0, arguments.size<dev_permutation_station>(), cuda_stream));

  state.set_opts(host_buffers.host_number_of_selected_events[0], cuda_stream);
  state.set_arguments(
    arguments.offset<dev_storage_tile_id>(),
    arguments.offset<dev_storage_tdc_value>(),
    arguments.offset<dev_atomics_muon>(),
    arguments.offset<dev_permutation_station>(),
    arguments.offset<dev_muon_hits>(),
    arguments.offset<dev_station_ocurrences_offset>(),
    arguments.offset<dev_muon_compact_hit>(),
    arguments.offset<dev_muon_raw_to_hits>());

  state.invoke();
}
