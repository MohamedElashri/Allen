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

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "UTDefinitions.cuh"
#include "UTUniqueID.cuh"

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::UTBoards::UTBoards(Constants& constants) : m_constants {constants} {}

void Consumers::UTBoards::initialize(std::vector<char> const& data)
{
  const ::UTBoards boards {data};

  // UT board -> geometry
  auto& host_ut_board_geometry_map = m_constants.get().host_ut_board_geometry_map;
  auto& dev_ut_board_geometry_map = m_constants.get().dev_ut_board_geometry_map;

  // UT board -> sector group
  auto& host_ut_board_to_sector_group_map = m_constants.get().host_ut_board_to_sector_group_map;
  auto& dev_ut_board_to_sector_group_map = m_constants.get().dev_ut_board_to_sector_group_map;

  // Fill maps
  for (uint32_t fullChanIndex = 0; fullChanIndex < boards.number_of_channels; fullChanIndex++) {
    const uint32_t side = boards.sides[fullChanIndex];
    const uint32_t layer = boards.layers[fullChanIndex];
    const uint32_t stave = boards.staves[fullChanIndex];
    const uint32_t face = boards.faces[fullChanIndex];
    const uint32_t module = boards.modules[fullChanIndex];
    const uint32_t sector = boards.sectors[fullChanIndex];
    int sec = sector_unique_id(side, layer, stave, face, module, sector);
    host_ut_board_geometry_map.emplace_back(sec);
    unsigned sg = get_sector_group_id(stave, face, module) + layer * UT::Constants::n_groups_in_layer;
    host_ut_board_to_sector_group_map.emplace_back(sg);
  }

  // Allocate and copy
  auto alloc_and_copy = [](auto const& host_data, auto& device_data) {
    using value_type = typename std::remove_reference_t<decltype(host_data)>::value_type;
    using span_type = typename std::remove_reference_t<decltype(device_data)>::value_type;
    value_type* p = nullptr;
    Allen::malloc((void**) &p, host_data.size() * sizeof(value_type));
    device_data = gsl::span {p, static_cast<span_size_t<span_type>>(host_data.size())};
    Allen::memcpy(
      device_data.data(), host_data.data(), host_data.size() * sizeof(value_type), Allen::memcpyHostToDevice);
  };
  alloc_and_copy(host_ut_board_geometry_map, dev_ut_board_geometry_map);
  alloc_and_copy(host_ut_board_to_sector_group_map, dev_ut_board_to_sector_group_map);
}

void Consumers::UTBoards::consume(std::vector<char> const& data)
{
  auto& host_ut_boards = m_constants.get().host_ut_boards;
  auto& dev_ut_boards = m_constants.get().dev_ut_boards;
  if (host_ut_boards.empty()) {
    initialize(data);
    char* p = nullptr;
    Allen::malloc((void**) &p, data.size());
    dev_ut_boards = {p, data.size()};
  }
  else if (host_ut_boards.size() != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(host_ut_boards.size()) + " " +
                        to_string(data.size())};
  }
  host_ut_boards = data;
  Allen::memcpy(dev_ut_boards.data(), host_ut_boards.data(), host_ut_boards.size(), Allen::memcpyHostToDevice);
}
