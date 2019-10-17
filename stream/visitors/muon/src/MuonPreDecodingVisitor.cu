#include "SequenceVisitor.cuh"
#include "MuonPreDecoding.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_pre_decoding_t>(
  muon_pre_decoding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_muon_raw>(std::get<1>(runtime_options.host_muon_events));
  arguments.set_size<dev_muon_raw_offsets>(std::get<2>(runtime_options.host_muon_events).size_bytes());
  arguments.set_size<dev_muon_raw_to_hits>(1);
  arguments.set_size<dev_storage_station_region_quarter_offsets>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::n_stations * Muon::Constants::n_regions *
      Muon::Constants::n_quarters +
    1);
  arguments.set_size<dev_storage_tile_id>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::max_numhits_per_event);
  arguments.set_size<dev_storage_tdc_value>(
    host_buffers.host_number_of_selected_events[0] * Muon::Constants::max_numhits_per_event);
  arguments.set_size<dev_atomics_muon>(2 * host_buffers.host_number_of_selected_events[0]);
}

template<>
void SequenceVisitor::visit<muon_pre_decoding_t>(
  muon_pre_decoding_t& state,
  const muon_pre_decoding_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{

  // FIXME: this should be done as part of the consumers, but
  // currently it cannot. This is because it is not possible to
  // indicate dependencies between Consumer and/or Producers.
  Muon::MuonRawToHits muonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_muon_raw_to_hits>(),
    &muonRawToHits,
    sizeof(muonRawToHits),
    cudaMemcpyHostToDevice,
    cuda_stream));

  data_to_device<dev_muon_raw, dev_muon_raw_offsets>
    (arguments, runtime_options.host_muon_events, cuda_stream);

  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_storage_station_region_quarter_offsets>(),
    0,
    arguments.size<dev_storage_station_region_quarter_offsets>(),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(arguments.offset<dev_atomics_muon>(), 0, arguments.size<dev_atomics_muon>(), cuda_stream));

  state.set_opts(
    runtime_options.mep_layout,
    host_buffers.host_number_of_selected_events[0],
    Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
    cuda_stream);
  state.set_arguments(
    runtime_options.mep_layout,
    arguments.offset<dev_event_list>(),
    arguments.offset<dev_muon_raw>(),
    arguments.offset<dev_muon_raw_offsets>(),
    arguments.offset<dev_muon_raw_to_hits>(),
    arguments.offset<dev_storage_station_region_quarter_offsets>(),
    arguments.offset<dev_storage_tile_id>(),
    arguments.offset<dev_storage_tdc_value>(),
    arguments.offset<dev_atomics_muon>());
  state.invoke(runtime_options.mep_layout);
}
