#include "SequenceVisitor.cuh"
#include "MuonDecoding.cuh"
#include "MuonRawToHits.cuh"
#include "MuonTables.cuh"
#include "MuonGeometry.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_decoding_t>(
  muon_decoding_t& state,
  muon_decoding_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_muon_raw>(std::get<0>(runtime_options.host_muon_events).size_bytes());
  arguments.set_size<dev_muon_raw_offsets>(std::get<1>(runtime_options.host_muon_events).size_bytes());
  arguments.set_size<dev_muon_raw_to_hits>(1);
  arguments.set_size<dev_muon_hits>(host_buffers.host_number_of_selected_events[0]);
}

template<>
void SequenceVisitor::visit<muon_decoding_t>(
  muon_decoding_t& state,
  const muon_decoding_t::arguments_t& arguments,
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
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_muon_raw>(),
    std::get<0>(runtime_options.host_muon_events).begin(),
    std::get<0>(runtime_options.host_muon_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_muon_raw_offsets>(),
    std::get<1>(runtime_options.host_muon_events).begin(),
    std::get<1>(runtime_options.host_muon_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  state.set_opts(
    host_buffers.host_number_of_selected_events[0],
    Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters,
    cuda_stream);
  state.set_arguments(
    arguments.offset<dev_event_list>(),
    arguments.offset<dev_muon_raw>(),
    arguments.offset<dev_muon_raw_offsets>(),
    arguments.offset<dev_muon_raw_to_hits>(),
    arguments.offset<dev_muon_hits>());
  state.invoke();
}
