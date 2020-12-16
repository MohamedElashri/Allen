/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "ClusteringCommon.h"
#include "VeloDefinitions.cuh"
#include "ClusteringDefinitions.cuh"

namespace {
  using std::string;
  using std::to_string;
  using std::vector;
} // namespace

Consumers::VPGeometry::VPGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::VPGeometry::initialize(vector<char> const&)
{

  auto alloc_and_copy = [](auto const& host_numbers, auto& device_numbers) {
    using value_type = typename std::remove_reference_t<decltype(host_numbers)>::value_type;
    using span_type = typename std::remove_reference_t<decltype(device_numbers)>::value_type;
    value_type* p = nullptr;
    Allen::malloc((void**) &p, host_numbers.size() * sizeof(value_type));
    device_numbers = gsl::span {p, static_cast<span_size_t<span_type>>(host_numbers.size())};
    Allen::memcpy(
      device_numbers.data(), host_numbers.data(), host_numbers.size() * sizeof(value_type), Allen::memcpyHostToDevice);
  };

  // Velo clustering candidate ks
  std::array<uint8_t, VeloClustering::lookup_table_size> host_candidate_ks = {0, 0, 1, 4, 4, 5, 5, 5, 5};
  alloc_and_copy(host_candidate_ks, m_constants.get().dev_velo_candidate_ks);

  // Velo clustering patterns
  // Fetch patterns and populate in GPU
  vector<uint8_t> sp_patterns(256, 0);
  vector<uint8_t> sp_sizes(256, 0);
  vector<float> sp_fx(512, 0);
  vector<float> sp_fy(512, 0);
  cache_sp_patterns(sp_patterns, sp_sizes, sp_fx, sp_fy);

  alloc_and_copy(sp_patterns, m_constants.get().dev_velo_sp_patterns);
  alloc_and_copy(sp_fx, m_constants.get().dev_velo_sp_fx);
  alloc_and_copy(sp_fy, m_constants.get().dev_velo_sp_fy);

  Allen::malloc((void**) &m_constants.get().dev_velo_geometry, sizeof(VeloGeometry));
}

void Consumers::VPGeometry::consume(vector<char> const& data)
{
  auto& dev_velo_geometry = m_constants.get().dev_velo_geometry;
  if (dev_velo_geometry == nullptr) {
    initialize(data);
  }
  // FIXME need to check the size of data is as expected

  VeloGeometry host_velo_geometry {data};
  Allen::memcpy(dev_velo_geometry, &host_velo_geometry, sizeof(VeloGeometry), Allen::memcpyHostToDevice);
}
