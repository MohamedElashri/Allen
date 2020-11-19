/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "MuonDefinitions.cuh"
#include "MuonGeometry.cuh"
#include "MuonTables.cuh"

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MuonLookupTables::MuonLookupTables(
  std::vector<char>& host_muon_tables_raw,
  char*& dev_muon_tables_raw,
  Muon::MuonTables*& dev_muon_tables) :
  m_host_muon_tables_raw {host_muon_tables_raw},
  m_dev_muon_tables_raw {dev_muon_tables_raw}, m_muon_tables {dev_muon_tables}
{}
void Consumers::MuonLookupTables::consume(std::vector<char> const& data)
{
  const char* raw_input = data.data();
  size_t allOffsets[n_data_blocks];
  unsigned int sizeOffset[Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::MuonTables::n_tables];
  int gridY[Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::MuonTables::n_tables];
  size_t currentAllOffsetsIndex = 0;

  for (size_t tableNumber = 0; tableNumber < Muon::MuonTables::n_tables; tableNumber++) {
    size_t gridXSize;
    std::copy_n((size_t*) raw_input, 1, &gridXSize);
    assert(gridXSize == Muon::Constants::n_stations * Muon::Constants::n_regions);
    raw_input += sizeof(size_t);
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    raw_input += sizeof(int) * gridXSize;

    size_t gridYSize;
    std::copy_n((size_t*) raw_input, 1, &gridYSize);
    raw_input += sizeof(size_t);
    std::copy_n((int*) raw_input, gridYSize, gridY + Muon::MuonTables::tableStationRegionOffset[tableNumber]);
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    raw_input += sizeof(int) * gridYSize;

    sizeOffset[Muon::MuonTables::tableStationRegionOffset[tableNumber]] = 0;
    for (size_t i = 0; i < Muon::Constants::n_stations * Muon::Constants::n_regions - 1; i++) {
      size_t index = Muon::MuonTables::tableStationRegionOffset[tableNumber] + i;
      sizeOffset[index + 1] = sizeOffset[index] + 24 * gridY[index];
    }

    size_t sizeXSize;
    std::copy_n((size_t*) raw_input, 1, &sizeXSize);
    raw_input += sizeof(size_t);
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    raw_input += sizeof(float) * sizeXSize;

    size_t sizeYSize;
    std::copy_n((size_t*) raw_input, 1, &sizeYSize);
    raw_input += sizeof(size_t);
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    raw_input += sizeof(float) * sizeYSize;

    size_t offsetSize;
    std::copy_n((size_t*) raw_input, 1, &offsetSize);
    raw_input += sizeof(size_t);
    allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
    raw_input += sizeof(unsigned int) * offsetSize;

    size_t tableSize;
    std::copy_n((size_t*) raw_input, 1, &tableSize);
    raw_input += sizeof(size_t);
    assert(tableSize == Muon::Constants::n_stations);
    for (size_t i = 0; i < tableSize; i++) {
      size_t stationTableSize;
      std::copy_n((size_t*) raw_input, 1, &stationTableSize);
      raw_input += sizeof(size_t);
      allOffsets[currentAllOffsetsIndex++] = raw_input - data.data();
      raw_input += sizeof(float) * Muon::MuonTables::n_dimensions * stationTableSize;
    }
  }
  assert(currentAllOffsetsIndex == n_data_blocks);

  auto& dev_muon_tables_raw = m_dev_muon_tables_raw.get();
  auto& host_muon_tables_raw = m_host_muon_tables_raw.get();
  if (!m_muon_tables) {
    cudaCheck(cudaMalloc((void**) &dev_muon_tables_raw, data.size()));
    cudaCheck(cudaMalloc((void**) &m_muon_tables.get(), sizeof(Muon::MuonTables)));
    m_size = sizeof(Muon::MuonTables);
  }
  else if (host_muon_tables_raw.size() != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(host_muon_tables_raw.size()) + " " +
                        to_string(data.size())};
  }
  host_muon_tables_raw = data;
  cudaCheck(
    cudaMemcpy(dev_muon_tables_raw, host_muon_tables_raw.data(), host_muon_tables_raw.size(), cudaMemcpyHostToDevice));
  Muon::MuonTables host_muon_tables {allOffsets, dev_muon_tables_raw, sizeOffset};
  cudaCheck(cudaMemcpy(m_muon_tables.get(), &host_muon_tables, sizeof(Muon::MuonTables), cudaMemcpyHostToDevice));
}
