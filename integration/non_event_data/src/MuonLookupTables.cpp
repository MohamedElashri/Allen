#include <string>

#include <cuda_runtime.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
}

Consumers::MuonLookupTables::MuonLookupTables(std::vector<char>& host_muon_tables_raw, char*& dev_muon_tables_raw, Muon::MuonTables*& dev_muon_tables)
    : m_host_muon_tables_raw{host_muon_tables_raw},
      m_dev_muon_tables_raw{dev_muon_tables_raw},
      m_muon_tables{dev_muon_tables} {
}
void Consumers::MuonLookupTables::consume(std::vector<char> const& data) {
  const char* raw_input = data.data();
  size_t allOffsets[27];
  size_t currentAllOffsetsIndex = 0;

  for (size_t tableNumber = 0; tableNumber < Muon::MuonTables::n_tables; tableNumber++) {
    size_t gridXSize;
    std::copy_n((size_t*) raw_input, 1, &gridXSize);
    assert(gridXSize == Muon::Constants::n_stations * Muon::Constants::n_regions);
    raw_input += sizeof(size_t);
    raw_input += sizeof(int) * gridXSize;
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();

    size_t gridYSize;
    std::copy_n((size_t*) raw_input, 1, &gridYSize);
    raw_input += sizeof(size_t);
    raw_input += sizeof(int) * gridYSize;
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();

    size_t sizeXSize;
    std::copy_n((size_t*) raw_input, 1, &sizeXSize);
    raw_input += sizeof(size_t);
    raw_input += sizeof(float) * sizeXSize;
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();

    size_t sizeYSize;
    std::copy_n((size_t*) raw_input, 1, &sizeYSize);
    raw_input += sizeof(size_t);
    raw_input += sizeof(float) * sizeYSize;
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();

    size_t offsetSize;
    std::copy_n((size_t*) raw_input, 1, &offsetSize);
    raw_input += sizeof(size_t);
    raw_input += sizeof(unsigned int) * offsetSize;
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();

    size_t tableSize;
    std::copy_n((size_t*) raw_input, 1, &tableSize);
    raw_input += sizeof(size_t);
    assert(tableSize == Muon::Constants::n_stations);
    for (int i = 0; i < tableSize; i++) {
      size_t stationTableSize;
      std::copy_n((size_t*) raw_input, 1, &stationTableSize);
      raw_input += sizeof(size_t);
      raw_input += sizeof(float) * Muon::MuonTables::n_dimensions * stationTableSize;
      allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    }
  }
  assert(currentAllOffsetsIndex == 27);

  auto& dev_muon_tables_raw = m_dev_muon_tables_raw.get();
  auto& host_muon_tables_raw = m_host_muon_tables_raw.get();
  std::cerr << host_muon_tables_raw.size() << " " << data.size() << "\n";
  if (!m_muon_tables) {
    cudaCheck(cudaMalloc((void**) &dev_muon_tables_raw, data.size()));
    cudaCheck(cudaMalloc((void**) &m_muon_tables.get(), sizeof(Muon::MuonTables)));
    m_size = sizeof(Muon::MuonTables);
    std::cerr << sizeof(Muon::MuonTables) << "\n";
  } else if (host_muon_tables_raw.size() != data.size()) {
    throw StrException{string{"sizes don't match: "} + to_string(host_muon_tables_raw.size()) + " " + to_string(data.size())};
  }
  host_muon_tables_raw = std::move(data);
  cudaCheck(cudaMemcpy(dev_muon_tables_raw, host_muon_tables_raw.data(), host_muon_tables_raw.size(), cudaMemcpyHostToDevice));
  Muon::MuonTables host_muon_tables{allOffsets, dev_muon_tables_raw};
  cudaCheck(cudaMemcpy(m_muon_tables.get(), &host_muon_tables, sizeof(Muon::MuonTables), cudaMemcpyHostToDevice));
}
