#include "SequenceVisitor.cuh"
#include "MuonSortBySRQ.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_sort_station_region_quarter_t>(
  muon_sort_station_region_quarter_t& state,
  muon_sort_station_region_quarter_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_permutation_srq>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::max_numhits_per_event);
}

template<>
void SequenceVisitor::visit<muon_sort_station_region_quarter_t>(
  muon_sort_station_region_quarter_t& state,
  const muon_sort_station_region_quarter_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(
    cudaMemsetAsync(arguments.offset<dev_permutation_srq>(), 0, arguments.size<dev_permutation_srq>(), cuda_stream));

  state.set_opts(host_buffers.host_number_of_selected_events[0], cuda_stream);
  state.set_arguments(
    arguments.offset<dev_storage_tile_id>(),
    arguments.offset<dev_storage_tdc_value>(),
    arguments.offset<dev_atomics_muon>(),
    arguments.offset<dev_permutation_srq>());

  state.invoke();
}
