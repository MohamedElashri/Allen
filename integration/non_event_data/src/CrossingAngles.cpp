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

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
  using std::vector;
} // namespace

Consumers::CrossingAngles::CrossingAngles(Constants& constants) : m_constants {constants} {}

void Consumers::CrossingAngles::consume(std::vector<char> const& data)
{
  auto& host_gen_crossing_angles = m_constants.get().host_gen_crossing_angles;
  auto const data_size = data.size();
  char const* data_start = data.data();
  auto host_crossing_angles_ptr = reinterpret_cast<float const*>(data_start);
  vector<float> host_crossing_angles_local(
    host_crossing_angles_ptr, host_crossing_angles_ptr + static_cast<span_size_t<char>>(data_size / sizeof(float)));
  host_gen_crossing_angles = host_crossing_angles_local;
}
