#include "SequenceVisitor.cuh"
#include "MuonDecoding.cuh"
#include "MuonRawToHits.cuh"
#include "MuonTables.cuh"
#include "MuonGeometry.cuh"

template<>
void SequenceVisitor::set_arguments_size<muon_decoding_t>(
    muon_decoding_t::arguments_t arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) {
  arguments.set_size<dev_muon_raw>(runtime_options.host_muon_events_size);
  arguments.set_size<dev_muon_raw_offsets>(runtime_options.host_muon_event_offsets_size);
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
    cudaEvent_t& cuda_generic_event) {
  /*
  std::string file_name_muon_tables = "../../../input/muon/muon_table.bin";
  std::string file_name_muon_geometry = "../../../input/muon/muon_geometry.bin";
  char muon_tables_raw_input[1200000];
  memset(muon_tables_raw_input, 0, sizeof(muon_tables_raw_input));
  std::ifstream muon_tables_file(file_name_muon_tables, std::ios::binary);
  muon_tables_file.read(muon_tables_raw_input, sizeof(muon_tables_raw_input));
  muon_tables_file.close();
  char muon_geometry_raw_input[100000];
  memset(muon_geometry_raw_input, 0, sizeof(muon_geometry_raw_input));
  std::ifstream muon_geometry_file(file_name_muon_geometry, std::ios::binary);
  muon_geometry_file.read(muon_geometry_raw_input, sizeof(muon_geometry_raw_input));
  muon_geometry_file.close();
  Muon::MuonTables muonTables;
  Muon::read_muon_tables(muon_tables_raw_input, &muonTables);
  Muon::MuonGeometry muonGeometry;
  muonGeometry.read_muon_geometry(muon_geometry_raw_input);
  Muon::MuonRawToHits muonRawToHits = {muonTables, muonGeometry};
  cudaCheck(cudaMemcpyAsync(
      arguments.offset<dev_muon_raw_to_hits>(),
      &muonRawToHits,
      sizeof(muonRawToHits),
      cudaMemcpyHostToDevice,
      cuda_stream
  ));
  cudaCheck(cudaMemcpyAsync(
      arguments.offset<dev_muon_raw>(),
      runtime_options.host_muon_events,
      runtime_options.host_muon_events_size,
      cudaMemcpyHostToDevice,
      cuda_stream)
  );
  cudaCheck(cudaMemcpyAsync(
      arguments.offset<dev_muon_raw_offsets>(),
      runtime_options.host_muon_event_offsets,
      runtime_options.host_muon_event_offsets_size * sizeof(unsigned int),
      cudaMemcpyHostToDevice,
      cuda_stream)
  );

  state.set_opts(
      host_buffers.host_number_of_selected_events[0],
      Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters,
      cuda_stream
  );
  state.set_arguments(
      arguments.offset<dev_event_list>(),
      arguments.offset<dev_muon_raw>(),
      arguments.offset<dev_muon_raw_offsets>(),
      arguments.offset<dev_muon_raw_to_hits>(),
      arguments.offset<dev_muon_hits>()
  );
  state.invoke();
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
  */
}
