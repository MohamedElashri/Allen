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

  auto& host_ut_board_geometry_map = m_constants.get().host_ut_board_geometry_map;
  auto& dev_ut_board_geometry_map = m_constants.get().dev_ut_board_geometry_map;

  for (uint32_t fullChanIndex = 0; fullChanIndex < boards.number_of_channels; fullChanIndex++) {
    const uint32_t side = boards.sides[fullChanIndex];
    const uint32_t layer = boards.layers[fullChanIndex];
    const uint32_t stave = boards.staves[fullChanIndex];
    const uint32_t face = boards.faces[fullChanIndex];
    const uint32_t module = boards.modules[fullChanIndex];
    const uint32_t sector = boards.sectors[fullChanIndex];
    int sec = sector_unique_id(side, layer, stave, face, module, sector);
    host_ut_board_geometry_map.emplace_back(sec);
  }

  uint16_t* p = nullptr;
  Allen::malloc((void**) &p, host_ut_board_geometry_map.size() * sizeof(uint16_t));
  dev_ut_board_geometry_map = gsl::span {p, static_cast<span_size_t<uint16_t>>(host_ut_board_geometry_map.size())};
  Allen::memcpy(
    dev_ut_board_geometry_map.data(),
    host_ut_board_geometry_map.data(),
    host_ut_board_geometry_map.size() * sizeof(uint16_t),
    Allen::memcpyHostToDevice);
}

void Consumers::UTBoards::consume(std::vector<char> const& data)
{
  auto& host_ut_boards = m_constants.get().host_ut_boards;
  auto& dev_ut_boards = m_constants.get().dev_ut_boards;
  if (host_ut_boards.empty()) {
    initialize(data);
    Allen::malloc((void**) &dev_ut_boards, data.size());
  }
  else if (host_ut_boards.size() != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(host_ut_boards.size()) + " " +
                        to_string(data.size())};
  }
  host_ut_boards = data;
  Allen::memcpy(dev_ut_boards, host_ut_boards.data(), host_ut_boards.size(), Allen::memcpyHostToDevice);
}
