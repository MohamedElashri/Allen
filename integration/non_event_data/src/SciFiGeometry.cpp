/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>
#include <vector>
#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "SciFiDefinitions.cuh"

namespace {
  using std::string;
  using std::to_string;
  using std::vector;
} // namespace

Consumers::SciFiGeometry::SciFiGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::SciFiGeometry::initialize(std::vector<char> const& data)
{
  auto& dev_scifi_geometry = m_constants.get().dev_scifi_geometry;
  Allen::malloc((void**) &dev_scifi_geometry, data.size());
}

void Consumers::SciFiGeometry::consume(std::vector<char> const& data)
{
  auto updated_data = data;
  size_t old_size = data.size();
  updated_data.resize(
    data.size() + 2 * SciFi::Constants::n_layers * sizeof(float)); // add 12 slots for z and 12 for dxdy
  SciFi::SciFiGeometry g {updated_data};
  uint32_t version = g.version;
  if (version == 0 || version == 1) {
    // hardcoded geometry version
    // v0 is decoding 4,5,6
    // v1 is decoding 7,8
    // hardcoded values taken from /device/event_model/SciFi/include/LookingForwardConstants.cuh (old Upgrade minbias
    // 2018 MC sample)
    std::vector<float> z_values = {
      7826.f, 7896.f, 7966.f, 8036.f, 8508.f, 8578.f, 8648.f, 8718.f, 9193.f, 9263.f, 9333.f, 9403.f};
    std::vector<float> dxdy_values = {
      0.f, 0.0874892f, -0.0874892f, 0.f, 0.f, 0.0874892f, -0.0874892f, 0.f, 0.f, 0.0874892f, -0.0874892f, 0.f};
    std::copy(z_values.begin(), z_values.end(), g.average_z);
    std::copy(dxdy_values.begin(), dxdy_values.end(), g.average_dxdy);
  }
  else {
    // extra space was not needed
    updated_data.resize(old_size);
  }

  auto& dev_scifi_geometry = m_constants.get().dev_scifi_geometry;
  if (dev_scifi_geometry == nullptr) {
    initialize(updated_data);
  }

  auto& host_scifi_geometry = m_constants.get().host_scifi_geometry;
  host_scifi_geometry = updated_data;
  Allen::memcpy(dev_scifi_geometry, host_scifi_geometry.data(), host_scifi_geometry.size(), Allen::memcpyHostToDevice);
}
