#include <string>

#include <CudaCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "MuonDefinitions.cuh"
#include "MuonGeometry.cuh"
#include "MuonTables.cuh"

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MuonGeometry::MuonGeometry(
  std::vector<char>& host_geometry_raw,
  char*& dev_geometry_raw,
  Muon::MuonGeometry*& dev_muon_geometry) :
  m_host_geometry_raw {host_geometry_raw},
  m_dev_geometry_raw {dev_geometry_raw}, m_muon_geometry {dev_muon_geometry}
{}

void Consumers::MuonGeometry::consume(std::vector<char> const& data)
{
  const char* raw_input = data.data();
  for (size_t i = 0; i < n_preamble_blocks; i++) {
    size_t size;
    std::copy_n((size_t*) raw_input, 1, &size);
    raw_input += sizeof(size_t);
    raw_input += sizeof(float) * size;
  }
  size_t nTilesSize;
  std::copy_n((size_t*) raw_input, 1, &nTilesSize);
  assert(nTilesSize == Muon::MuonGeometry::m_tiles_size);
  size_t sizes[Muon::MuonGeometry::m_tiles_size];
  unsigned int* tiles[Muon::MuonGeometry::m_tiles_size];
  size_t tilesOffset[Muon::MuonGeometry::m_tiles_size];
  raw_input += sizeof(size_t);
  for (size_t i = 0; i < nTilesSize; i++) {
    size_t tilesSize;
    std::copy_n((size_t*) raw_input, 1, &tilesSize);
    raw_input += sizeof(size_t);
    tilesOffset[i] = ((unsigned*) raw_input) - ((unsigned*) data.data());
    raw_input += sizeof(unsigned) * tilesSize;
    sizes[i] = tilesSize;
  }

  auto& dev_geometry_raw = m_dev_geometry_raw.get();
  auto& host_geometry_raw = m_host_geometry_raw.get();
  if (!m_muon_geometry) {
    cudaCheck(cudaMalloc((void**) &dev_geometry_raw, data.size()));
    cudaCheck(cudaMalloc((void**) &m_muon_geometry.get(), sizeof(Muon::MuonGeometry)));
    m_size = sizeof(Muon::MuonGeometry);
  }
  else if (host_geometry_raw.size() != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(host_geometry_raw.size()) + " " +
                        to_string(data.size())};
  }
  host_geometry_raw = std::move(data);
  cudaCheck(cudaMemcpy(dev_geometry_raw, host_geometry_raw.data(), host_geometry_raw.size(), cudaMemcpyHostToDevice));
  for (size_t i = 0; i < nTilesSize; i++) {
    tiles[i] = ((unsigned*) dev_geometry_raw) + tilesOffset[i];
  }
  Muon::MuonGeometry host_muon_geometry {sizes, tiles};
  cudaCheck(cudaMemcpy(m_muon_geometry.get(), &host_muon_geometry, sizeof(Muon::MuonGeometry), cudaMemcpyHostToDevice));
}
