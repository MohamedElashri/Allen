/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <string>
#include <vector>
#include <set>
#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"

namespace {
  using std::string;
  using std::to_string;

  struct AverageCounter {
    float mean = 0.0;
    unsigned count = 0;

    float value() const { return count == 0 ? 0.f : mean; }

    void add(float value)
    {
      ++count;
      mean += (value - mean) / count;
    }

    AverageCounter& operator+=(float value)
    {
      ++count;
      mean += (value - mean) / count;
      return *this;
    }
  };

  // UT sector numbering
  const unsigned sector_layer_offsets[] = {0, 248, 248 + 248, 248 + 248 + 276, 248 + 248 + 276 + 276};

  // Hardcoded dxdy
  const float hardcoded_layer_dxdy[] = {0, 0.08748866, -0.08748866, 0};

  unsigned map_sector_to_group(unsigned layer, unsigned sector)
  {
    static const unsigned r0_map[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
    static const unsigned r1_map[] = {0, 1, 2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 10, 11, 12, 13};
    static const unsigned r2_map[] = {0, 1, 2, 3, 4, 5, 5, 14, 14, 15, 15, 16, 16, 17, 17, 8, 8, 9, 10, 11, 12, 13};

    const auto group_offset = layer * UT::Constants::n_groups_in_layer;
    const auto station = layer / 2;
    const auto num_large_columns = 6 + station;

    const unsigned offsets[] = {0,
                                14 * num_large_columns,
                                14 * num_large_columns + 18,
                                14 * num_large_columns + 18 + 22 * 2,
                                14 * num_large_columns + 18 * 2 + 22 * 2,
                                14 * num_large_columns * 2 + 18 * 2 + 22 * 2};
    std::array<const unsigned*, 5> maps = {r0_map, r1_map, r2_map, r1_map, r0_map};
    const unsigned maps_size[5] = {14, 18, 22, 18, 14};
    for (unsigned region = 0; region < 5; region++) {
      if (sector >= offsets[region] && sector < offsets[region + 1]) {
        const auto map = maps[region];
        const auto size = maps_size[region];
        const auto idx = (sector - offsets[region]) % size;
        return group_offset + map[idx];
      }
    }
    return 0;
  }

  template<typename T>
  void alloc_and_copy(std::vector<T>& host_data, gsl::span<T>& device_data)
  {
    T* p;
    Allen::malloc((void**) &p, host_data.size() * sizeof(T));
    device_data = gsl::span {p, host_data.size()};
    Allen::memcpy(device_data.data(), host_data.data(), host_data.size() * sizeof(T), Allen::memcpyHostToDevice);
  }

  template<typename T>
  void alloc_and_copy(T*& host_data, T*& device_data)
  {
    Allen::malloc((void**) &device_data, sizeof(T));
    Allen::memcpy(device_data, host_data, sizeof(T), Allen::memcpyHostToDevice);
  }
} // namespace

Consumers::UTGeometry::UTGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::UTGeometry::initialize(std::vector<char> const& data)
{
  // Allocate space for geometry
  auto& dev_ut_geometry = m_constants.get().dev_ut_geometry;
  using span_type = typename std::remove_reference_t<decltype(dev_ut_geometry)>::value_type;
  char* g = nullptr;
  Allen::malloc((void**) &g, data.size());
  dev_ut_geometry = gsl::span {g, static_cast<span_size_t<span_type>>(data.size())};
  const ::UTGeometry geometry {data};

  // Fill sector to group map
  auto& host_ut_sector_to_group_map = m_constants.get().host_ut_sector_to_group_map;
  host_ut_sector_to_group_map.resize(UT::Constants::n_sectors);
  auto& dev_ut_sector_to_group_map = m_constants.get().dev_ut_sector_to_group_map;
  for (unsigned layer = 0; layer < UT::Constants::n_layers; layer++) {
    const auto sector_offset = sector_layer_offsets[layer];
    const auto sector_size = sector_layer_offsets[layer + 1] - sector_offset;
    for (unsigned sector = 0; sector < sector_size; sector++) {
      host_ut_sector_to_group_map[sector_offset + sector] = map_sector_to_group(layer, sector);
    }
  }

  // Fill layer geometry
  auto& host_ut_layer_geometry = m_constants.get().host_ut_layer_geometry;
  auto& dev_ut_layer_geometry = m_constants.get().dev_ut_layer_geometry;
  host_ut_layer_geometry = new UT::Constants::UTLayerGeometry;

  for (unsigned layer = 0; layer < 4; layer++) {
    const auto inf = std::numeric_limits<float>::infinity();
    float min_z = inf, max_z = -inf, min_dxdy = inf, max_dxdy = -inf;
    AverageCounter mean_z, mean_dxdy, inner_ymin, inner_ymax, outer_ymin, outer_ymax, mean_dy[2];

    // Sector range
    const auto sector_offset = sector_layer_offsets[layer];
    const auto sector_size = sector_layer_offsets[layer + 1] - sector_offset;

    for (unsigned sector = 0; sector < sector_size; sector++) {
      const auto group = map_sector_to_group(layer, sector) % UT::Constants::n_groups_in_layer;

      // Get values
      float sector_dxdy = (geometry.dxDy) ? geometry.dxDy[sector_offset + sector] : hardcoded_layer_dxdy[layer];
      float sector_z = fabsf(geometry.p0Z[sector_offset + sector]);
      float sector_y0 = geometry.p0Y[sector_offset + sector];
      float sector_dy = geometry.dy[sector_offset + sector];

      // Fill Min and Max
      min_z = std::min(min_z, sector_z);
      max_z = std::max(max_z, sector_z);
      min_dxdy = std::min(min_dxdy, sector_dxdy);
      max_dxdy = std::max(max_dxdy, sector_dxdy);

      // Fill mean
      mean_z += sector_z;
      mean_dxdy += sector_dxdy;
      if (group == 0) {
        outer_ymin += sector_y0;
      }
      if (group == 13) {
        outer_ymax += sector_y0;
      }
      if (group == 14) {
        inner_ymin += sector_y0;
      }
      if (group == 17) {
        inner_ymax += sector_y0;
      }
      mean_dy[(group < 14)] += sector_dy;
    }

    // Compute step
    float outer_dy = (outer_ymax.value() - outer_ymin.value()) / (UT::Constants::n_groups_outer_in_layer - 1);
    float inner_dy = (inner_ymax.value() - inner_ymin.value()) / (UT::Constants::n_groups_inner_in_layer - 1);

    // Fill layer info
    host_ut_layer_geometry->mean_z[layer] = mean_z.value();
    host_ut_layer_geometry->mean_dxdy[layer] = mean_dxdy.value();
    host_ut_layer_geometry->error_z[layer] = max_z - min_z;
    host_ut_layer_geometry->error_dxdy[layer] = max_dxdy - min_dxdy;
    host_ut_layer_geometry->two_dy[layer][0] = mean_dy[0].value();
    host_ut_layer_geometry->two_dy[layer][1] = mean_dy[1].value();
    host_ut_layer_geometry->outer_1_over_dy[layer] = 1.f / outer_dy;
    host_ut_layer_geometry->outer_y0_over_dy[layer] = outer_ymin.value() / outer_dy;
    host_ut_layer_geometry->inner_1_over_dy[layer] = 1.f / inner_dy;
    host_ut_layer_geometry->inner_y0_over_dy[layer] = inner_ymin.value() / inner_dy;
  }

  alloc_and_copy(host_ut_sector_to_group_map, dev_ut_sector_to_group_map);
  alloc_and_copy(host_ut_layer_geometry, dev_ut_layer_geometry);
}

void Consumers::UTGeometry::consume(std::vector<char> const& data)
{
  auto& dev_ut_geometry = m_constants.get().dev_ut_geometry;
  if (dev_ut_geometry.empty()) {
    initialize(data);
  }
  else if (static_cast<size_t>(dev_ut_geometry.size()) != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(dev_ut_geometry.size()) + " " +
                        to_string(data.size())};
  }

  auto& host_ut_geometry = m_constants.get().host_ut_geometry;
  host_ut_geometry = data;
  Allen::memcpy(dev_ut_geometry.data(), host_ut_geometry.data(), host_ut_geometry.size(), Allen::memcpyHostToDevice);
}
