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

Consumers::Beamline::Beamline(Constants& constants) : m_constants {constants} {}

void Consumers::Beamline::consume(std::vector<char> const& data)
{
  // Version "0" of the beamline has floats in it: the x and y
  // position. A version number was absent, so we use the fact
  // that we got 8 bytes. This is ugly but at this point it's better
  // to stay backwards compatible.

  // Version 1 has a version number (unsigned int) followed by 3
  // floats for (x, y, z) position and 6 floats representing a
  // triangular covariance matrix. We don't copy the version number to
  // stay backwards compatible.

  // Version 2 has a version number (unsigned int) followed by 3
  // floats for (x, y, z) position, 6 floats representing a
  // triangular covariance matrix and 2 floats representing effective crossing angles. We don't copy the version number
  // to stay backwards compatible. We are not copy angles to host_beamline to be backward compatible
  assert(data.size() >= 8u);
  auto const version = data.size() == 8u ? 0u : reinterpret_cast<unsigned const*>(data.data())[0];
  auto const data_size = version == 0u ? data.size() : data.size() - sizeof(unsigned);
  char const* data_start = version == 0u ? data.data() : data.data() + sizeof(unsigned);

  auto& host_beamline = m_constants.get().host_beamline;
  auto host_beamline_ptr = reinterpret_cast<float const*>(data_start);

  vector<float> host_beamline_local(
    host_beamline_ptr, host_beamline_ptr + static_cast<span_size_t<char>>(data_size / sizeof(float)));
  host_beamline = host_beamline_local;
}
